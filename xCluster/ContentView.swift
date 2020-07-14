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
  
    //@Binding var overlays: [MKPolyline]
    
    func makeNSView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
      
      //----------------------------------------------
      let annotation = MKPointAnnotation()
      annotation.title = "London"
      annotation.subtitle = "Capital of England"
      annotation.coordinate = CLLocationCoordinate2D(latitude: 51.5, longitude: 0.13)
      mapView.addAnnotation(annotation)
      
      
      
      
      //----------------------------------------------
        return mapView
    }

    func updateNSView(_ uiView: MKMapView, context: Context) {
      
      print("Map updated")

    }
  
  func makeCoordinator() -> Coordinator {
      Coordinator(self)
  }
  
  // https://www.hackingwithswift.com/books/ios-swiftui/communicating-with-a-mapkit-coordinator
  class Coordinator: NSObject, MKMapViewDelegate {
      var parent: MapView

      init(_ parent: MapView) {
          self.parent = parent
      }
    
    func mapViewDidChangeVisibleRegion(_ mapView: MKMapView) {
        //print(mapView.centerCoordinate)
    }
  } // end class
} // end struct

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
        MapView()
        .edgesIgnoringSafeArea(.all)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
      }
      .border(Color.black)
      .padding(.top, 0)
      .frame(minWidth: 1024, maxWidth: .infinity, minHeight: 800, maxHeight: .infinity)
      
      // MARK: - cluster selection and filtering.
      
      ClusterView(controller: controller, clusters: clusters)
        .environmentObject(controller)
      
      // MARK: - cluster list display.
      
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
      //.border(Color.green)
      VStack{
        Divider()
        .frame(maxHeight: 1)
        .padding(-5)
      }
      .frame(maxWidth: .infinity, maxHeight: 1)
    }
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
