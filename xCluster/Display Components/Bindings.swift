//
//  Bindings.swift
//  xCluster
//
//  Created by Peter Bourget on 7/4/20.
//  Copyright © 2020 Peter Bourget. All rights reserved.
//

import Foundation
import SwiftUI
import Combine

// MARK: - Band Definition

struct BandIdentifier : Identifiable, Hashable {
    var band: String
    var id: Int
    var isSelected: Bool
//    {
//      willSet {
//      // Here's where any code goes that needs to run when a switch is toggled
//      print("\(band) is \(isSelected ? "enabled" : "disabled")")
//        //setBandButtons(id, isSelected)
//
//    }
//  }
}

let bandData = [
  BandIdentifier(band: "All",id: 0, isSelected: false),
  BandIdentifier(band: "VHF",id: 99, isSelected: false),
    BandIdentifier(band: "160m",id: 160, isSelected: false),
    BandIdentifier(band: "80m",id: 80, isSelected: false),
    BandIdentifier(band: "60m",id: 60, isSelected: false),
    BandIdentifier(band: "40m",id: 40, isSelected: false),
    BandIdentifier(band: "30m",id: 30, isSelected: false),
    BandIdentifier(band: "20m",id: 20, isSelected: false),
    BandIdentifier(band: "18m",id: 18, isSelected: false),
    BandIdentifier(band: "15m",id: 15, isSelected: false),
    BandIdentifier(band: "12m",id: 12, isSelected: false),
    BandIdentifier(band: "10m",id: 10, isSelected: false),
    BandIdentifier(band: "6m",id: 6, isSelected: false),
]

// MARK: - Cluster Definition

struct ClusterIdentifier: Identifiable, Hashable {
    var name: String
    var address: String
    var port: String
    var id: Int
}

let clusterData = [
    ClusterIdentifier(name: "Select DX Spider Node", address: "", port: "", id: 99),
  
    ClusterIdentifier(name: "WW1R_9", address: "dxc.ww1r.com", port: "7300", id: 0),
    ClusterIdentifier(name: "VE7CC", address: "dxc.ve7cc.net", port: "23", id: 1),
    ClusterIdentifier(name: "dxc_middlebrook_ca", address: "dxc.middlebrook.ca", port: "8000", id: 2),
    ClusterIdentifier(name: "WA9PIE-2", address: "hrd.wa9pie.net", port: "8000", id: 3),
    
    ClusterIdentifier(name: "AE5E", address: "dxspots.com", port: "23", id: 4),
    ClusterIdentifier(name: "W6CUA", address: "w6cua.no-ip.org", port: "7300", id: 5),
    ClusterIdentifier(name: "W6KK", address: "w6kk.zapto.org", port: "7300", id: 6),
    
    ClusterIdentifier(name: "N5UXT", address: "dxc.n5uxt.org", port: "23", id: 7),
    ClusterIdentifier(name: "GB7DXS", address: "81.149.0.149", port: "7300", id: 8),
    // telnet.reversebeacon.net port 7001
    ClusterIdentifier(name: "FT8 RBN", address: "telnet.reversebeacon.net", port: "7001", id: 9),
    // telnet.reversebeacon.net port 7000, for CW and RTTY spots
    ClusterIdentifier(name: "All RBN", address: "telnet.reversebeacon.net", port: "7000", id: 10),
]

//https://stackoverflow.com/questions/56996272/how-can-i-trigger-an-action-when-a-swiftui-toggle-is-toggled
// allows an action to be attached to a Toggle
extension Binding {
    func didSet(execute: @escaping (Value) -> Void) -> Binding {
        return Binding(
            get: {
                return self.wrappedValue
            },
            set: {
                self.wrappedValue = $0
                execute($0)
            }
        )
    }
}

//struct ClusterSpot: Identifiable, Hashable {
//  var dx: String
//  var frequency: String
//  var spotter: String
//  var datetime: String
//  var comment: String
//  var grid: String
//  
//  var id: Int
//}
//
//let clusterSpots = ClusterSpot(dx: "----------", frequency: "----------", spotter: "----------", datetime: "----", comment: "-------",grid: "----", id: 0)

/**
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
 
 */
