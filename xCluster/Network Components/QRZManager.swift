//
//  QRZManager.swift
//  xCluster
//
//  Created by Peter Bourget on 7/8/20.
//  Copyright © 2020 Peter Bourget. All rights reserved.
//

import Cocoa
import Network
import CoreLocation
import os
import CallParser

@available(OSX 10.15, *)
protocol QRZManagerDelegate: class {
    
    func qrzManagerdidGetSessionKey(_ qrzManager: QRZManager, messageKey: QRZManagerMessage, haveSessionKey: Bool)
    
    func qrzManagerdidGetCallsignData(_ qrzManager: QRZManager, messageKey: QRZManagerMessage, qrzInfoCombined: QRZInfoCombined)
}

// TODO: check session key expiration and renew

@available(OSX 10.15, *)
class QRZManager: NSObject {
    
    private let serialQRZProcessorQueue =
        DispatchQueue(
            label: "com.w6op.virtualcluster.qrzProcessorQueue")
    
    // MARK: - Field Definitions ----------------------------------------------------------------------------
    
    static let model_log = OSLog(subsystem: "com.w6op.TelnetManager", category: "Model")
    // delegate to pass messages back to viewcontroller
    weak var qrzManagerDelegate:QRZManagerDelegate?
    var callParser = CallLookup()
    
    var sessionKey: String!
    var haveSessionKey: Bool = false
    
    // a few variables to hold the results as we parse the XML
    var recordKey = "Session"
    var dictionaryKeys = Set<String>(["Key", "Count", "SubExp", "GMTime", "Remark"])
    var results: [[String: String]]?         // the whole array of dictionaries
    var results2: QRZInfo!
    var sessionDictionary: [String: String]! // the current dictionary
    var currentValue: String?
    var locationDictionary: (spotter: [String: String], dx: [String: String])!
    
    var qrzCallSignCache = [String: QRZInfo]()
    var qrzCallSignPair = [QRZInfo]()
    var qrzInfo: QRZInfo!
    
    // MARK: - Overrides ----------------------------------------------------------------------------
    
    override init() {
        
        super.init()
        
    }
    
    // MARK: - Network Implementation ----------------------------------------------------------------------------
    
    /**
     Get a Session Key from QRZ.com.
     - parameters:
     - name: logon name with xml plan.
     - password: password for account.
     */
    func parseQRZSessionKeyRequest(name: String, password: String) {
        
        recordKey = "Session"
        dictionaryKeys = Set<String>(["Key", "Count", "SubExp", "GMTime", "Remark"])
        
        let urlString = URL(string: "https://xmldata.qrz.com/xml/current/?username=\(name);password=\(password);VirtualCluster=1.0")
        
        let parser = XMLParser(contentsOf: urlString!)!
        
        parser.delegate = self
        if parser.parse() {
            print(self.results ?? "No results")
            self.sessionKey = self.sessionDictionary?["Key"]?.trimmingCharacters(in: .whitespaces)
            self.haveSessionKey = true
                self.qrzManagerDelegate?.qrzManagerdidGetSessionKey(self, messageKey: .SESSION, haveSessionKey: true)
        }
    }
    
    /**
     Request all the call information from QRZ.com to make a line on the map.
     - parameters:
     - spotterCall: first of a pair call signs to look up.
     - dxCall: second of a pair call signs to look up.
     */
    func getConsolidatedQRZInformation(spotterCall: String, dxCall: String, frequency: String) {
        
        serialQRZProcessorQueue.sync(flags: .barrier) { [weak self] in
            self?.parseQRZData(callSign: spotterCall, frequency: frequency)
            self?.parseQRZData(callSign: dxCall, frequency: frequency)
        }
    }
    
    /**
     Request all the call information from QRZ.com.
     - parameters:
     - call: call sign to look up.
     */
    func parseQRZData(callSign: String, frequency: String) {
        
        recordKey = "Callsign"
        sessionDictionary = [String: String]()
        dictionaryKeys = Set<String>(["call", "country", "lat", "lon", "grid", "lotw", "aliases"])
        
        guard let urlString = URL(string: "https://xmldata.qrz.com/xml/current/?s=\(String(self.sessionKey));callsign=\(callSign)") else {
            print("Invalid call sign: \(callSign)") // 'PY2OT  05'
            return
        }
        
        // first check to see if I have the info cached already
        if let qrzInfo = qrzCallSignCache[callSign] {
            combineQRZInfo(qrzInfo: qrzInfo, frequency: frequency)
            //print ("cache hit for: \(callSign)")
            print("cache contains \(qrzCallSignCache.count) call signs.")
        } else {
            let parser = XMLParser(contentsOf: urlString)!
            
            parser.delegate = self
            if parser.parse() {
                if (self.results != nil && self.results?.count != 0) {
                    if qrzCallSignPair.count > 1 {
                        qrzCallSignPair.removeAll()
                    } else {
                        if qrzCallSignPair.count > 2 {
                            print("Excess CallSignPairCount: \(qrzCallSignPair.count)")
                        }
                    }
                    populateQRZInfo(frequency: frequency)
                } else {
                    // we did not get one or more hits
                    // will move this to CallParser and call it there
                   
                }
                
            }
        }
    }
    
