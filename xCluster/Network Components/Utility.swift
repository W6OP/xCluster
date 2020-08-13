//
//  Utility.swift
//  xCluster
//
//  Created by Peter Bourget on 7/8/20.
//  Copyright © 2020 Peter Bourget. All rights reserved.
//

import Cocoa

extension String {
  func condenseWhitespace() -> String {
    let components = self.components(separatedBy: .whitespacesAndNewlines)
    return components.filter { !$0.isEmpty }.joined(separator: " ")
  }
}

// find all items in an array that match a given predicate
// https://learnappmaking.com/find-item-in-array-swift/#finding-all-items-in-an-array-with-allwhere
//extension Array where Element: Equatable {
//    func all(where predicate: (Element) -> Bool) -> [Element]  {
//        return self.compactMap { predicate($0) ? $0 : nil }
//    }
//}

// round a Float to a number of digits
// let x = Float(0.123456789).roundTo(places: 4)
// https://www.uraimo.com/swiftbites/rounding-doubles-to-specific-decimal-places/
extension Float {
  func roundTo(places:Int) -> Float {
    let divisor = pow(10.0, Float(places))
    return (self * divisor).rounded() / divisor
  }
}

// https://stackoverflow.com/questions/31083348/parsing-xml-from-url-in-swift/31084545#31084545
extension QRZManager: XMLParserDelegate {
  
  // initialize results structure
  func parserDidStartDocument(_ parser: XMLParser) {
    results = []
  }
  
  // start element
  //
  // - If we're starting a "Session" create the dictionary that will hold the results
  // - If we're starting one of our dictionary keys, initialize `currentValue` (otherwise leave `nil`)
  func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String]) {
    if elementName == recordKey {
      sessionDictionary = [:]
    } else if elementName == "Error" {
      //print(ele)
    } else if dictionaryKeys.contains(elementName) {
      currentValue = ""
    }
  }
  
  // found characters
  //
  // - If this is an element we care about, append those characters.
  // - If `currentValue` still `nil`, then do nothing.
  func parser(_ parser: XMLParser, foundCharacters string: String) {
    currentValue? += string
  }
  
  // end element
  //
  // - If we're at the end of the whole dictionary, then save that dictionary in our array
  // - If we're at the end of an element that belongs in the dictionary, then save that value in the dictionary
  func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
    if elementName == recordKey {
      results!.append(sessionDictionary!)
    } else if dictionaryKeys.contains(elementName) {
      sessionDictionary![elementName] = currentValue
      currentValue = nil
    }
  }
  
  func parserDidEndDocument(_ parser: XMLParser) {
    //print("document finished")
  }
  
  // Just in case, if there's an error, report it. (We don't want to fly blind here.)
  func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
    print(parseError)
    
    currentValue = nil
    sessionDictionary = nil
    results = nil
  }
}

enum CommandType : String {
  case announce = "Announcement"
  case callsign = "Callsign"
  case connect = "Connect"
  case error = "Error"
  case ignore = "A reset so unsolicited messages don't get processed incorrectly"
  case logon = "Logon"
  case showdxspots = "Show Spots"
  case yes = "Yes"
  case message = "Message to send"
  case keepalive = "Keep alive"
  case qth = "Your QTH"
}

/**
 Unify message nouns going to the view controller
 */
enum TelnetManagerMessage : String {
  case announcement = "Announcement"
  case clustertype = "Cluster Type"
  case connected = "Connected"
  case disconnected = "Disconnected"
  case error = "Error"
  case info = "Cluster information received"
  case invalid = "Invaid command"
  case logon = "Logon message received"
  case logonCompleted = "Logon complete"
  case showdxspots = "Show DX received"
  case spotreceived = "Spot received"
  case waiting = "Waiting"
  case call = "Your call"
  case qth = "Your QTH"
  case name = "Your name"
  case location = "Your grid"
}

enum QRZManagerMessage : String {
  case session = "Session key available"
  case information = "CCall sign information"
  
}

enum ClusterType : String {
  case arcluster = "AR-Cluster"
  case cccluster = "CC-Cluster"
  case dxspider = "DXSpider"
  case ve7cc = "VE7CC"
  case unknown = "Unknown"
}

enum SpotError: Error {
  case spotError(String)
}

/** utility functions to run a UI or background thread
 // USAGE:
 BG() {
 everything in here will execute in the background
 }
 https://www.electrollama.net/blog/2017/1/6/updating-ui-from-background-threads-simple-threading-in-swift-3-for-ios
 */
func BG(_ block: @escaping ()->Void) {
  DispatchQueue.global(qos: .background).async(execute: block)
}

/**  USAGE:
 UI() {
 everything in here will execute on the main thread
 }
 */
func UI(_ block: @escaping ()->Void) {
  DispatchQueue.main.async(execute: block)
}

// MARK: - QRZ Structs ----------------------------------------------------------------------------

/**
 Structure to return information from QRZ.com.
 - parameters:
 */
struct QRZInfo {
  var call = ""
  var aliases = ""
  var country = ""
  var latitude: Double = 00
  var longitude: Double = 00
  var grid = ""
  var lotw = false
  var error = false
}

struct QRZInfoCombined  { //: Hashable
  var spotterCall = ""
  var spotterCountry = ""
  var spotterLatitude: Double = 00
  var spotterLongitude: Double = 00
  var spotterGrid = ""
  var spotterLotw = false
  
  var dxCall = ""
  var dxCountry = ""
  var dxLatitude: Double = 00
  var dxLongitude: Double = 00
  var dxGrid = ""
  var dxLotw = false
  
  var error = false
  var identifier = "0"
  var expired = false
  
  var frequency = "0.0"
  var formattedFrequency: Float = 0.0
  var band = 0
  var mode = ""
  
  init() {
    self.identifier = UUID().uuidString
  }
  
  // need to convert 3.593.4 to 3.5934
  mutating func setFrequency(frequency: String) {
    self.frequency = frequency
    self.formattedFrequency = QRZInfoCombined.formatFrequency(frequency: frequency)
    self.band = QRZInfoCombined.setBand(frequency: self.formattedFrequency)
  }
  
  static func formatFrequency(frequency: String) -> Float {
    
    let components = frequency.trimmingCharacters(in: .whitespaces).components(separatedBy: ".")
    var suffix = ""
    
    // TRY THIS
    // frequency.trimmingCharacters(in: .whitespaces).components(separatedBy: ".")[1]
    let prefix = components[0]
    
    for index in 1..<components.count {
      suffix += components[index]
    }
    
    let result = Float(("\(prefix).\(suffix)"))?.roundTo(places: 4)
    
    return result ?? 0.0
  }
  
  static func setBand(frequency: Float) -> Int {
    
    switch frequency {
    case 1.8...2.0:
      return 160
    case 3.5...4.0:
      return 80
    case 5.0...6.0:
      return 60
    case 7.0...7.3:
      return 40
    case 10.1...10.5:
      return 30
    case 14.0...14.350:
      return 20
    case 18.068...18.168:
      return 17
    case 21.0...21.450:
      return 15
    case 24.890...24.990:
      return 12
    case 28.0...29.7:
      return 10
    case 70.0...75.0:
      return 4
    case 50.0...54.0:
      return 6
    case 144.0...148.0:
      return 2
    default:
      return 0
    }
  }
} // end

