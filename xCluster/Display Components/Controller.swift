//
//  Controller.swift
//  xCluster
//
//  Created by Peter Bourget on 7/6/20.
//  Copyright © 2020 Peter Bourget. All rights reserved.
//

// shim between UI and Network Controllers

import Foundation
import Combine

// MARK: - ClusterSpots

struct ClusterSpot: Identifiable, Hashable {
  var id: Int
  var dxStation: String
  var frequency: String
  var spotter: String
  var dateTime: String
  var comment: String
  var grid: String
}

public class  Controller: ObservableObject, TelnetManagerDelegate, QRZManagerDelegate {
  
  private let concurrentSpotProcessorQueue =
    DispatchQueue(
      label: "com.w6op.virtualcluster.spotProcessorQueue",
      attributes: .concurrent)
  
  @Published var spots = [ClusterSpot]()
  @Published var statusMessage = [String]()
  @Published var haveSessionKey = false
  
  var qrzManager = QRZManager()
  var telnetManager = TelnetManager()
  var spotProcessor = SpotProcessor()
  
  let callsign = UserDefaults.standard.string(forKey: "callsign") ?? ""
  let fullname = UserDefaults.standard.string(forKey: "fullname") ?? ""
  let location = UserDefaults.standard.string(forKey: "location") ?? ""
  let grid = UserDefaults.standard.string(forKey: "grid") ?? ""
  let qrzUsername = UserDefaults.standard.string(forKey: "username") ?? ""
  let qrzPassword = UserDefaults.standard.string(forKey: "password") ?? ""
  
  
  // MARK: - Protocol Delegate Implementation
  
  /**
   Connect to a cluster
   */
  func  connect(clusterName: String) {
    
    // clear the collection
    //spots = [ClusterSpot]()
    
    let cluster = clusterData.first(where: {$0.name == clusterName})
    
    if !cluster!.address.isEmpty {
      self.statusMessage = [String]()
      telnetManager.connect(host: cluster!.address, port: cluster!.port)
    }
    //          // show an entry in the tableview
    //          clusterSpotArray.insert(ClusterSpots(dx: "----------", frequency: "----------", spotter: "----------", comment: comment, datetime: "----",grid: "----"), at: 0)
  }
  
  /**
   Telnet Manager protocol - Process a status message from the Telnet Manager.
   - parameters:
   - telnetManager: Reference to the class sending the message.
   - messageKey: Key associated with this message.
   - message: message text.
   */
  func telnetManagerStatusMessageReceived(_ telnetManager: TelnetManager, messageKey: TelnetManagerMessage, message: String) {
    switch messageKey {
      case .LOGON:
        self.sendLogin()
      case .WAITING:
        UI {
          //self.statusMessage.append(message.appendingFormat("\n"))
          self.statusMessage.append(message.appendingFormat(message))
        }
        // self.statusMessages.string = self.statusMessages.string.appendingFormat("\n")
      // self.statusMessages.string = self.statusMessages.string.appendingFormat(message)
      case .ERROR:
        UI {
          //self.statusMessage.append(message.appendingFormat("\n"))
          self.statusMessage.append(message.appendingFormat(message))
        }
      case .CALL:
        self.sendClusterCommand(message: "\(callsign)", commandType: CommandType.LOGON)
      case .NAME:
        self.sendClusterCommand(message: "set/name \(fullname)", commandType: CommandType.CALLSIGN)
      case .QTH:
        self.sendClusterCommand(message: "set/qth \(location)", commandType: CommandType.QTH)
      case .LOCATION:
        self.sendClusterCommand(message: "set/qra \(grid)", commandType: CommandType.MESSAGE)// want lat/long
      case .INFO:
        UI {
          //self.statusMessage.append(message.appendingFormat("\n"))
          self.statusMessage.append(message.appendingFormat(message))
        }
      default:
        UI {
          //self.statusMessage.append(message.appendingFormat("\n"))
          self.statusMessage.append(message.appendingFormat(message))
          //print(self.statusMessage)
        }
      }
  }
  
  /**
   Telnet Manager protocol - Process information messages from the Telnet Manager.
   - parameters:
   - telnetManager: Reference to the class sending the message.
   - messageKey: Key associated with this message.
   - message: message text.
   */
  func telnetManagerDataReceived(_ telnetManager: TelnetManager, messageKey: TelnetManagerMessage, message: String) {
    switch messageKey {
    case .CLUSTERTYPE:
      UI {
        self.statusMessage.append(message.condenseWhitespace())
        //self.clusterTypeLabel.stringValue = message.condenseWhitespace()
      }
      break
    case .ANNOUNCEMENT:
      UI {
        self.statusMessage.append(message.condenseWhitespace())
        //self.annoucementsLabel.stringValue = message.condenseWhitespace()
      }
      break
    case .INFO:
      UI {
        //self.statusMessage.append(message.appendingFormat("\n"))
        self.statusMessage.append(message.appendingFormat(message))
      }
    case .ERROR:
      UI {
        //self.statusMessage.append(message.appendingFormat("\n"))
        self.statusMessage.append(message.appendingFormat(message))
      }
    case .SPOTRECEIVED:
      UI {
        self.parseClusterSpot(message: message, messageType: messageKey)
      }
    case .SHOWDXSPOTS:
      UI {
        self.parseClusterSpot(message: message, messageType: messageKey)
      }
    default:
      break
    }
  }
  