    /**
     Populate the qrzInfo with lat. lon, etc. If there is a pair
     send them to the viewcontroller for a line to be drawn.
     - parameters: frequency represented as a string
     */
    func populateQRZInfo(frequency: String) {
        
        qrzInfo = QRZInfo()
        
        qrzInfo.call = sessionDictionary["call"] ?? ""
        
        //qrzInfo.call = ("\(qrzInfo.call)/W5") // for debug
         // IF THERE IS A PREFIX OR SUFFIX CALL CALL PARSER AND SKIP SOME OF THIS
        // ALSO IF WE DON'T GET ANTHING from QRZ
        if qrzInfo.call.contains("/") { // process it
          let hitList: [Hit] = callParser.lookupCall(call: qrzInfo.call)
            if hitList.count > 0 {
                qrzInfo = populateQRZInfo(hitList: hitList)
            }
        } else {
        
            qrzInfo.latitude = Double(sessionDictionary["lat"] ?? "0.0") ?? 00
            if qrzInfo.latitude == 00 {
                qrzInfo.error = true
                print("latitude error: \(qrzInfo.call)")
            }
            
            qrzInfo.longitude = Double(sessionDictionary["lon"] ?? "0.0") ?? 00
            if qrzInfo.longitude == 00 {
                qrzInfo.error = true
                print("longitude error: \(qrzInfo.call)")
            }
        
            // TODO: if there is a prefix or suffix I need to find correct country and lat/lon
            
            qrzInfo.country = sessionDictionary["country"] ?? ""
            qrzInfo.grid = sessionDictionary["grid"] ?? ""
            qrzInfo.lotw = Bool(sessionDictionary["lotw"] ?? "0") ?? false
            qrzInfo.aliases = sessionDictionary["aliases"] ?? ""
        }
        
        // add to call sign cache
        qrzCallSignCache[qrzInfo.call] = qrzInfo
        combineQRZInfo(qrzInfo: qrzInfo, frequency: frequency)
    }
    
    /**
     Creatw a QRZInfo object from the hitlist.
     - parameters:
     - hitList: the array of hits returned
     */
    func populateQRZInfo(hitList: [Hit]) -> QRZInfo {
        qrzInfo = QRZInfo()
        
        let hit = hitList[hitList.count - 1]
        
        qrzInfo.call = hit.call
        qrzInfo.country = hit.country
        
        if let latitude = Double(hit.latitude) {
            qrzInfo.latitude = latitude
        }
        
        if let longitude = Double(hit.longitude) {
            qrzInfo.latitude = longitude
        }
        
        print("hit: \(qrzInfo.call)")
        
        return qrzInfo
    }
    
    /**
     Combine the QRZ information and send it to the viewcontroller for a line to be drawn.
     - parameters:
     - qrzCallSignPairCopy: the pair of QRZInfo to be combined
     - frequency: frequency to add to structure
     */
    func combineQRZInfo(qrzInfo: QRZInfo, frequency: String) {
        
        qrzCallSignPair.append(qrzInfo)
        
        if qrzCallSignPair.count == 2 {
            let qrzCallSignPairCopy = qrzCallSignPair // use copy so we don't read while modifying
            var qrzInfoCombined = QRZInfoCombined()
            
            qrzInfoCombined.setFrequency(frequency: frequency)
            
            qrzInfoCombined.spotterCall = qrzCallSignPairCopy[0].call
            qrzInfoCombined.spotterCountry = qrzCallSignPairCopy[0].country
            qrzInfoCombined.spotterLatitude = qrzCallSignPairCopy[0].latitude
            qrzInfoCombined.spotterLongitude = qrzCallSignPairCopy[0].longitude
            qrzInfoCombined.spotterGrid = qrzCallSignPairCopy[0].grid
            qrzInfoCombined.spotterLotw = qrzCallSignPairCopy[0].lotw
            qrzInfoCombined.error = qrzCallSignPairCopy[0].error
            
            qrzInfoCombined.dxCall = qrzCallSignPairCopy[1].call
            qrzInfoCombined.dxCountry = qrzCallSignPairCopy[1].country
            qrzInfoCombined.dxLatitude = qrzCallSignPairCopy[1].latitude
            qrzInfoCombined.dxLongitude = qrzCallSignPairCopy[1].longitude
            qrzInfoCombined.dxGrid = qrzCallSignPairCopy[1].grid
            qrzInfoCombined.dxLotw = qrzCallSignPairCopy[1].lotw
            if !qrzInfoCombined.error {
                qrzInfoCombined.error = qrzCallSignPairCopy[1].error
            }
            
            self.qrzManagerDelegate?.qrzManagerdidGetCallsignData(self, messageKey: .INFORMATION, qrzInfoCombined: qrzInfoCombined)
        }
    }
    
