//
//  TelnetManager.swift
//  xCluster
//
//  Created by Peter Bourget on 7/8/20.
//  Copyright © 2020 Peter Bourget. All rights reserved.
//

import Cocoa
import Network
import os

@available(OSX 10.15, *)
protocol TelnetManagerDelegate: class {
    
    func connect(clusterName: String)
    
    func telnetManagerStatusMessageReceived(_ telnetManager: TelnetManager, messageKey: TelnetManagerMessage, message: String)
    
    func telnetManagerDataReceived(_ telnetManager: TelnetManager, messageKey: TelnetManagerMessage, message: String)
}


@available(OSX 10.15, *)
class TelnetManager {
    
    // MARK: - Field Definitions ----------------------------------------------------------------------------
    
    private let concurrentTelnetQueue =
        DispatchQueue(
            label: "com.w6op.virtualcluster.telnetQueue",
            attributes: .concurrent)
    
    
    static let model_log = OSLog(subsystem: "com.w6op.TelnetManager", category: "Model")
    // delegate to pass messages back to viewcontroller
    weak var telnetManagerDelegate:TelnetManagerDelegate?
    
    var connection: NWConnection!
    var connected: Bool
    var connectionChanged: Bool
    var loggedOn : Bool
    
    var clusterType: ClusterType
    var currentCommandType: CommandType
    
    // MARK: - init Overrides ----------------------------------------------------------------------------
    
     init() {
        
        self.connected = false
        self.currentCommandType = .IGNORE // change to INIT
        self.clusterType = ClusterType.UNKNOWN
        self.connectionChanged = false
        self.loggedOn = false
        
        //super.init()
    }
    
    // MARK: - Network Implementation ----------------------------------------------------------------------------
    
    /**
     Connect to the cluster server.
     - parameters:
     - host: The host name to connect to.
     - port: The port to connect to.
     */
    func connect(host: String, port: String) {
        
        connection = NWConnection(host: NWEndpoint.Host(host), port: NWEndpoint.Port(port) ?? 23, using: NWParameters.tcp)
        
        connection.stateUpdateHandler = { newState in
            
            switch newState {
            case .ready:
                self.connected = true
                self.connectionChanged = true
                self.clusterType = .UNKNOWN
                
                self.telnetManagerDelegate?.telnetManagerStatusMessageReceived(self, messageKey: .CONNECTED, message: "Connected to \(host)")
  
                print("Connected")
                
                    self.telnetManagerDelegate?.telnetManagerDataReceived(self, messageKey: .CLUSTERTYPE, message: "Connected to Unknown cluster type")
                self.startReceive()
            case .waiting(let error):
                    self.telnetManagerDelegate?.telnetManagerStatusMessageReceived(self, messageKey: .WAITING, message: "Waiting: \(error)")
            case .failed(let error):
                    self.telnetManagerDelegate?.telnetManagerStatusMessageReceived(self, messageKey: .ERROR, message: "Error: \(error)")
            default:
                break
            }
        }
        
        connection.start(queue: concurrentTelnetQueue)
    }
    
    /**
     Start the receiver.
     */
    func startReceive() {
        connection.receive(minimumIncompleteLength: 1, maximumLength: Int(UINT32_MAX), completion: receiveMessage)
    }
    
    /**
     Send a message or command to the cluster server.
     - parameters:
     - message: The data sent.
     - commandType: The type of command received.
     */
    func send(_ message: String, commandType: CommandType) {
        
        self.currentCommandType = commandType
        
        if connected {
            let newmessage = message + "\r\n"
            
            if let data = newmessage.data(using: .utf8) {
                connection.send(content: data, completion: .contentProcessed({(error) in
                    if let error = error {
                        print(error)
                            self.telnetManagerDelegate?.telnetManagerStatusMessageReceived(self, messageKey: .ERROR, message: "ERROR: \(error)")
                        return
                    }
                }))
            }
        }
    }
    
    /**
     Receive data from the active connection.
     - parameters:
     - data: The data received.
     - context:
     - isComplete:
     - error:
     */
    func receiveMessage(data: Data?, context: NWConnection.ContentContext?, isComplete: Bool, error: NWError?) {

        // ignore nil messages
        guard data != nil else { return }
        if currentCommandType == .KEEPALIVE {currentCommandType = .IGNORE}

        guard let response = String(data: data!, encoding: .utf8)?.trimmingCharacters(in: .whitespaces) else {
            return
        }
            //os_log("Data received.", log: TelnetManager.model_log, type: .info)
        let lines = response.components(separatedBy: "\r\n")
        
            for line in lines {
                if !line.isEmpty {
                    //print(line)
                    determineMessageType(message: line.trimmingCharacters(in: .whitespaces))
                }
            }
        
        if isComplete {
            os_log("Data receive completed.", log: TelnetManager.model_log, type: .info)
        }

        startReceive()
    }
    
