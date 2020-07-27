//
//  ContentView.swift
//  xCluster
//
//  Created by Peter Bourget on 7/3/20.
//  Copyright © 2020 Peter Bourget. All rights reserved.
//

import SwiftUI
import CallParser
import MapKit

// MARK: - Map View
struct MapView: NSViewRepresentable {
  typealias MapViewType = NSViewType
  var overlays: [MKPolyline]
  
  func makeNSView(context: Context) -> MKMapView {
    let mapView = MKMapView()
    mapView.delegate = context.coordinator
    
    return mapView
  }
  
  func updateNSView(_ uiView: MKMapView, context: Context) {
    updateOverlays(from: uiView)
  }
  
  // https://medium.com/@mauvazquez/decoding-a-polyline-and-drawing-it-with-swiftui-mapkit-611952bd0ecb
  public func updateOverlays(from mapView: MKMapView) {
    mapView.removeOverlays(mapView.overlays)
    
    for polyline in overlays {
      mapView.addOverlay(polyline)
    }
    
    //    setMapZoomArea(map: mapView, polyline: polyline, edgeInsets: mapZoomEdgeInsets, animated: true)
  }
  
  func makeCoordinator() -> Coordinator {
    Coordinator(self)
  }
} // end struct

// https://www.hackingwithswift.com/books/ios-swiftui/communicating-with-a-mapkit-coordinator
class Coordinator: NSObject, MKMapViewDelegate {
  var parent: MapView
  
  init(_ parent: MapView) {
    self.parent = parent
  }
  
  func mapViewDidChangeVisibleRegion(_ mapView: MKMapView) {
    //print(mapView.centerCoordinate)
    
  }
  
  func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
    let renderer = MKPolylineRenderer(overlay: overlay)
    renderer.strokeColor = .blue
    renderer.lineWidth = 1.0
    return renderer
  }
  
} // end class


// MARK: - Content View ------------------------------------------------------------.

struct ContentView: View {
  @ObservedObject var userSettings = UserSettings()
  @EnvironmentObject var controller: Controller
  var bands: [BandIdentifier] = bandData
  var clusters: [ClusterIdentifier] = clusterData
  @State private var showPreferences = false
  
  var body: some View {
    VStack{
      // MARK: - band buttons.
      
      HStack{
        // show preferences
        Button(action: {self.showPreferences.toggle()}) {
          Text("Settings")
        }
        .padding(.top, 4)
        .sheet(isPresented: $showPreferences) {
          
          return PreferencesView()
        }
        
        BandViewToggle(bands: bands)
      }
      .padding(.top, -2).padding(.bottom, 2)
      .frame(maxWidth: .infinity, minHeight: 30, maxHeight: 30)
      .background(Color.blue)
      .opacity(0.50)
      
      // MARK: - mapping container.
      
      HStack{
        MapView(overlays: controller.overlays)
          .edgesIgnoringSafeArea(.all)
          .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
      }
      .border(Color.black)
      .padding(.top, 0)
      .frame(minWidth: 1024, maxWidth: .infinity, minHeight: 800, maxHeight: .infinity)
      
      // MARK: - Cluster selection and filtering.
      
      ClusterView(clusters: clusters)
      
      // MARK: - Spot list display.
      
      HStack{
        HStack{
          ScrollView {
            VStack{
              SpotHeader()
              Divider()
                .frame(maxHeight: 1)
                .padding(-5)
              ForEach(controller.spots, id: \.self) { spot in
                SpotRow(spot: spot)
              }
            }
            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 300, maxHeight: 300, alignment: .topLeading)
            .background(Color(red: 209 / 255, green: 215 / 255, blue: 226 / 255))
          }
        }
        .border(Color.gray)
        
        // MARK: - Status message display.
       
        HStack{
          ScrollView {
            VStack{
              ForEach(controller.statusMessage, id: \.self) { message in
                HStack{
                  Text(message)
                    .padding(.leading, 2)
                    .foregroundColor(Color.black)
                  Spacer()
                }
                .frame(maxHeight: 15)
                .multilineTextAlignment(.leading)
              }
            }
            .frame(minWidth: 300, maxWidth: .infinity, minHeight: 300, maxHeight: 300, alignment: .topLeading)
            .background(Color(red: 209 / 255, green: 215 / 255, blue: 226 / 255))
          }
        }
        .border(Color.gray)
      }
      .frame(maxWidth: .infinity, minHeight: 300, maxHeight: 300)
      .padding(.vertical,0)
    } // end outer vstack
      .frame(minWidth: 1300)
    
  }
} // end ContentView