    /**
     Combine the QRZ information and send it to the viewcontroller for a line to be drawn.
     - parameters:
     - qrzCallSignPairCopy: the pair of QRZInfo to be combined
     */
//    func combineQRZInfo(qrzCallSignPairCopy: [QRZInfo], frequency: String) {
//
//        var qrzInfoCombined = QRZInfoCombined()
//
//            qrzInfoCombined.setFrequency(frequency: frequency)
//
//            qrzInfoCombined.spotterCall = qrzCallSignPairCopy[0].call
//            qrzInfoCombined.spotterCountry = qrzCallSignPairCopy[0].country
//            qrzInfoCombined.spotterLatitude = qrzCallSignPairCopy[0].latitude
//            qrzInfoCombined.spotterLongitude = qrzCallSignPairCopy[0].longitude
//            qrzInfoCombined.spotterGrid = qrzCallSignPairCopy[0].grid
//            qrzInfoCombined.spotterLotw = qrzCallSignPairCopy[0].lotw
//            qrzInfoCombined.error = qrzCallSignPairCopy[0].error
//
//            qrzInfoCombined.dxCall = qrzCallSignPairCopy[1].call
//            qrzInfoCombined.dxCountry = qrzCallSignPairCopy[1].country
//            qrzInfoCombined.dxLatitude = qrzCallSignPairCopy[1].latitude
//            qrzInfoCombined.dxLongitude = qrzCallSignPairCopy[1].longitude
//            qrzInfoCombined.dxGrid = qrzCallSignPairCopy[1].grid
//            qrzInfoCombined.dxLotw = qrzCallSignPairCopy[1].lotw
//            if !qrzInfoCombined.error {
//                qrzInfoCombined.error = qrzCallSignPairCopy[1].error
//            }
//
//        self.qrzManagerDelegate?.qrzManagerdidGetCallsignData(self, messageKey: .INFORMATION, qrzInfoCombined: qrzInfoCombined)
//    }
    
        
} // end class

