//
//  Controller.swift
//  xCluster
//
//  Created by Peter Bourget on 7/6/20.
//  Copyright © 2020 Peter Bourget. All rights reserved.
//

// shim between UI and Network Controllers
import Cocoa
import Foundation
import SwiftUI
import MapKit
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

public class  Controller: NSObject, ObservableObject, TelnetManagerDelegate, QRZManagerDelegate {
  
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
  var clustermapView: MKMapView! = MKMapView()
  
  let callsign = UserDefaults.standard.string(forKey: "callsign") ?? ""
  let fullname = UserDefaults.standard.string(forKey: "fullname") ?? ""
  let location = UserDefaults.standard.string(forKey: "location") ?? ""
  let grid = UserDefaults.standard.string(forKey: "grid") ?? ""
  let qrzUsername = UserDefaults.standard.string(forKey: "username") ?? ""
  let qrzPassword = UserDefaults.standard.string(forKey: "password") ?? ""
  
  // mapping
  let MAX_SPOTS = 1000
  let MAX_MAP_LINES = 50
  let REGION_RADIUS: CLLocationDistance = 10000000
  let CENTER_LATITUDE = 28.282778
  let CENTER_LONGITUDE = -40.829444
  let KEEP_ALIVE = 200
  
  let STANDARD_STROKE_COLOR = NSColor.blue
  let FT8_STROKE_COLOR = NSColor.red
  let LINE_WIDTH: Float = 5.0 //1.0
  
  weak var keepAliveTimer: Timer!
  var overlays = [MKPolyline]()
  var bandFilters = [Int:Int]()
  
  // MARK: - Initialization
  
