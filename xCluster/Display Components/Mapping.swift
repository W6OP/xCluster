//
//  Mapping.swift
//  xCluster
//
//  Created by Peter Bourget on 7/5/20.
//  Copyright © 2020 Peter Bourget. All rights reserved.
//

import Foundation
import MapKit
import SwiftUI

struct MapView: NSViewRepresentable {
    typealias MapViewType = NSViewType
    
    func makeNSView(context: Context) -> MKMapView {
        MKMapView()
    }

  func updateNSView(_ uiView: MKMapView, context: Context) {
  }
}
