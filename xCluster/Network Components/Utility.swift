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

extension Queue: CustomStringConvertible {
    public var description: String {
        return list.description
    }
}

// find all items in an array that match a given predicate
// https://learnappmaking.com/find-item-in-array-swift/#finding-all-items-in-an-array-with-allwhere
extension Array where Element: Equatable {
    func all(where predicate: (Element) -> Bool) -> [Element]  {
        return self.compactMap { predicate($0) ? $0 : nil }
    }
}

// round a Float to a number of digits
// let x = Float(0.123456789).roundTo(places: 4)
// https://www.uraimo.com/swiftbites/rounding-doubles-to-specific-decimal-places/
extension Float {
    func roundTo(places:Int) -> Float {
        let divisor = pow(10.0, Float(places))
        return (self * divisor).rounded() / divisor
    }
}

// https://www.raywenderlich.com/848-swift-algorithm-club-swift-queue-data-structure
public struct Queue<T> {
    
    // 2
    fileprivate var list = LinkedList<T>()
    
    public var isEmpty: Bool {
        return list.isEmpty
    }
    
    // 3
    public mutating func enqueue(_ element: T) {
        list.append(value: element)
    }
    
    // 4
    public mutating func dequeue() -> T? {
        guard !list.isEmpty, let element = list.first else { return nil }
        
        _ = list.remove(node: element)
        
        return element.value
    }
    
    // 5
    public func peek() -> T? {
        return list.first?.value
    }
}

/*
 var queue = Queue<Int>()
 queue.enqueue(10)
 queue.enqueue(3)
 queue.enqueue(57)
 
 print(queue)
 
 var queue2 = Queue<String>()
 queue2.enqueue("mad")
 queue2.enqueue("lad")
 if let first = queue2.dequeue() {
 print(first)
 }
 print(queue2)
 */

public class Node<T> {
    var value: T
    var next: Node<T>?
    weak var previous: Node<T>?
    
    init(value: T) {
        self.value = value
    }
}
// https://www.raywenderlich.com/947-swift-algorithm-club-swift-linked-list-data-structure
public class LinkedList<T> {
    fileprivate var head: Node<T>?
    private var tail: Node<T>?
    
    public var isEmpty: Bool {
        return head == nil
    }
    
    public var first: Node<T>? {
        return head
    }
    
    public var last: Node<T>? {
        return tail
    }
    
    /// Computed property to iterate through the linked list and return the total number of nodes
    public var count: Int {
        guard var node = head else {
            return 0
        }
        
        var count = 1
        while let next = node.next {
            node = next
            count += 1
        }
        return count
    }
    
    public func append(value: T) {
        let newNode = Node(value: value)
        if let tailNode = tail {
            newNode.previous = tailNode
            tailNode.next = newNode
        } else {
            head = newNode
        }
        tail = newNode
    }
    
    public func nodeAt(index: Int) -> Node<T>? {
        if index >= 0 {
            var node = head
            var i = index
            while node != nil {
                if i == 0 { return node }
                i -= 1
                node = node!.next
            }
        }
        return nil
    }
    
    public func removeAll() {
        head = nil
        tail = nil
    }
    
    public func remove(node: Node<T>) -> T {
        let prev = node.previous
        let next = node.next
        
        if let prev = prev {
            prev.next = next
        } else {
            head = next
        }
        next?.previous = prev
        
        if next == nil {
            tail = prev
        }
        
        node.previous = nil
        node.next = nil
        
        return node.value
    }
}

extension LinkedList: CustomStringConvertible {
    public var description: String {
        var text = "["
        var node = head
        
        while node != nil {
            text += "\(node!.value)"
            node = node!.next
            if node != nil { text += ", " }
        }
        return text + "]"
    }
}