  override init () {
    
    super.init()
    
    //clustermapView = MKMapView()
    bandFilters[0] = 0
    
    telnetManager.telnetManagerDelegate = self
    qrzManager.qrzManagerDelegate = self
    
    //clustermapView.delegate = self
    
    /*
     let initialLocation = CLLocation(latitude: CENTER_LATITUDE, longitude: CENTER_LONGITUDE)
     centerMapOnLocation(location: initialLocation)
     
     keepAliveTimer = Timer.scheduledTimer(timeInterval: TimeInterval(KEEP_ALIVE), target: self, selector: #selector(tickleServer), userInfo: nil, repeats: true)
     */
    
    getQRZSessionKey()
    
  }
  
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
          self.statusMessage.append(message.appendingFormat(message))
        }

      case .ERROR:
        UI {
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
          self.statusMessage.append(message.appendingFormat(message))
        }
      default:
        UI {
          self.statusMessage.append(message.appendingFormat(message))
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
      }
      break
    case .ANNOUNCEMENT:
      UI {
        self.statusMessage.append(message.condenseWhitespace())
      }
      break
    case .INFO:
      UI {
        self.statusMessage.append(message.appendingFormat(message))
      }
    case .ERROR:
      UI {
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
   QRZ Manager protocol - Retrieve the session key from QRZ.com.
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
    
          DispatchQueue.global(qos: .userInitiated).async { [weak self] in
              self!.buildMapLines(qrzInfoCombined: qrzInfoCombined)
          }
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
  
  // MARK: - Button Action Implementation ----------------------------------------------------------------------------
     
     /**
      Manage the band button state.
      - parameters:
      - buttonTag: the tag that identifies the button.
      - state: the state of the button .on or .off.
      */
     func setBandButtons( buttonTag: Int, state: NSControl.StateValue) {
         
         // TODO: put clear button outside stackview
         if buttonTag == 9999 {return}
         
         switch state {
         case .on:
             self.bandFilters[buttonTag] = buttonTag
             if buttonTag == 0 {
                 resetBandButtons()
             } else {
                 bandFilters.removeValue(forKey: 0)
                 //allBandsButton.state = .off
             }
         case .off:
             self.bandFilters.removeValue(forKey: buttonTag)
             if self.bandFilters.count == 0 {
                 //allBandsButton.state = .on
                 self.bandFilters[0] = 0
             }
         default:
             break
         }
         
         filterMapLines()
     }
     
     /**
      Turn off all the buttons if the ALL button is on.
      - parameters:
      */
     func resetBandButtons()
     {
//         for case let button as NSButton in self.bandStackView.subviews {
//             if button.tag != 0 && button.tag != 9999 {
//                 button.state = .off
//                 bandFilters.removeValue(forKey: button.tag)
//             }
//         }
     }
     
     // MARK: - Implementation ----------------------------------------------------------------------------
     
     @objc func tickleServer() {
         print("timer fired.")
         let bs = String(UnicodeScalar(8)) //"BACKSPACE"
         sendClusterCommand(message: bs, commandType: CommandType.KEEPALIVE)
     }
     // MARK: - Map Implementation ----------------------------------------------------------------------------
      
      func centerMapOnLocation(location: CLLocation) {
          let coordinateRegion = MKCoordinateRegion(center: location.coordinate,
                                                    latitudinalMeters: REGION_RADIUS, longitudinalMeters: REGION_RADIUS)
          clustermapView.setRegion(coordinateRegion, animated: true)
      }
      
      /*
       Build the line (overlay) to display on the map.
       - parameters:
       - qrzInfoCombined: combined data of a pair of call signs QRZ information.
       */
      func buildMapLines(qrzInfoCombined: QRZInfoCombined) {
          
          if qrzInfoCombined.error {return}
          
          // now have an array of arrays - need to flatten array
          
          let locations = [
              CLLocationCoordinate2D(latitude: qrzInfoCombined.spotterLatitude, longitude: qrzInfoCombined.spotterLongitude),
              CLLocationCoordinate2D(latitude: qrzInfoCombined.dxLatitude, longitude: qrzInfoCombined.dxLongitude)]
        
          
          let polyline = MKPolyline(coordinates: locations, count: locations.count)
          polyline.title = String(qrzInfoCombined.band)
          self.overlays.append(polyline)
          
          if overlays.count > 50 {
              let deletedPolyline = overlays.remove(at: overlays.count - 1)
              self.clustermapView.removeOverlay(deletedPolyline)
          }
          
          //print("\(qrzInfoCombined.spotterCall) : \(qrzInfoCombined.dxCall) : \(qrzInfoCombined.band)")
          
        UI {
          self.clustermapView.addOverlay(polyline)
          //self.filterMapLines()
        }
      }
      
      /*
       Delete any map lines that don't meet the filter criteria.
       If the filter is "All" put all the map lines back
       */
      func filterMapLines() {
          // remove map overlays that don't match that band(s)
          // TODO: add back lines when a filter button turns off
        UI {
          self.clustermapView.removeOverlays(self.clustermapView.overlays)
        }
          
          if bandFilters[0] == nil {
              var polylines = [[MKPolyline]]()
              for band in bandFilters.values {
                  // array of lines for a specific band
                  polylines.append(self.overlays.filter { $0.title == String(band) })
                  print("band filter: \(band)")
              }
              
              // array of all filters lines
              let flattened = polylines.flatMap { $0 }
            UI {
              self.clustermapView.addOverlays(flattened)
            }
          } else {
              // show all lines
            UI {
              self.clustermapView.removeOverlays(self.clustermapView.overlays)
              self.clustermapView.addOverlays(self.overlays)
            }
          }
      }
      
      /*
       Required function to render a polyline.
       - parameters:
       */
//  public func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
//    var polylineView: MKPolylineRenderer? = nil
//   
//    if let overlay = overlay as? MKPolyline {
//      polylineView = MKPolylineRenderer(polyline: overlay)
//      polylineView?.strokeColor = self.STANDARD_STROKE_COLOR
//      polylineView?.lineWidth = CGFloat(self.LINE_WIDTH)
//      print ("returning overlay")
//    }
//    
//    return polylineView!
//  }

} // end class


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