/*
 <QRZDatabase version="1.33" xmlns="http://xmldata.qrz.com">
 <Callsign>
 <call>F2JD</call>
 <xref>HR5/F2JD</xref>
 <aliases>HR5/F2JD</aliases>
 <dxcc>227</dxcc>
 <fname>Gerard</fname>
 <name>JACOT</name>
 <addr1>Boucle de l'Observatoite - Le Mont Revard</addr1>
 <addr2>73100 PUGNY- CHATENOD</addr2>
 <zip>73100</zip>
 <country>France</country>
 <lat>45.686667</lat>
 <lon>5.956667</lon>
 <grid>JN25xq</grid>
 <ccode>97</ccode>
 <land>France</land>
 <class>A</class>
 <codes>TP</codes>
 <qslmgr>ALL VIA F6AJA (NOW FROM 36 YEARS)</qslmgr>
 <email>f2jd@orange.fr</email>
 <u_views>120353</u_views>
 <bio>4146</bio>
 <biodate>2015-07-16 00:28:33</biodate>
 <image>https://s3.amazonaws.com/files.qrz.com/d/f2jd/f2jd_1039532297.jpg</image>
 <imageinfo>274:400:27678</imageinfo>
 <moddate>2018-08-24 06:38:45</moddate>
 <eqsl>0</eqsl>
 <mqsl>1</mqsl>
 <cqzone>14</cqzone>
 <ituzone>27</ituzone>
 <born>1947</born>
 <lotw>1</lotw>
 <user>F2JD</user>
 <geoloc>user</geoloc>
 </Callsign>
 <Session>
 <Key>8c0e9b8e4072e5782727928413417bc2</Key>
 <Count>9471417</Count>
 <SubExp>Sun Dec 29 00:00:00 2019</SubExp>
 <GMTime>Fri Mar  8 23:26:34 2019</GMTime>
 <Remark>cpu: 0.131s</Remark>
 </Session>
 </QRZDatabase>
 
 <QRZDatabase version="1.33" xmlns="http://xmldata.qrz.com">
 <Callsign>
 <call>F2JD</call>
 <aliases>HR5/F2JD</aliases>
 <dxcc>227</dxcc>
 <fname>Gerard</fname>
 <name>JACOT</name>
 <addr1>Boucle de l'Observatoite - Le Mont Revard</addr1>
 <addr2>73100 PUGNY- CHATENOD</addr2>
 <zip>73100</zip>
 <country>France</country>
 <lat>45.686667</lat>
 <lon>5.956667</lon>
 <grid>JN25xq</grid>
 <ccode>97</ccode>
 <land>France</land>
 <class>A</class>
 <codes>TP</codes>
 <qslmgr>ALL VIA F6AJA (NOW FROM 36 YEARS)</qslmgr>
 <email>f2jd@orange.fr</email>
 <u_views>120354</u_views>
 <bio>4146</bio>
 <biodate>2015-07-16 00:28:33</biodate>
 <image>https://s3.amazonaws.com/files.qrz.com/d/f2jd/f2jd_1039532297.jpg</image>
 <imageinfo>274:400:27678</imageinfo>
 <moddate>2018-08-24 06:38:45</moddate>
 <eqsl>0</eqsl>
 <mqsl>1</mqsl>
 <cqzone>14</cqzone>
 <ituzone>27</ituzone>
 <born>1947</born>
 <lotw>1</lotw>
 <user>F2JD</user>
 <geoloc>user</geoloc>
 </Callsign>
 <Session>
 <Key>8c0e9b8e4072e5782727928413417bc2</Key>
 <Count>9471418</Count>
 <SubExp>Sun Dec 29 00:00:00 2019</SubExp>
 <GMTime>Fri Mar  8 23:28:18 2019</GMTime>
 <Remark>cpu: 0.348s</Remark>
 </Session>
 </QRZDatabase>
 
 
 <QRZDatabase version="1.33" xmlns="http://xmldata.qrz.com">
 <Callsign>
 <call>WY8I</call>
 <dxcc>291</dxcc>
 <fname>WILLIAM J</fname>
 <name>ODAM, JR</name>
 <addr1>7840 INGLEWOOD BEACH, PO BOX 230337</addr1>
 <addr2>FAIR HAVEN</addr2>
 <state>MI</state>
 <zip>48023</zip>
 <country>United States</country>
 <lat>42.663863</lat>
 <lon>-82.622504</lon>
 <grid>EN82qp</grid>
 <county>Saint Clair</county>
 <ccode>271</ccode>
 <fips>26147</fips>
 <land>United States</land>
 <efdate>2016-07-19</efdate>
 <expdate>2026-10-13</expdate>
 <class>E</class>
 <codes>HVIE</codes>
 <qslmgr>BURO OR DIRECT</qslmgr>
 <email>wy8i@comcast.net</email>
 <u_views>24299</u_views>
 <bio>1076</bio>
 <biodate>2015-07-16 00:30:18</biodate>
 <image>https://s3.amazonaws.com/files.qrz.com/i/wy8i/Jim.jpg</image>
 <imageinfo>694:565:58980</imageinfo>
 <moddate>2019-01-15 13:13:27</moddate>
 <MSA>2160</MSA>
 <AreaCode>810</AreaCode>
 <TimeZone>Eastern</TimeZone>
 <GMTOffset>-5</GMTOffset>
 <DST>Y</DST>
 <eqsl>0</eqsl>
 <mqsl>1</mqsl>
 <cqzone>4</cqzone>
 <ituzone>8</ituzone>
 <lotw>0</lotw>
 <user>WY8I</user>
 <geoloc>user</geoloc>
 </Callsign>
 <Session>
 <Key>d078471d55aef6e17fb566ef6e381e03</Key>
 <Count>9465097</Count>
 <SubExp>Sun Dec 29 00:00:00 2019</SubExp>
 <GMTime>Thu Feb 28 19:12:42 2019</GMTime>
 <Remark>cpu: 0.027s</Remark>
 </Session>
 </QRZDatabase>
 
 
 <QRZDatabase version="1.33" xmlns="http://xmldata.qrz.com">
 <Session>
 <Key>d078471d55aef6e17fb566ef6e381e03</Key>
 <Count>9465097</Count>
 <SubExp>Sun Dec 29 00:00:00 2019</SubExp>
 <GMTime>Thu Feb 28 18:11:31 2019</GMTime>
 <Remark>cpu: 0.162s</Remark>
 </Session>
 </QRZDatabase>
 */

