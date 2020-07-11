//
//  ContentView.swift
//  xCluster
//
//  Created by Peter Bourget on 7/3/20.
//  Copyright © 2020 Peter Bourget. All rights reserved.
//

import SwiftUI
import CallParser

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
          ScrollView {
          VStack{
            SpotHeader()
            ForEach(controller.spots, id: \.self) { spot in
            SpotRow(spot: spot)
            }
//            ForEach(controller.spots, id: \.self) { spot in
//            HStack{
//              Text("\(spot.dxStation) | \(spot.frequency) | \(spot.spotter) | \(spot.dateTime) | \(spot.comment) | \(spot.grid)")
//              Spacer()
//            }
//            .frame(maxHeight: 15)
//            .padding(.leading, 5)
//            .border(Color.green)
//          }
        }.frame(minWidth: 0, maxWidth: .infinity, minHeight: 300, maxHeight: 300, alignment: .topLeading)
          //.border(Color.green)
          }
        }
        .border(Color.green)
        HStack{
          ScrollView {
          VStack{
          ForEach(controller.statusMessage, id: \.self) { message in
            HStack{
              Text(message)
              Spacer()
            }
            .frame(maxHeight: 15)
            .lineLimit(nil)
            .multilineTextAlignment(.leading)
          }
        }.frame(minWidth: 0, maxWidth: .infinity, minHeight: 300, maxHeight: 300, alignment: .topLeading)
          .border(Color.green)
          }
        }
        .border(Color.red)
      }
      .frame(maxWidth: .infinity, minHeight: 300, maxHeight: 300)
      .padding(.vertical,0)
      
    } // end outer vstack
      .frame(minWidth: 1024)
    
  }
} // end ContentView

// MARK: - Spot Header

struct SpotHeader: View {
   var body: some View {
    
    HStack(){
      Text("DX")
        .lineLimit(nil)
        .multilineTextAlignment(.leading)
        .frame(minWidth: 50)
      Text("Frequency")
        .lineLimit(nil)
        .multilineTextAlignment(.leading)
      .frame(minWidth: 70)
      Text("Spotter")
      .frame(minWidth: 50)
      .lineLimit(nil)
      .multilineTextAlignment(.leading)
      Text("Time")
        .lineLimit(nil)
        .multilineTextAlignment(.leading)
      .frame(minWidth: 50)
      Text("Comment")
        .lineLimit(nil)
        .multilineTextAlignment(.leading)
      .frame(minWidth: 200)
      Text("Grid")
        .lineLimit(nil)
        .multilineTextAlignment(.leading)
      .frame(minWidth: 50)
      //Spacer()
    }
  }
}

// MARK: - Spot Row

struct SpotRow: View {
  var spot: ClusterSpot
  
   var body: some View {
      HStack{
        Text(spot.dxStation)
          .multilineTextAlignment(.leading)
          .frame(minWidth: 75)
        Text(spot.frequency)
          .multilineTextAlignment(.leading)
        .frame(minWidth: 90)
        Text(spot.spotter)
          .multilineTextAlignment(.leading)
        .frame(minWidth: 75)
        Text(spot.dateTime)
          .multilineTextAlignment(.leading)
        .frame(minWidth: 50)
        Text(spot.comment)
          .multilineTextAlignment(.leading)
        .frame(minWidth: 200)
        Text(spot.grid)
          .multilineTextAlignment(.leading)
        .frame(minWidth: 50)
        Spacer()
      }
      .frame(maxHeight: 15)
      .padding(.leading, 5)
      .border(Color.green)
  }
}

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
