//
//  ClusterDisplayView.swift
//  xCluster
//
//  Created by Peter Bourget on 7/27/20.
//  Copyright © 2020 Peter Bourget. All rights reserved.
//

import SwiftUI

struct ClusterDisplayView: View {
  @EnvironmentObject var controller: Controller
  
    var body: some View {
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
                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 30, maxHeight: .infinity, alignment: .topLeading) // minHeight: 300, maxHeight: 300,
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
                .frame(minWidth: 300, maxWidth: .infinity, minHeight: 30, maxHeight: .infinity, alignment: .topLeading) // , minHeight: 300, maxHeight: 300
              .background(Color(red: 209 / 255, green: 215 / 255, blue: 226 / 255))
            }
          }
          .border(Color.gray)
        }
        .frame(maxWidth: .infinity, minHeight: 200, maxHeight: 200)// , maxHeight: 300
        .padding(.vertical,0)
    }
}

struct ClusterDisplayView_Previews: PreviewProvider {
    static var previews: some View {
      ClusterDisplayView()
        .environmentObject(Controller())
    }
}
