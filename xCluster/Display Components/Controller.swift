//
//  Controller.swift
//  xCluster
//
//  Created by Peter Bourget on 7/6/20.
//  Copyright © 2020 Peter Bourget. All rights reserved.
//

import Foundation

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

public class  Controller: ObservableObject {
  @Published var spots = [Spots]()
  
  init () {
    
  }
  
} // end class