// https://stackoverflow.com/questions/31083348/parsing-xml-from-url-in-swift/31084545#31084545
@available(OSX 10.15, *)
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
            // why do you want to destroy your dictionary here?
            //sessionDictionary = nil
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
    case ANNOUNCE = "Announcement"
    case CALLSIGN = "Callsign"
    case CONNECT = "Connect"
    case ERROR = "Error"
    case IGNORE = "A reset so unsolicited messages don't get processed incorrectly"
    case LOGON = "Logon"
    case SHOWDXSPOTS = "Show Spots"
    case YES = "Yes"
    case MESSAGE = "Message to send"
    case KEEPALIVE = "Keep alive"
    case QTH = "Your QTH"
}

/**
 Unify message nouns going to the view controller
 */
 enum TelnetManagerMessage : String {
    case ANNOUNCEMENT = "Announcement"
    case CLUSTERTYPE = "Cluster Type"
    case CONNECTED = "Connected"
    case DISCONNECTED = "Disconnected"
    case ERROR = "Error"
    case INFO = "Cluster information received"
    case LOGON = "Logon message received"
    case SHOWDXSPOTS = "Show DX received"
    case SPOTRECEIVED = "Spot received"
    case WAITING = "Waiting"
    case CALL = "Your call"
    case QTH = "Your QTH"
    case NAME = "Your name"
    case LOCATION = "Your grid"
}

 enum QRZManagerMessage : String {
    case SESSION = "Session key available"
    case INFORMATION = "CCall sign information"
    
}


 enum ClusterType : String {
    case ARCLUSTER = "AR-Cluster"
    case CCCLUSTER = "CC-Cluster"
    case DXSPIDER = "DXSpider"
    case VE7CC = "VE7CC"
    case UNKNOWN = "Unknown"
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

/*
 
 */
class Utility: NSObject {
    
    override init() {
        super.init()
    }
    
    func loadStandardURLSet() -> Dictionary<Int, String> {
        
        var collection = [Int: String]()
        
        // subscript is key, not index
        collection[1] = "http://www.dxsummit.fi/DxSpots.aspx?count=25&range=1"
        collection[2] = "http://www.dxsummit.fi/DxSpots.aspx?count=250&range=1"
        collection[3] = "http://www.dxsummit.fi/DxSpots.aspx?count=500&range=1"
        collection[4] = "http://www.dxsummit.fi/DxSpots.aspx?count=1000&range=1"
        collection[5] = ""
        collection[6] = ""
        collection[7] = ""
        collection[8] = ""
        collection[9] = ""
        collection[10] = ""
        collection[11] = ""
        
        return collection
    }
    
} // end class

// http://www.rockhoppertech.com/blog/swift-nstableview-and-nsarraycontroller/
 class ClusterNames : NSObject {
    
    @objc dynamic var clusterName: String
    @objc dynamic var clusterAddress: String
    @objc dynamic var clusterPort: String
    
    override init() {
        clusterName = "Select DXSpider Node"
        clusterAddress = "family"
        clusterPort = "0"
        super.init()
    }
    
    init(clusterName:String, clusterAddress:String, clusterPort:String) {
        self.clusterName = clusterName
        self.clusterAddress = clusterAddress
        self.clusterPort = clusterPort
        super.init()
    }
}

 // MARK: - ClusterSpots ----------------------------------------------------------------------------

// spot for display in tableview
class ClusterSpots : NSObject {
    
    @objc dynamic var dx: String
    @objc dynamic var frequency: String
    @objc dynamic var spotter: String
    @objc dynamic var datetime: String
    @objc dynamic var comment: String
    @objc dynamic var grid: String
    
    override init() {
        dx = "W6OP"
        frequency = "10000"
        spotter = "W6OP"
        datetime = "1200"
        comment = "Comment"
        grid = "CM98ha"
        
        super.init()
    }
    
    init(dx:String, frequency:String, spotter:String, comment:String, datetime:String,  grid:String) {
        self.dx = dx
        self.frequency = frequency
        self.spotter = spotter
        self.datetime = datetime
        self.comment = comment
        self.grid = grid
        
        super.init()
    }
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
            //print("40M : \(frequency)")
            return 40
        case 10.1...10.5:
            //print("10M : \(frequency)")
            return 30
        case 14.0...14.350:
            //print("20M : \(frequency)")
            return 20
        case 18.068...18.168:
            //print("17M : \(frequency)")
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

// MARK: - Overlay Spot Structs ----------------------------------------------------------------------------

//struct OverlaySpot {
//    var dx = ""
//    var spotter = ""
//    var frequency = "0.0"
//    var rawFrequency: Float = 0.0
//    var comment = ""
//    // https://stackoverflow.com/questions/45533460/cannot-invoke-initializer-for-type-float-with-an-argument-of-type-any  USE THIS FOR DATE AND TIME
//    var datetime = ""
//    var grid = ""
//    var band = 0
//    var mode = ""
//    var country: String = ""
//    //var latitude: Double = 00
//    //var longitude: Double = 00
//    var lotw = false
//    var identifier = "0"
//    var isInvalid = false
//
//    init(dx:String, frequency:String, spotter:String, comment:String, datetime:String,  grid:String) {
//        self.dx = dx
//        self.frequency = frequency
//        self.spotter = spotter
//        self.datetime = datetime
//        self.comment = comment
//        self.grid = grid
//
//        self.identifier = UUID().uuidString
//
//        setFrequency(frequency: frequency)
//    }
//
//    mutating func setFrequency(frequency: String) {
//        self.rawFrequency = Float(frequency) ?? 0.0
//        self.band = OverlaySpot.setBand(frequency: self.rawFrequency)
//    }
//
//    static func setBand(frequency: Float) -> Int {
//
//        switch frequency {
//        case 1.8...2.0:
//            return 160
//        case 3.5...4.0:
//            return 80
//        case 5.0...6.0:
//            return 60
//        case 7.0...7.3:
//            return 40
//        case 10.1...10.5:
//            return 30
//        case 14.0...14.350:
//            return 20
//        case 18.068...18.168:
//            return 17
//        case 21.0...21.450:
//            return 15
//        case 24.890...24.990:
//            return 12
//        case 28.0...29.7:
//            return 10
//        case 70.0...74.0:
//            return 4
//        case 50.0...54.0:
//            return 6
//        case 144.0...148.0:
//            return 2
//        default:
//            return 0
//        }
//    }
//} // end OverlaySpot struct


//<QRZDatabase xmlns="http://xmldata.qrz.com" version="1.33">
//<Session>
//<Error>Invalid session key</Error>
//<GMTime>Sat Mar 2 21:44:10 2019</GMTime>
//<Remark>cpu: 0.011s</Remark>
//</Session>
//</QRZDatabase>

/*
 func getSessionKey(name: String, password: String) {
 
 parseQRZSessionKeyRequest(name: name, password: password)
 return
 
 recordKey = "Session"
 dictionaryKeys = Set<String>(["Key", "Count", "SubExp", "GMTime", "Remark"])
 
 let qrzEndpoint: String = "https://xmldata.qrz.com/xml/current/?username=\(name);password=\(password);VirtualCluster=1.0"
 guard let url = URL(string: qrzEndpoint) else {
 print("Error: cannot create URL")
 return
 }
 
 let urlRequest = URLRequest(url: url)
 
 // set up the session
 let config = URLSessionConfiguration.default
 let session = URLSession(configuration: config)
 
 // make the request
 let task = session.dataTask(with: urlRequest) {
 (data, response, error) in
 // check for any errors
 guard error == nil else {
 print("error calling GET on /todos/1")
 print(error!)
 return
 }
 // make sure we got data
 guard data != nil else {
 print("Error: did not receive data")
 return
 }
 
 let parser = XMLParser(data: data!)
 parser.delegate = self
 if parser.parse() {
 print(self.results ?? "No results")
 }
 
 self.sessionKey = self.sessionDictionary?["Key"]?.trimmingCharacters(in: .whitespaces)
 self.haveSessionKey = true

 self.qrzManagerDelegate?.qrzManagerdidGetSessionKey(self, messageKey: .SESSION, haveSessionKey: true)

 }
 
 task.resume()
 }
 */
/*
 // --------------------------------------------------------------------------
 //        print("\(spotterCall):\(dxCall)")
 //
 //        locationDictionary = ([String: String](),[String: String]())
 //        locationDictionary.spotter = [String: String]()
 //        locationDictionary.dx = [String: String]()
 //
 //        if spotterCall.isEmpty || dxCall.isEmpty {
 //            return locationDictionary
 //        }
 //
 //        let group = DispatchGroup()
 //
 //        group.enter()
 //        start() {
 //            print("1")
 //            self.parseQRZData(callSign: spotterCall)
 //            group.leave()
 //        }
 //
 //        group.enter()
 //        start() {
 //            print("2")
 //            self.parseQRZData(callSign: dxCall)
 //            group.leave()
 //        }
 //
 //
 //        group.notify(queue: .main) {
 //            print("done")
 //        }
 
 //    func start(completion: () -> Void) {
 //        //sleep(delay)
 //        print("Completed")
 //        completion()
 //    }
 
 //
 
 
 // --------------------------------------------------------------------------
 //        let group = DispatchGroup()
 //        let queue = DispatchQueue(label: "com.theswiftdev.queues.serial")
 //        let workItem = DispatchWorkItem {
 //            print("start")
 //
 ////            print("end")
 //
 //        }
 //
 //        queue.async(group: group) {
 //            print("group start")
 //            self.requestQRZDetails(callSign: spotterCall)
 //            sleep(1)
 //            self.requestQRZDetails(callSign: dxCall)
 //        }
 //        DispatchQueue.global().async(group: group, execute: workItem)
 //
 //        // you can block your current queue and wait until the group is ready
 //        // a better way is to use a notification block instead of blocking
 //        //group.wait(timeout: .now() + .seconds(3))
 //        //print("done")
 //
 //        group.notify(queue: .main) {
 //            print("done")
 //            print(self.locationDictionary)
 //        }
 // -----------------------------------------------------------
 
 
 //requestQRZDetails(callSign: spotterCall)
 //requestQRZDetails(callSign: dxCall)
 */

/*
 // http://xmldata.qrz.com/xml/current/?s=d078471d55aef6e17fb566ef6e381e03;callsign=WY8I
 /**
 Request all the call information from QRZ.com.
 - parameters:
 - call: call sign to look up.
 */
 func requestQRZDetails(callSign: String){
 
 recordKey = "Callsign"
 sessionDictionary = [String: String]()
 dictionaryKeys = Set<String>(["call", "country", "lat", "lon", "grid", "lotw"])
 
 let qrzEndpoint: String = "https://xmldata.qrz.com/xml/current/?s=\(String(self.sessionKey));callsign=\(callSign)"
 
 guard let url = URL(string: qrzEndpoint) else {
 print("Error: cannot create URL \(qrzEndpoint)")
 return
 }
 
 let urlRequest = URLRequest(url: url)
 
 // make the request
 let task = URLSession.shared.dataTask(with: urlRequest) {
 (data, response, error) in
 // check for any errors
 guard error == nil else {
 print("error calling GET on /todos/1")
 print(error!)
 return
 }
 // make sure we got data
 guard data != nil else {
 print("Error: did not receive data")
 return
 }
 
 print(String(data: data!, encoding: .utf8) as Any)
 self.parseQRZData(data: data!)
 
 }
 
 task.resume()
 }
 */

/*
 func parseQRZData(data: Data) {
 
 let parser = XMLParser(data: data)
 
 parser.delegate = self
 if parser.parse() {
 print(self.results ?? "No results")
 print("append")
 if (self.results != nil && self.results?.count != 0) {
 qrzData.append((self.results?[0] ?? [String: String]()))
 }

 self.qrzManagerDelegate?.qrzManagerdidGetCallsignData(self, messageKey: .INFORMATION, locationDictionary: self.locationDictionary ?? ([String: String](), [String: String]()))

 }
 }
 */