// MARK: - Spot Header

struct SpotHeader: View {
  var body: some View {
    
    HStack{
      Text("DX")
        .frame(minWidth: 75)
      Text("Frequency")
        .frame(minWidth: 90)
      Text("Spotter")
        .frame(minWidth: 75)
      Text("Time")
        .frame(minWidth: 60)
      Text("Comment")
        .padding(.leading, 20)
        .frame(minWidth: 250, alignment: .leading)
      Text("Grid")
        .frame(minWidth: 50)
      Spacer()
    }
    .foregroundColor(Color.red)
    .font(.system(size: 14))
    .padding(0)
  }
}

// MARK: - Spot Row

struct SpotRow: View {
  var spot: ClusterSpot
  
  var body: some View {
    VStack{
      HStack{
        Text(spot.dxStation)
          .frame(minWidth: 75,alignment: .leading)
          .padding(.leading, 5)
        Text(spot.frequency)
          .frame(minWidth: 90,alignment: .leading)
        Text(spot.spotter)
          .frame(minWidth: 75,alignment: .leading)
        Text(spot.dateTime)
          .frame(minWidth: 60,alignment: .leading)
        Text(spot.comment)
          .frame(minWidth: 250,alignment: .leading)
          .padding(.leading, 5)
          .padding(.trailing, 5)
        Text(spot.grid)
          .frame(minWidth: 50,alignment: .leading)
        Spacer()
      }
      .frame(maxWidth: .infinity, maxHeight: 15)
      .padding(.leading, 5)
      .padding(.top, -5)
      .padding(.bottom, -5)
      
      VStack{
        Divider()
          .frame(maxHeight: 1)
          .padding(-5)
      }
      .frame(maxWidth: .infinity, maxHeight: 1)
    }
  }
}

// MARK: -  List of band toggles

// https://stackoverflow.com/questions/60994255/swiftui-get-toggle-state-from-items-inside-a-list
struct BandViewToggle: View {
  @EnvironmentObject var controller: Controller
  @State var bands: [BandIdentifier]
  
  var body: some View {
    HStack{
      Spacer()
      ForEach(bands.indices) { item in
        Toggle(self.bands[item].band, isOn: self.$bands[item].isSelected.didSet { (state) in
          self.controller.filter = (self.bands[item].id, state )
        })
          .tag(self.bands[item].id)
          .padding(.top, 5)
          .toggleStyle(SwitchToggleStyle())
        //.background(isSelected ? Color.orange : Color.purple)
        Divider()
      }
      Spacer()
    }
  }
}

// MARK: - Picker of Cluster Names

struct ClusterView: View {
  
  @EnvironmentObject var controller: Controller
  //@State private var prefixDataList = [Hit]()
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
          // onReceive is fired when anything on the GUI is changed.
          // if a spot comes in or a line on map drawn it is fired
          .onReceive([selectedCluster].publisher.first()) { value in
            if self.selectedCluster != "Select DX Spider Node" {
              if self.controller.connectedCluster != value {
                self.controller.connectedCluster = value
              }
              print("value: \(value)")
            }
        }
      }
      .padding(.trailing)
      
      Spacer()
      
      HStack{
        TextField("Call Filter", text: $callFilter)
          .textFieldStyle(RoundedBorderTextFieldStyle())
          .frame(maxWidth: 100)
        Button(action: {self.controller.clusterCommand = (20, "show dx/20")}) {
          Text("show dx/20")
        }
        Button(action: {self.controller.clusterCommand = (50, "show dx/50")}) {
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
    ContentView().environmentObject(Controller())
  }
}