    /**
     Disconnect from the telent session and break the connection.
     */
    func disconnect() {
        if connected {
            send("bye", commandType: .IGNORE)
            connection.cancel()
        }
    }
    
    /**
     Determine if the message is a spot or a status message.
     - parameters:
     - message: The message text.
     */
    func determineMessageType(message: String) {
        
        switch message.description {
        case _ where message.contains("login:"):

                self.telnetManagerDelegate?.telnetManagerStatusMessageReceived(self, messageKey: .LOGON, message: message)
            return
        case _ where message.contains("Please enter your call"):
  
                self.telnetManagerDelegate?.telnetManagerStatusMessageReceived(self, messageKey: .CALL, message: message)
      
            return
        case _ where message.contains("Please enter your name"):
      
                self.telnetManagerDelegate?.telnetManagerStatusMessageReceived(self, messageKey: .NAME, message: message)
        
            return
        case _ where message.contains("Please enter your QTH"):
      
                self.telnetManagerDelegate?.telnetManagerStatusMessageReceived(self, messageKey: .QTH, message: message)
         
            return
        case _ where message.contains("Please enter your location"):
           
                self.telnetManagerDelegate?.telnetManagerStatusMessageReceived(self, messageKey: .LOCATION, message: message)
         
            return
        case _ where message.contains("DX de"):
           
                self.telnetManagerDelegate?.telnetManagerDataReceived(self, messageKey: .SPOTRECEIVED, message: message)
           
            return
        case _ where message.contains("Is this correct"):
            send("Y", commandType: .YES)
            currentCommandType = .YES
            return
        case _ where message.contains("dxspider >"):
            if !loggedOn {
                loggedOn = true
            //send("set/ve7cc", commandType: .IGNORE)
            // CC11^14197.0^R7DN^27-Feb-2019^1628Z^59+9^PI3CQ^179^139^EA7URM-5^30^16^27^14^^^Eur-Russia-UA^Netherlands-PA^^\r\n
            // DX de F4FGC:     14074.0  K7QXG        FT8 Tnx                        1630Z\u{07}\u{07}\r\n
           }
            return
        case _ where Int(message.condenseWhitespace().prefix(4)) != nil:
          
                self.telnetManagerDelegate?.telnetManagerDataReceived(self, messageKey: .SHOWDXSPOTS, message: message)
           
        default:
            determineClusterType(message: message)
            
                self.telnetManagerDelegate?.telnetManagerDataReceived(self, messageKey: .INFO, message: message)
          
        }
    }
    
    func determineClusterType(message: String) {
        if self.connectionChanged {
            switch message.description {
            case _ where message.contains("CC-Cluster"): // CCC_Commands
                self.clusterType = ClusterType.CCCLUSTER
                self.connectionChanged = false
              
                    self.telnetManagerDelegate?.telnetManagerDataReceived(self, messageKey: .CLUSTERTYPE, message: "Connected to CC-Cluster")
               
            case _ where message.contains("CC Cluster"), _ where message.contains("CCC_Commands"):
                self.clusterType = ClusterType.CCCLUSTER
                self.connectionChanged = false
                
                    self.telnetManagerDelegate?.telnetManagerDataReceived(self, messageKey: .CLUSTERTYPE, message: "Connected to CC-Cluster")
              
            case _ where message.contains("AR-Cluster"):
                self.clusterType = ClusterType.ARCLUSTER
                self.connectionChanged = false
               
                    self.telnetManagerDelegate?.telnetManagerDataReceived(self, messageKey: .CLUSTERTYPE, message: "Connected to AR-Cluster")
               
            case _ where message.contains("DXSpider"):
                self.clusterType = ClusterType.DXSPIDER
                self.connectionChanged = false
               
                    self.telnetManagerDelegate?.telnetManagerDataReceived(self, messageKey: .CLUSTERTYPE, message: "Connected to DXSpider")
             
            case _ where message.uppercased().contains("VE7CC"):
                self.clusterType = ClusterType.VE7CC
                self.connectionChanged = false
              
                    self.telnetManagerDelegate?.telnetManagerDataReceived(self, messageKey: .CLUSTERTYPE, message: "Connected to VE7CC Cluster")
              
            default:
                self.clusterType = ClusterType.UNKNOWN
            }
            //
        }
    }
      
} // end class

