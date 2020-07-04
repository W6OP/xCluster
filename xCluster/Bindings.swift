//
//  Bindings.swift
//  xCluster
//
//  Created by Peter Bourget on 7/4/20.
//  Copyright © 2020 Peter Bourget. All rights reserved.
//

import Foundation

/// MARK: Band Definition

struct BandIdentifier : Identifiable, Hashable {
    var band: String
    var id: Int
}

let bandData = [
    BandIdentifier(band: "Clear",id: 0),
    BandIdentifier(band: "All",id: 1),
    BandIdentifier(band: "VHF",id: 99),
    BandIdentifier(band: "160m",id: 2),
    BandIdentifier(band: "80m",id: 3),
    BandIdentifier(band: "60m",id: 4),
    BandIdentifier(band: "40m",id: 5),
    BandIdentifier(band: "30m",id: 6),
    BandIdentifier(band: "20m",id: 7),
    BandIdentifier(band: "18m",id: 8),
    BandIdentifier(band: "15m",id: 9),
    BandIdentifier(band: "12m",id: 10),
    BandIdentifier(band: "10m",id: 11),
    BandIdentifier(band: "6m",id: 12),
]

/// MARK: Cluster Definition

struct ClusterIdentifier: Identifiable, Hashable {
    var name: String
    var address: String
    var port: String
    var id: Int
}

let clusterData = [
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
