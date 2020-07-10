//
//  ContentView.swift
//  xCluster
//
//  Created by Peter Bourget on 7/3/20.
//  Copyright © 2020 Peter Bourget. All rights reserved.
//

import SwiftUI
import CallParser

//extension EnvironmentObject
//{
//  var safeToUse: Bool {
//    return (Mirror(reflecting: self).children.first(where: { $0.label == "_store"})?.value as? ObjectType) != nil
//  }
//}

struct ContentView: View {
  @ObservedObject var userSettings = UserSettings()
  @ObservedObject var controller: Controller
  var bands: [BandIdentifier] = bandData
  var clusters: [ClusterIdentifier] = clusterData
  // var spots
  // var maplines
  @State private var showPreferences = false
  
  var body: some View {
    VStack{
      
      // MARK: - band buttons.
      
      HStack{
        // show preferences
        Button(action: {self.showPreferences.toggle()}) {
          Text("Configure")
        }
        .padding(.top, 4)
        .sheet(isPresented: $showPreferences) {
         
          return PreferencesView()
        }
        
        BandView(bands: bands)
      }
      .padding(.top, -2).padding(.bottom, 2)
      .frame(maxWidth: .infinity)
      .background(Color.blue)
      .opacity(0.50)
      
      // MARK: - mapping container.
      
      HStack{
        MapView().edgesIgnoringSafeArea(.vertical)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
      }
      .border(Color.black)
      .padding(.top, 0)
      .frame(minWidth: 1024, maxWidth: .infinity, minHeight: 800, maxHeight: .infinity)
      
      // MARK: - cluster selection and filtering.
      
      ClusterView(controller: controller, clusters: clusters)
        .environmentObject(controller)
      
      // MARK: - cluster display.
      
      HStack{
        HStack{
          Text("Data Grid")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        HStack{
          ScrollView{
          Text(controller.statusMessage)
            .frame(maxWidth: .infinity, maxHeight: 290)
          }
        }
        
      }
      .frame(maxWidth: .infinity, minHeight: 300, maxHeight: 300)
      .padding(.vertical,0)
      
    } // end outer vstack
    
  }
} // end ContentView

// MARK: -  List of band buttons

struct BandView: View {
  var bands: [BandIdentifier]
  
  var body: some View {
    
    ForEach(bands, id: \.self) { item in
      Button(action: {selectBand(bandId: item.id)}) {
        Text(item.band)
      }.padding(.top, 5)
    }
  }
}

// MARK: - Picker of Cluster Names

struct ClusterView: View {

  var controller: Controller
  @State var prefixDataList = [Hit]()
  @State private var selectedCluster = "Select DX Spider Node"
  @State private var callFilter = ""
  var clusters: [ClusterIdentifier]
  
  var body: some View {
    HStack{
      HStack{
        Picker(selection: $selectedCluster, label: Text("")) {
            ForEach(clusters) { cluster in
                Text("\(cluster.name):\(cluster.address):\(cluster.port)").tag(cluster.name)
            }
        }.frame(minWidth: 400, maxWidth: 400)
        Button(action: {self.controller.connect(clusterName: "\(self.selectedCluster)")}) {
          Text("Connect")
        }
        .disabled(controller.haveSessionKey == false)
      }
      .padding(.trailing)
      
      Spacer()
      
      HStack{
        TextField("Call Filter", text: $callFilter)
          .textFieldStyle(RoundedBorderTextFieldStyle())
          .frame(maxWidth: 100)
        Button(action: {showDX(count: 20)}) {
          Text("show dx/20")
        }
        Button(action: {showDX(count: 50)}) {
            Text("show dx/50")
        }
      }
      .frame(minWidth: 500)
      .padding(.leading)
      .padding(.vertical,2)
      
      Spacer()
    }
    .background(Color.blue)
    .opacity(0.50)
    .frame(maxWidth: .infinity)
  }
}

// MARK: - Content Preview

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    //ContentView(bands: bandData, clusters: clusterData)
    ContentView(controller: Controller())
  }
}

func configure() {
  
}

func selectBand(bandId: Int) {
  
}

func showDX(count: Int) {
  
}

func filterDx(filter: Int) {
  
}

// disConnect()
//connect(clusterAddress: cluster.clusterAddress, clusterPort: cluster.clusterPort)
func connect(clusterName: String) {
  
}
