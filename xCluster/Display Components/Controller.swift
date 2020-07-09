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

struct Spots: Identifiable, Hashable {
  var id: ObjectIdentifier
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
  
  @Published var spots = [Spots]()
  @Published var telnetMessage = ""
  
  var qrzManager = QRZManager()
  var telnetManager = TelnetManager()
  var spotProcessor = SpotProcessor()
  
  let fullname = UserDefaults.standard.string(forKey: "location") ?? ""
  let location = UserDefaults.standard.string(forKey: "grid") ?? ""
  let grid = UserDefaults.standard.string(forKey: "fullname") ?? ""
  let qrzUsername = UserDefaults.standard.string(forKey: "username") ?? ""
  let qrzPassword = UserDefaults.standard.string(forKey: "password") ?? ""
  
  
  // MARK: - Protocol Delegate Implementation
  
  
  /**
   Initial Connect
   */
  func  connect(clusterAddress: String, clusterPort: String) {
    
    //      if !clusterAddress.isEmpty {
    //          let comment = ("Connecting to \(clusterAddress)")
    //
    //          // show an entry in the tableview
    //          clusterSpotArray.insert(ClusterSpots(dx: "----------", frequency: "----------", spotter: "----------", comment: comment, datetime: "----",grid: "----"), at: 0)
    //
    //          telnetManager.connect(host: clusterAddress, port: String(clusterPort))
    //      }
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
      self.telnetMessage = message.appendingFormat("\n")
      //                   self.statusMessages.string = self.statusMessages.string.appendingFormat("\n")
    //                   telnetMessage = self.statusMessages.string.appendingFormat(message)
    case .ERROR:
      self.telnetMessage = message.appendingFormat("\n")
      //                   self.statusMessages.string = self.statusMessages.string.appendingFormat("\n")
    //                   self.statusMessages.string = self.statusMessages.string.appendingFormat(message)
    case .CALL:
      self.sendClusterCommand(message: "W6OP", commandType: CommandType.LOGON)
    case .NAME:
      self.sendClusterCommand(message: "set/name \(fullname)", commandType: CommandType.CALLSIGN)
    case .QTH:
      self.sendClusterCommand(message: "set/qth \(location)", commandType: CommandType.QTH)
    case .LOCATION:
      self.sendClusterCommand(message: "set/qra \(grid)", commandType: CommandType.MESSAGE)// want lat/long
    case .INFO:
      self.telnetMessage = message.appendingFormat("\n")
      //self.statusMessages.string = self.statusMessages.string.appendingFormat("\n")
    //self.statusMessages.string = self.statusMessages.string.appendingFormat(message)
    default:
      self.telnetMessage = message.appendingFormat("\n")
      //self.statusMessages.string = self.statusMessages.string.appendingFormat("\n")
      //self.statusMessages.string = self.statusMessages.string.appendingFormat(message)
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
    //         switch messageKey {
    //         case .CLUSTERTYPE:
    //             UI {
    //                 self.clusterTypeLabel.stringValue = message.condenseWhitespace()
    //             }
    //         case .ANNOUNCEMENT:
    //             UI {
    //                 self.annoucementsLabel.stringValue = message.condenseWhitespace()
    //             }
    //         case .INFO:
    //             UI {
    //                 self.statusMessages.string = self.statusMessages.string.appendingFormat("\n")
    //                 self.statusMessages.string = self.statusMessages.string.appendingFormat(message)
    //             }
    //         case .ERROR:
    //             UI {
    //                 self.statusMessages.string = self.statusMessages.string.appendingFormat("\n")
    //                 self.statusMessages.string = self.statusMessages.string.appendingFormat(message)
    //             }
    //         case .SPOTRECEIVED:
    //             UI {
    //                 self.updateClusterSpotsEx(message: message, messageType: messageKey)
    //             }
    //         case .SHOWDXSPOTS:
    //             UI {
    //                 self.updateClusterSpotsEx(message: message, messageType: messageKey)
    //             }
    //         default:
    //             break
    //         }
  }
  
  /**
   QRZ Manager protocol - Receive the session key from QRZ.com.
   - parameters:
   - qrzManager: Reference to the class sending the message.
   - messageKey: Key associated with this message.
   - message: message text.
   */
  func qrzManagerdidGetSessionKey(_ qrzManager: QRZManager, messageKey: QRZManagerMessage, haveSessionKey: Bool) {
    //         UI {
    //             self.haveSessionKey = haveSessionKey
    //             print("Session key arrived")
    //         }
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
  
  
} // end class

// MARK: - Get the QRZ Session Key
//UserDefaults.standard.object(forKey: "username")


// MARK: - User Defaults

// https://www.simpleswiftguide.com/how-to-use-userdefaults-in-swiftui/
class UserSettings: ObservableObject {
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
    self.username = UserDefaults.standard.string(forKey: "username") ?? ""
    self.password = UserDefaults.standard.string(forKey: "password") ?? ""
    self.fullname = UserDefaults.standard.string(forKey: "fullname") ?? ""
    self.location = UserDefaults.standard.string(forKey: "location") ?? ""
    self.grid = UserDefaults.standard.string(forKey: "grid") ?? ""
  }
}
