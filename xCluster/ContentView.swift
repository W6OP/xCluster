//
//  ContentView.swift
//  xCluster
//
//  Created by Peter Bourget on 7/3/20.
//  Copyright © 2020 Peter Bourget. All rights reserved.
//

import SwiftUI

struct ContentView: View {
  var bands: [BandIdentifier] = bandData
  var clusters: [ClusterIdentifier] = clusterData
  @State private var selectedCluster = "Select DX Spider Node"
  @State private var callFilter = ""
  
  var body: some View {
    VStack{
      
      HStack{
        BandView(bands: bands)
      }
      .frame(maxWidth: .infinity)
      .background(Color.blue)
      .opacity(0.50)
      
      
      // map view
      HStack{
        Text("Map View")
      }
      .frame(minWidth: 1024, maxWidth: 1024, minHeight: 800, maxHeight: 800)
      .border(Color.black)
      
      // cluster selection and filtering
      HStack{
        HStack{
          Picker(selection: $selectedCluster, label: Text("Select DX Spider Node")) {
              ForEach(clusters) { cluster in
                  Text("\(cluster.name):\(cluster.address):\(cluster.port)").tag(cluster.name)
              }
          }.frame(minWidth: 400, maxWidth: 400)
        }
        .padding(.trailing)
        //.frame(maxWidth: 300)
        
        Spacer()
        //  .frame(maxWidth: 100)
        
        HStack{
          TextField("Call Sign", text: $callFilter)
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
      }
      .frame(maxWidth: .infinity, maxHeight: 30)
      .background(Color.blue)
      .opacity(0.50)
      
      // cluster display
      HStack{
        HStack{
          Text("Data Grid")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        HStack{
          Text("Cluster Commands")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        
      }
      .frame(maxWidth: .infinity, minHeight: 300, maxHeight: 300)
      .background(Color.blue)
      .opacity(0.50)
      
    } // end outer vstack
  }
} // end ContentView

// List of band buttons
struct BandView: View {
  var bands: [BandIdentifier]
  
  var body: some View {
    ForEach(bands, id: \.self) { item in
      Button(action: {selectBand(bandId: item.id)}) {
        Text(item.band)
      }
    }
  }
}

func selectBand(bandId: Int) {
  
}

func showDX(count: Int) {
  
}

func filterDx(filter: Int) {
  
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView(bands: bandData, clusters: clusterData)
  }
}
