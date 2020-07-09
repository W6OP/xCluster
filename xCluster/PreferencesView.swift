//
//  PreferencesView.swift
//  xCluster
//
//  Created by Peter Bourget on 7/8/20.
//  Copyright © 2020 Peter Bourget. All rights reserved.
//

import SwiftUI

struct PreferencesView: View {
  @Environment(\.presentationMode) var presentationMode
  @ObservedObject var userSettings = UserSettings()
  @State private var callsign = ""
  @State private var userName = ""
  @State private var password = ""
  @State private var fullname = ""
  @State private var location = ""
  @State private var grid = ""
  @State private var showPreferences = false
  
  var body: some View {
    VStack{
      HStack{
        Form {
          Section(header: Text("General Information")) {
            HStack{
              Text("Call Sign")
              Spacer()
              TextField("Call Sign", text: $userSettings.callsign)
              .textFieldStyle(RoundedBorderTextFieldStyle())
              .frame(minWidth: 230, maxWidth: 230)
            }
            HStack{
              Text("Full Name")
              TextField("First and Last Name", text: $userSettings.fullname)
                .textFieldStyle(RoundedBorderTextFieldStyle())
              .frame(minWidth: 230, maxWidth: 230)
            }
            HStack{
              Text("Location")
              Spacer()
              TextField("City, State", text: $userSettings.location)
                .textFieldStyle(RoundedBorderTextFieldStyle())
              .frame(minWidth: 230, maxWidth: 230)
            }
            HStack{
              Text("Grid")
              Spacer()
              TextField("Grid", text: $userSettings.grid)
                .textFieldStyle(RoundedBorderTextFieldStyle())
              .frame(minWidth: 230, maxWidth: 230)
            }
          }
        }
      }
      
      HStack{
        Spacer()
      }
      
      HStack{
        Form {
          Section(header: Text("QRZ Credentials")) {
            HStack{
              Text("QRZ User Name")
              TextField("User Name", text: $userSettings.username)
              .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            HStack{
              Text("QRZ Password")
              Spacer()
                .frame(minWidth: 18, maxWidth: 18)
              SecureField("Password", text: $userSettings.password)
              .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            Button(action: {self.presentationMode.wrappedValue.dismiss()}) {
              Text("Close")
            }
          }
        }
      }
      //.frame(minWidth: 275,maxWidth: 275)
    }
      .frame(minWidth: 300,maxWidth: 300)
    .padding(5)
  }
}

struct PreferencesView_Previews: PreviewProvider {
  static var previews: some View {
    PreferencesView()
  }
}