  /**
   QRZ Manager protocol - Retieve the session key from QRZ.com.
   - parameters:
   - qrzManager: Reference to the class sending the message.
   - messageKey: Key associated with this message.
   - message: message text.
   */
  func qrzManagerdidGetSessionKey(_ qrzManager: QRZManager, messageKey: QRZManagerMessage, haveSessionKey: Bool) {
    
    self.haveSessionKey = haveSessionKey
    print("Session key arrived")
  }
  
  /**
   QRZ Manager protocol - Receive the call sign data QRZ.com.
   - parameters:
   - qrzManager: Reference to the class sending the message.
   - messageKey: Key associated with this message.
   - message: message text.
   */
  func qrzManagerdidGetCallsignData(_ qrzManager: QRZManager, messageKey: QRZManagerMessage, qrzInfoCombined: QRZInfoCombined) {
    
    //      DispatchQueue.global(qos: .userInitiated).async { [weak self] in
    //          self!.buildMapLines(qrzInfoCombined: qrzInfoCombined)
    //      }
  }
  
  
  
  init () {
    
    telnetManager.telnetManagerDelegate = self
    qrzManager.qrzManagerDelegate = self
    
    getQRZSessionKey()
  }
  
  func getQRZSessionKey(){
    //concurrentSpotProcessorQueue.async() { [weak self] in
    self.qrzManager.parseQRZSessionKeyRequest(name: self.qrzUsername, password: self.qrzPassword)
    //}
  }
  
  /**
   Send the operators call sign to the telnet server.
   */
  func sendLogin() {
    telnetManager.send(qrzUsername, commandType: .LOGON)
  }
  
  /**
   Send a message or command to the telnet manager.
   - parameters:
   - message: The data sent.
   - commandType: The type of command sent.
   */
  func sendClusterCommand (message: String, commandType: CommandType) {
    telnetManager.send(message, commandType: commandType)
  }
  /**
   Send a message or command to the telnet manager.
   - parameters:
   - tag: The tag value from the button to identify what command needs to be sent.
   - commandType: The type of command sent.
   */
  func sendClusterCommand(tag: Int, command: String)  {
    
    switch tag {
    case 20:
      telnetManager.send("show/dx 20", commandType: .SHOWDXSPOTS)
    case 50:
      telnetManager.send("show/dx 50", commandType: .SHOWDXSPOTS)
    default:
      telnetManager.send(command, commandType: .IGNORE)
    }
  }
  
  func parseClusterSpot(message: String, messageType: TelnetManagerMessage){
    do {
        let spot = try self.spotProcessor.processRawSpot(rawSpot: message)
        self.spots.insert(spot, at: 0)
        
        if self.haveSessionKey {
            DispatchQueue.global(qos: .background).async { [weak self] in
                _ =  self!.qrzManager.getConsolidatedQRZInformation(spotterCall: spot.spotter, dxCall: spot.dxStation, frequency: spot.frequency)
            }
        }
      
      if spots.count > 100 {
        spots.remove(at: spots.count - 1)
      }
    }
    catch {
        print("Error: \(error)")
        return
    }
  }
} // end class

// MARK: - Get the QRZ Session Key
//UserDefaults.standard.object(forKey: "username")


// MARK: - User Defaults

// https://www.simpleswiftguide.com/how-to-use-userdefaults-in-swiftui/
class UserSettings: ObservableObject {
  
  @Published var callsign: String {
    didSet {
      UserDefaults.standard.set(callsign.uppercased(), forKey: "callsign")
    }
  }
  
  @Published var fullname: String {
    didSet {
      UserDefaults.standard.set(fullname, forKey: "fullname")
    }
  }
  
  @Published var username: String {
    didSet {
      UserDefaults.standard.set(username, forKey: "username")
    }
  }
  
  @Published var password: String {
    didSet {
      UserDefaults.standard.set(password, forKey: "password")
    }
  }
  
  @Published var location: String {
    didSet {
      UserDefaults.standard.set(location, forKey: "location")
    }
  }
  
  @Published var grid: String {
    didSet {
      UserDefaults.standard.set(grid, forKey: "grid")
    }
  }
  
  init() {
    self.callsign = UserDefaults.standard.string(forKey: "callsign") ?? ""
    self.username = UserDefaults.standard.string(forKey: "username") ?? ""
    self.password = UserDefaults.standard.string(forKey: "password") ?? ""
    self.fullname = UserDefaults.standard.string(forKey: "fullname") ?? ""
    self.location = UserDefaults.standard.string(forKey: "location") ?? ""
    self.grid = UserDefaults.standard.string(forKey: "grid") ?? ""
  }
}
