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
    BandIdentifier(band: "160m",id: 160, isSelected: true),
    BandIdentifier(band: "80m",id: 80, isSelected: true),
    BandIdentifier(band: "60m",id: 60, isSelected: true),
    BandIdentifier(band: "40m",id: 40, isSelected: true),
    BandIdentifier(band: "30m",id: 30, isSelected: true),
    BandIdentifier(band: "20m",id: 20, isSelected: true),
    BandIdentifier(band: "18m",id: 18, isSelected: true),
    BandIdentifier(band: "15m",id: 15, isSelected: true),
    BandIdentifier(band: "12m",id: 12, isSelected: true),
    BandIdentifier(band: "10m",id: 10, isSelected: true),
    BandIdentifier(band: "6m",id: 6, isSelected: true),
]

// MARK: - Cluster Definition

struct ClusterIdentifier: Identifiable, Hashable {
    var name: String
    var address: String
    var port: String
    var id: Int
}

let clusterData = [
    ClusterIdentifier(name: "Select DX Spider Node", address: "", port: "", id: 9999),
  
    ClusterIdentifier(name: "WW1R_9", address: "dxc.ww1r.com", port: "7300", id: 0),
    ClusterIdentifier(name: "VE7CC", address: "dxc.ve7cc.net", port: "23", id: 1),
    ClusterIdentifier(name: "dxc_middlebrook_ca", address: "dxc.middlebrook.ca", port: "8000", id: 2),
    ClusterIdentifier(name: "WA9PIE", address: "dxc.wa9pie.net", port: "8000", id: 3),
    ClusterIdentifier(name: "WA9PIE-2", address: "hrd.wa9pie.net", port: "8000", id: 4),
    
    ClusterIdentifier(name: "AE5E", address: "dxspots.com", port: "23", id: 5),
    ClusterIdentifier(name: "W6CUA", address: "w6cua.no-ip.org", port: "7300", id: 6),
    ClusterIdentifier(name: "W6KK", address: "w6kk.zapto.org", port: "7300", id: 7),
    
    ClusterIdentifier(name: "N5UXT", address: "dxc.n5uxt.org", port: "23", id: 8),
    ClusterIdentifier(name: "GB7DXS", address: "81.149.0.149", port: "7300", id: 9),
    
    ClusterIdentifier(name: "K1TTT", address: "k1ttt.net", port: "7373", id: 10),
    ClusterIdentifier(name: "K0XM-5", address: "dxc.k0xm.net", port: "7300", id: 11),
    ClusterIdentifier(name: "K1RFI", address: "k1rfi.com", port: "7300", id: 12),
    ClusterIdentifier(name: "K1SA", address: "sebago.ddns.net", port: "7373", id: 13),
    
    // telnet.reversebeacon.net port 7001, for FT8 spots
    ClusterIdentifier(name: "FT8 RBN", address: "telnet.reversebeacon.net", port: "7001", id: 99),
    // telnet.reversebeacon.net port 7000, for CW and RTTY spots
    ClusterIdentifier(name: "CW/RTTY", address: "telnet.reversebeacon.net", port: "7000", id: 100),
]

/**
 K0XM-5 dxc.k0xm.net:7300
 K1RFI k1rfi.com:7300
 K1SA sebago.ddns.net:7373
 K1TTT k1ttt.net:7373
 K1VU k1vu.miketheactuary.com:4242
 K3KT-1 216.135.40.104:7300
 K3WW k3ww.gofrc.org:7300
 K4FX dxc.k4fx.net:7300
 K4JW k4jw.no-ip.com:41414
 K4KYD-2 dxc.k4kyd.com:7300
 K4QC hvldx.tzo.com:41112
 K4UJ cluster-us.dx-is.com:7300
 K4UJ-1 cluster-eu.dx-is.com:7300
 K4ZR k4zr.no-ip.org:7300
 K5DX dxc.tdxs.net:7373
 K5JZ dxc.k5jz.net:7373
 K6KOZ k6koz.serveftp.com:7300
 K7AR k7ar.net:7374
 K7EK-1 k7ek.ddns.net:9000
 K7SDX k7sdx.no-ip.org:7300
 K8BTT-1 cluster.dxworld.info:8000
 K9LC k9lc.ddns.net:7300
 K9USA soliton.csl.illinois.edu:8000
 K9WMS-2 k9wms.com:7374
 K9WMS-3 k9wms.com:7373
 KA0MOS-10 dxcluster.servebeer.com:2323
 KA2PBT-1 dx.ka2pbt.com:7300
 KA9OKH-2 96.27.205.110:7373
 KB2FAF-12 kb2faf.net:7300
 KB2SSE-2 kb2sse.dyndns.org:7300
 KB5VJY-1 kb5vjy.com:8000
 KB8PMY-3 www.kb8pmy.net:7300
 KC2CWT-9 dxspider.kc2cwt.net:7300
 KC9AOP-1 dxspots.kc9aop.net:7300
 KC9GWK-2 kc9gwk.squaretfarm.com:7300
 KD4GCA-9 kd4gca.dyndns.org:7300
 KD8ATF-2 kd8atf.ddns.net:7300
 KE0CQF-2 ke0cqf.120v.ac:7300
 KE2L-5 dx.scarcnj.org:7300
 KE2OI-10 ke2oi.dyndns.org:7300
 KF2FK-1 themaincomputer.net:7300
 KF4LLF-8 kf4llf.no-ip.org:7300
 KG4OOL-2 dxfinder.bfielding.com:7300
 KI5T-2 98.181.43.23:7300
 KK4UIL hobbyshack.no-ip.org:7300
 KN9N kn9n.no-ip.org:7300
 KQ8M kq8m.no-ip.org:7373
 KQ8M-2 kq8m.no-ip.org:7374
 KQ8M-3 kq8m.no-ip.org:3608
 KX4O-2 spots.qsoparty.com:7300
 KY4XX-3 dxc.ky4xx.com:7300
 KY9J-2 dxc.ky9j.com:7300
 */

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
