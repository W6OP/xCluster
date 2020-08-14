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

protocol TelnetManagerDelegate: class {
 
  func connect(clusterName: String)
  
  func telnetManagerStatusMessageReceived(_ telnetManager: TelnetManager, messageKey: TelnetManagerMessage, message: String)
  
  func telnetManagerDataReceived(_ telnetManager: TelnetManager, messageKey: TelnetManagerMessage, message: String)
}

// Someday look at rewriting this from
// https://rderik.com/blog/building-a-server-client-aplication-using-apple-s-network-framework/

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
  var isLoggedOn : Bool
  
  var clusterType: ClusterType
  var currentCommandType: CommandType
  
  // MARK: - init Overrides ----------------------------------------------------------------------------
  
  init() {
    
    self.connected = false
    self.currentCommandType = .ignore // change to INIT
    self.clusterType = ClusterType.unknown
    self.connectionChanged = false
    self.isLoggedOn = false
    
  }
  
  // MARK: - Network Implementation ----------------------------------------------------------------------------
  
  /**
   Connect to the cluster server.
   - parameters:
   - host: The host name to connect to.
   - port: The port to connect to.
   */
  func connect(host: String, port: String) {
    
//    let tcpOptions = NWProtocolTCP.Options()
//    tcpOptions.enableKeepalive = true
//    tcpOptions.keepaliveIdle = 2
//    tcpOptions.keepaliveCount = 2
//    tcpOptions.keepaliveInterval = 2
//
    connection = NWConnection(host: NWEndpoint.Host(host), port: NWEndpoint.Port(port) ?? 23, using: NWParameters.tcp)
    
    connection.stateUpdateHandler = { state in
      
      switch state {
      case .ready:
        self.connected = true
        self.connectionChanged = true
        self.clusterType = .unknown
        
        self.telnetManagerDelegate?.telnetManagerStatusMessageReceived(self, messageKey: .connected, message: "Connected to \(host)")
  
        self.telnetManagerDelegate?.telnetManagerDataReceived(self, messageKey: .clustertype, message: "Connected") //  to Unknown cluster type
        self.startReceive()
        
      case .waiting(let error):
        self.connection.restart()
        print ("Restarted: \(error)")
      
      case .failed(let error):
        self.handleConnectionError(error: error)

      case .cancelled:
        print ("Connection Cancelled")
//         self.telnetManagerDelegate?.telnetManagerStatusMessageReceived(self, messageKey: .disconnected, message: "")
        
      case .setup:
       print ("Connection Setup")
        
      case .preparing:
        print ("Connection Preparing")
        
      @unknown default:
        print ("Connection State Unknown")
      }
    }
    
    connection.start(queue: concurrentTelnetQueue)
  }
  
  /**
   timer fired.
   sequence 22 Invalid command
   sequence 5 W6OP de WW1R-9  2-Aug-2020 1619Z dxspider >
   timer fired.
   timer fired.
   2020-08-02 09:26:14.073962-0700 TelnetTester[9428:10678357] [] nw_socket_handle_socket_event [C2.1:1] Socket SO_ERROR [54: Connection reset by peer]
   Connection Error: POSIXErrorCode: Connection reset by peer Localized: The operation couldn’t be completed. (Network.NWError error 0.)
   timer fired.
   2020-08-02 09:29:34.040344-0700 TelnetTester[9428:10678358] [] nw_flow_add_write_request [C2.1 107.211.74.188:7300 failed socket-flow (satisfied (Path is satisfied), interface: en0, ipv4, ipv6, dns)] cannot accept write requests
   2020-08-02 09:29:34.040435-0700 TelnetTester[9428:10678358] [] nw_write_request_report [C2] Send failed with error "Socket is not connected"
   Error: SEND ERROR: POSIXErrorCode: Socket is not connected
   timer fired.
   */
  
  
  
  /**
   Hand the errors when there is a connection problem.
   */
  func handleConnectionError(error: NWError) {
    
    //print("Connection Error: \(error) Localized: \(error.localizedDescription)")
    
    switch error {
   
    case .posix(.ECONNREFUSED):
      print("Posix .ECONNREFUSED")
  
    case .posix(.EPERM):
      print("Posix .EPERM")

    case .posix(.ENOENT):
      print("Posix .ENOENT")

//    case .posix(.ESRCH):
//      break
//    case .posix(.EINTR):
//      break
//    case .posix(.EIO):
//      break
//    case .posix(.ENXIO):
//      break
//    case .posix(.E2BIG):
//      break
//    case .posix(.ENOEXEC):
//      break
//    case .posix(.EBADF):
//      break
//    case .posix(.ECHILD):
//      break
//    case .posix(.EDEADLK):
//      break
//    case .posix(.ENOMEM):
//      break
//    case .posix(.EACCES):
//      break
//    case .posix(.EFAULT):
//      break
//    case .posix(.ENOTBLK):
//      break
//    case .posix(.EBUSY):
//      break
//    case .posix(.EEXIST):
//      break
//    case .posix(.EXDEV):
//      break
//    case .posix(.ENODEV):
//      break
//    case .posix(.ENOTDIR):
//      break
//    case .posix(.EISDIR):
//      break
//    case .posix(.EINVAL):
//      break
//    case .posix(.ENFILE):
//      break
//    case .posix(.EMFILE):
//      break
//    case .posix(.ENOTTY):
//      break
//    case .posix(.ETXTBSY):
//      break
//    case .posix(.EFBIG):
//      break
//    case .posix(.ENOSPC):
//      break
//    case .posix(.ESPIPE):
//      break
//    case .posix(.EROFS):
//      break
//    case .posix(.EMLINK):
//      break
//    case .posix(.EPIPE):
//      break
//    case .posix(.EDOM):
//      break
//    case .posix(.ERANGE):
//      break
//    case .posix(.EAGAIN):
//      break
//    case .posix(.EINPROGRESS):
//      break
//    case .posix(.EALREADY):
//      break
//    case .posix(.ENOTSOCK):
//      break
//    case .posix(.EDESTADDRREQ):
//      break
//    case .posix(.EMSGSIZE):
//      break
//    case .posix(.EPROTOTYPE):
//      break
//    case .posix(.ENOPROTOOPT):
//      break
//    case .posix(.EPROTONOSUPPORT):
//      break
//    case .posix(.ESOCKTNOSUPPORT):
//      break
//    case .posix(.ENOTSUP):
//      break
//    case .posix(.EPFNOSUPPORT):
//      break
//    case .posix(.EAFNOSUPPORT):
//      break
//    case .posix(.EADDRINUSE):
//      break
//    case .posix(.EADDRNOTAVAIL):
//      break
//    case .posix(.ENETDOWN):
//      break
//    case .posix(.ENETUNREACH):
//      break
//    case .posix(.ENETRESET):
//      break
//    case .posix(.ECONNABORTED):
//      break
    case .posix(.ECONNRESET):
      print("Posix .ECONNRESET")
      self.telnetManagerDelegate?.telnetManagerStatusMessageReceived(self, messageKey: .disconnected, message: "")
//    case .posix(.ENOBUFS):
//      break
//    case .posix(.EISCONN):
//      break
    case .posix(.ENOTCONN):
      print("Posix .ENOTCONN")
      self.telnetManagerDelegate?.telnetManagerStatusMessageReceived(self, messageKey: .disconnected, message: "")
//    case .posix(.ESHUTDOWN):
//      break
//    case .posix(.ETOOMANYREFS):
//      break
//    case .posix(.ETIMEDOUT):
//      break
//    case .posix(.ELOOP):
//      break
//    case .posix(.ENAMETOOLONG):
//      break
//    case .posix(.EHOSTDOWN):
//      break
    case .posix(.EHOSTUNREACH):
      print("Posix .EHOSTUNREACH")
      print("Connection Error: \(error) Localized: \(error.localizedDescription)")
      self.telnetManagerDelegate?.telnetManagerStatusMessageReceived(self, messageKey: .disconnected, message: "")
//    case .posix(.ENOTEMPTY):
//      break
//    case .posix(.EPROCLIM):
//      break
//    case .posix(.EUSERS):
//      break
//    case .posix(.EDQUOT):
//      break
//    case .posix(.ESTALE):
//      break
//    case .posix(.EREMOTE):
//      break
//    case .posix(.EBADRPC):
//      break
//    case .posix(.ERPCMISMATCH):
//      break
//    case .posix(.EPROGUNAVAIL):
//      break
//    case .posix(.EPROGMISMATCH):
//      break
//    case .posix(.EPROCUNAVAIL):
//      break
//    case .posix(.ENOLCK):
//      break
//    case .posix(.ENOSYS):
//      break
//    case .posix(.EFTYPE):
//      break
//    case .posix(.EAUTH):
//      break
//    case .posix(.ENEEDAUTH):
//      break
//    case .posix(.EPWROFF):
//      break
//    case .posix(.EDEVERR):
//      break
//    case .posix(.EOVERFLOW):
//      break
//    case .posix(.EBADEXEC):
//      break
//    case .posix(.EBADARCH):
//      break
//    case .posix(.ESHLIBVERS):
//      break
//    case .posix(.EBADMACHO):
//      break
    case .posix(.ECANCELED):
      print("Posix .ECANCELED")
      // what should I do here?
      break
//    case .posix(.EIDRM):
//      break
//    case .posix(.ENOMSG):
//      break
//    case .posix(.EILSEQ):
//      break
//    case .posix(.ENOATTR):
//      break
//    case .posix(.EBADMSG):
//      break
//    case .posix(.EMULTIHOP):
//      break
//    case .posix(.ENODATA):
//      break
//    case .posix(.ENOLINK):
//      break
//    case .posix(.ENOSR):
//      break
//    case .posix(.ENOSTR):
//      break
//    case .posix(.EPROTO):
//      break
//    case .posix(.ETIME):
//      break
//    case .posix(.ENOPOLICY):
//      break
//    case .posix(.ENOTRECOVERABLE):
//      break
//    case .posix(.EOWNERDEAD):
//      break
//    case .posix(.EQFULL):
//      break
    case .posix(_):
      print("Posix .posix")
      print("Connection Error: \(error) Localized: \(error.localizedDescription)")
      self.telnetManagerDelegate?.telnetManagerStatusMessageReceived(self, messageKey: .disconnected, message: "")
    case .dns(_):
      print("Posix .dns")
    case .tls(_):
      print("Posix .tls")
    @unknown default:
      print("Posix @unknown default")
    }
  }
  
  /**
   Start the receiver.
   Call receiveMessage when completed
   */
  func startReceive() {
    connection.receive(minimumIncompleteLength: 1, maximumLength: Int(UINT32_MAX), completion: receiveMessage)
  }
  
  
   ///Send a message or command to the cluster server.
  ///
   ///- parameters:
   ///- message: The data sent.
   ///- commandType: The type of command received.
  func send(_ message: String, commandType: CommandType) {
    
    self.currentCommandType = commandType
    
    if connected {
      let newmessage = message + "\r\n"
      
      if let data = newmessage.data(using: .utf8) {
        connection.send(content: data, completion: .contentProcessed({(error) in
          if let error = error {
            print("send: \(error)")
            self.telnetManagerDelegate?.telnetManagerStatusMessageReceived(self, messageKey: .error, message: "SEND ERROR: \(error)")
            self.handleConnectionError(error: error)
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
    
    if let error = error {
        print("receiveMessage: \(error)")
        handleConnectionError(error: error)
    }
    
    //guard error == nil else {handleConnectionError(error: error!); return}
    
    // ignore nil messages
    guard data != nil else { return }
    if currentCommandType == .keepalive {currentCommandType = .ignore}
    
    guard let response = String(data: data!, encoding: .utf8)?.trimmingCharacters(in: .whitespaces) else {
      return
    }
    
    let lines = response.components(separatedBy: "\r\n")
    if lines.count == 0 {
      print("nil response: \(response)")
    }
    
    for line in lines {
      if !line.isEmpty {
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
   close or bye
   */
  func disconnect() {
    if connected {
      send("bye", commandType: .ignore)
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
      self.telnetManagerDelegate?.telnetManagerStatusMessageReceived(self, messageKey: .logon, message: message)
      //print("sequence login")
    case _ where message.contains("Please enter your call"):
      self.telnetManagerDelegate?.telnetManagerStatusMessageReceived(self, messageKey: .call, message: message)
      //print("sequence enter call")
    case _ where message.contains("Please enter your name"):
      self.telnetManagerDelegate?.telnetManagerStatusMessageReceived(self, messageKey: .name, message: message)
      //print("sequence enter name")
    case _ where message.contains("Please enter your QTH"):
      self.telnetManagerDelegate?.telnetManagerStatusMessageReceived(self, messageKey: .qth, message: message)
      
    case _ where message.contains("Please enter your location"):
      self.telnetManagerDelegate?.telnetManagerStatusMessageReceived(self, messageKey: .location, message: message)
      //print("sequence enter location")
    case _ where message.contains("DX de"):
      self.telnetManagerDelegate?.telnetManagerDataReceived(self, messageKey: .spotreceived, message: message)

    case _ where message.contains("Is this correct"):
      send("Y", commandType: .yes)
      currentCommandType = .yes
      //print("sequence is this correct")
    case _ where message.contains("dxspider >"):
      //print("sequence dxspider \(message)")
      if !isLoggedOn {
        isLoggedOn = true
        self.telnetManagerDelegate?.telnetManagerStatusMessageReceived(self, messageKey: .logonCompleted, message: message)
      }

    case _ where Int(message.condenseWhitespace().prefix(4)) != nil:
      self.telnetManagerDelegate?.telnetManagerDataReceived(self, messageKey: .showdxspots, message: message)
      //print("sequence show dx spots")
      
    case _ where message.contains("Invalid command"):
      self.telnetManagerDelegate?.telnetManagerDataReceived(self, messageKey: .invalid, message: "")
      print("sequence invalid command \(message)")

    default:
      //print("sequence default \(message)")
      if self.connectionChanged {
          determineClusterType(message: message)
      }
      self.telnetManagerDelegate?.telnetManagerDataReceived(self, messageKey: .info, message: message)
    }
  }
  
  func determineClusterType(message: String) {
    
    //if self.connectionChanged {
      switch message.description {
      case _ where message.contains("Invalid command"):
        self.telnetManagerDelegate?.telnetManagerDataReceived(self, messageKey: .invalid, message: "")
        //print("sequence invalid command duplicate \(message)")
        
      case _ where message.contains("CC-Cluster"): // CCC_Commands
        self.clusterType = ClusterType.cccluster
        self.connectionChanged = false
        //print("sequence cc-cluster")
        self.telnetManagerDelegate?.telnetManagerDataReceived(self, messageKey: .clustertype, message: "Connected to CC-Cluster")
        
      case _ where message.contains("CC Cluster"), _ where message.contains("CCC_Commands"):
        self.clusterType = ClusterType.cccluster
        self.connectionChanged = false
        //print("sequence cc cluster")
        self.telnetManagerDelegate?.telnetManagerDataReceived(self, messageKey: .clustertype, message: "Connected to CC-Cluster")
        
      case _ where message.contains("AR-Cluster"):
        self.clusterType = ClusterType.arcluster
        self.connectionChanged = false
        //print("sequence ar-cluster")
        self.telnetManagerDelegate?.telnetManagerDataReceived(self, messageKey: .clustertype, message: "Connected to AR-Cluster")
        
      case _ where message.contains("DXSpider"):
        self.clusterType = ClusterType.dxspider
        self.connectionChanged = false
        //print("sequence DXSpider")
        self.telnetManagerDelegate?.telnetManagerDataReceived(self, messageKey: .clustertype, message: "Connected to DXSpider")
        
      case _ where message.uppercased().contains("VE7CC"):
        self.clusterType = ClusterType.ve7cc
        self.connectionChanged = false
        //print("sequence ve7cc")
        self.telnetManagerDelegate?.telnetManagerDataReceived(self, messageKey: .clustertype, message: "Connected to VE7CC Cluster")
        
      default:
        self.clusterType = ClusterType.unknown
        //print("sequence default unknown")
      }
    //}
  }
  
} // end class

