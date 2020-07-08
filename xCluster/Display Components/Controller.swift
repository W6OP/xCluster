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

public class  Controller: ObservableObject {
  @Published var spots = [Spots]()
  
  init () {
    
  }
  
} // end class


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
