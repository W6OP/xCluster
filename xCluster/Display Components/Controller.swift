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
//    switch messageKey {
//           case .LOGON:
//               UI {
//                   self.sendLogin()
//               }
//           case .WAITING:
//               UI {
//                   self.statusMessages.string = self.statusMessages.string.appendingFormat("\n")
//                   self.statusMessages.string = self.statusMessages.string.appendingFormat(message)
//               }
//           case .ERROR:
//               UI {
//                   self.statusMessages.string = self.statusMessages.string.appendingFormat("\n")
//                   self.statusMessages.string = self.statusMessages.string.appendingFormat(message)
//               }
//           case .CALL:
//               UI {
//                   self.sendClusterCommand(message: "W6OP", commandType: CommandType.LOGON)
//               }
//           case .NAME:
//               UI {
//                   self.sendClusterCommand(message: "set/name Peter Bourget", commandType: CommandType.CALLSIGN)
//               }
//           case .QTH:
//               UI {
//                   self.sendClusterCommand(message: "set/qth Stockton, CA", commandType: CommandType.QTH)
//               }
//           case .LOCATION:
//               do {
//                   self.sendClusterCommand(message: "set/qra CM98ha", commandType: CommandType.MESSAGE)// want lat/long
//               }
//           case .INFO:
//               do {
//                   self.statusMessages.string = self.statusMessages.string.appendingFormat("\n")
//                   self.statusMessages.string = self.statusMessages.string.appendingFormat(message)
//               }
//           default:
//               UI {
//                   self.statusMessages.string = self.statusMessages.string.appendingFormat("\n")
//                   self.statusMessages.string = self.statusMessages.string.appendingFormat(message)
//               }
//           }
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
  
  @Published var spots = [Spots]()
  var qrzManager: QRZManager!
  var telnetManager: TelnetManager!
  var spotProcessor: SpotProcessor!
  
  
  let qrzUsername = UserDefaults.standard.object(forKey: "username")
  let qrzPassword = UserDefaults.standard.object(forKey: "password")
  
  init () {
     telnetManager = TelnetManager()
     telnetManager.telnetManagerDelegate = self
    
     qrzManager = QRZManager()
     qrzManager.qrzManagerDelegate = self
    
     spotProcessor = SpotProcessor()
    
     getQRZSessionKey()
  }
  
  func getQRZSessionKey(){
    concurrentSpotProcessorQueue.async() { [weak self] in
        self?.qrzManager.parseQRZSessionKeyRequest(name: "w6op", password: "LetsFindSomeDXToday$56")
    }
  }
  
} // end class

// MARK: - Get the QRZ Session Key
//UserDefaults.standard.object(forKey: "username")


// MARK: - User Defaults

// https://www.simpleswiftguide.com/how-to-use-userdefaults-in-swiftui/
class UserSettings: ObservableObject {
    @Published var username: String {
        didSet {
            UserDefaults.standard.set(username, forKey: "username")
        }
    }
  
  @Published var password: String {
      didSet {
          UserDefaults.standard.set(username, forKey: "password")
      }
  }
    
    init() {
        self.username = UserDefaults.standard.object(forKey: "username") as? String ?? ""
        self.password = UserDefaults.standard.object(forKey: "password") as? String ?? ""
    }
}
