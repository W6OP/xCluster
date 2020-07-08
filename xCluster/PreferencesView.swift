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
  @State private var userName = "W6OP"
  @State private var password = "LetsFindSomeDXToday$56"
  @State private var showPreferences = false
  @ObservedObject var userSettings = UserSettings()
  
  var body: some View {
    VStack{
      HStack{
        Form {
          Section(header: Text("QRZ Credentials")) {
            HStack{
              Text("QRZ User Name")
              TextField("User Name", text: $userSettings.username)
            }
            HStack{
              Text("QRZ Password")
              Spacer()
                .frame(minWidth: 18, maxWidth: 18)
              SecureField("Password", text: $userSettings.password)
            }
            Button(action: {savePreferences(); self.presentationMode.wrappedValue.dismiss()}) {
              Text("Close")
            }
          }
        }
      }
      .frame(minWidth: 275,maxWidth: 275)
    }
    .padding(5)
  }
}

struct PreferencesView_Previews: PreviewProvider {
  static var previews: some View {
    PreferencesView()
  }
}

func savePreferences() {
  
}
