//
//  Spot Processor.swift
//  xCluster
//
//  Created by Peter Bourget on 7/8/20.
//  Copyright © 2020 Peter Bourget. All rights reserved.
//

// Take a raw spot and break it into its component parts

import Cocoa

class SpotProcessor {
    
     init() {
        //super.init()
        
    }
    
    //      12 chars
    // DX de LY3AB:     1887.0  LY2RJ        cq cq cq                       1743Z KO25
    func processRawSpot(rawSpot: String) throws -> ClusterSpot  {
        
        //let clusterSpot = ClusterSpot()
      var spot = ClusterSpot(id: 0, dxStation: "", frequency: "", spotter: "", dateTime: "",comment: "",grid: "")
        
        if rawSpot.count < 75 {
            print("\(rawSpot.count) -- \(rawSpot)")
            throw SpotError.spotError("processRawSpot: spot length too short")
        }
       
        let spotter = rawSpot.components(separatedBy: ":")
        // replacing -# for AE5E - don't know why he does that "W6OP-#" and "W6OP-2"
        spot.spotter =  convertStringSliceToString(spotter[0].components(separatedBy: " ")[2])   //.replacingOccurrences(of: "-#", with: "")
        if spot.spotter.contains("-") {
          spot.spotter = String(spot.spotter.prefix(spot.spotter.count - 2))
        }
        
        var startIndex = rawSpot.index(rawSpot.startIndex, offsetBy: 16)
        var endIndex = rawSpot.index(startIndex, offsetBy: 9)
        let frequency = convertStringSliceToString(String(rawSpot[startIndex..<endIndex])).condenseWhitespace()
        guard Float(frequency) != nil else {
            //print(frequency)
            throw SpotError.spotError("processRawSpot: unable to parse frequency")
        }
        spot.frequency = convertFrequencyToDecimalString(frequency:frequency)
        
        startIndex = rawSpot.index(rawSpot.startIndex, offsetBy: 26)
        endIndex = rawSpot.index(startIndex, offsetBy: 11)
        spot.dxStation = convertStringSliceToString(String(rawSpot[startIndex..<endIndex]))
        
        startIndex = rawSpot.index(rawSpot.startIndex, offsetBy: 39)
        endIndex = rawSpot.index(startIndex, offsetBy: 30)
        spot.comment = convertStringSliceToString(String(rawSpot[startIndex..<endIndex]))
        
        startIndex = rawSpot.index(rawSpot.startIndex, offsetBy: 70)
        endIndex = rawSpot.index(startIndex, offsetBy: 5)
        // clean of junk on end so it displays correctly when no grid supplied
        spot.dateTime = convertStringSliceToString(String(rawSpot[startIndex..<endIndex])).condenseWhitespace()
        
        endIndex = rawSpot.endIndex
        startIndex = rawSpot.index(rawSpot.startIndex, offsetBy: 75)
        
        // clean of junk on end so it displays correctly
        spot.grid = convertStringSliceToString(String(rawSpot[startIndex..<endIndex])).condenseWhitespace()
        // remove /a/a at end
        spot.grid = spot.grid.components(separatedBy: CharacterSet.alphanumerics.inverted)
            .joined()

        return spot
    }
    
    // "24048940.0  GB3PKT      24-Feb-2019 2340Z  <tr>S9+ !!                   <G4BAO>\r\n"
    // 432174.0  DH9OK       24-Feb-2019 2035Z  JO01FQ<TR>JO51AQ 660km       <G3YDY>
    // 1840.0  UA3LNM      24-Feb-2019 2036Z  FT8,CLG HS1                 <JA3SWL>
    /**
     Process a telnet packet from a show/dx command.
     - parameters:
     - rawSpot: the string received via telnet.
     - returns:
     */
    func processRawShowDxSpot(rawSpot: String) throws ->  ClusterSpots {
        
        let spot = ClusterSpots(dx: "", frequency: "", spotter: "", comment: "",datetime: "",grid: "")

        if rawSpot.count < 65 {
            print("\(rawSpot.count) -- \(rawSpot)")
            throw SpotError.spotError("processRawShowDxSpot: spot length too short")
        }
        
        // grab the frequency off the front some we can get exact lengths
        let beginning = rawSpot.components(separatedBy: " ").first
        var startIndex = rawSpot.index(rawSpot.startIndex, offsetBy: beginning!.count + 1)
        var endIndex = rawSpot.endIndex
        let balance = convertStringSliceToString(String(rawSpot[startIndex..<endIndex]).trimmingCharacters(in: .whitespaces))

        let frequency = convertStringSliceToString(beginning!).condenseWhitespace()
        // first see if the first chunk is numeric (frequency) otherwise it is a status message, probably all spots
        // have arrived
        guard Float(frequency) != nil else {
            print(frequency)
            throw SpotError.spotError("processRawShowDxSpot: unable to parse frequency")
        }
        spot.frequency = convertFrequencyToDecimalString(frequency:frequency)

        startIndex = balance.startIndex
        endIndex = balance.index(startIndex, offsetBy: 12)
        spot.dx = convertStringSliceToString(String(balance[startIndex..<endIndex]))
       
        startIndex = balance.index(balance.startIndex, offsetBy: 13)
        endIndex = balance.index(startIndex, offsetBy: 17)
        spot.datetime = String(balance[startIndex..<endIndex])
        
        startIndex = balance.index(balance.startIndex, offsetBy: 30)
        endIndex = balance.index(startIndex, offsetBy: 30)
        spot.comment = convertStringSliceToString(String(balance[startIndex..<endIndex]))

        // clean of junk on end so it displays correctly when no grid supplied
        startIndex = balance.index(rawSpot.startIndex, offsetBy: 60)
        endIndex = balance.endIndex
        // clean of junk on end so it displays correctly when no grid supplied
        spot.spotter = convertStringSliceToString(String(balance[startIndex..<endIndex])).condenseWhitespace()
        spot.spotter = spot.spotter.replacingOccurrences(of: "<", with: "").replacingOccurrences(of: ">", with: "")
        
        return spot
    }
    
    /**
     Read handler.
     - parameters:
     - s: Initialize a new string instance from a slice of a string.
     Otherwise the reference to the string will never go away.
     */
    func convertStringSliceToString(_ s: String) -> String {
        return s.trimmingCharacters(in: .whitespaces)
    }
    
    /**
     Convert the frequency (10136000) to a string with a decimal place (10136.000)
     Use an extension to String to format frequency correctly. This is used to
     display the frequency formatted in the tableview.
     */
    func convertFrequencyToDecimalString (frequency: String) -> String {
        
        var converted: String
       
        var components = frequency.trimmingCharacters(in: .whitespaces).components(separatedBy: ".")
        let frequencyString = components[0]
        
        if components.count == 1 {
            components.append("0")
        }
        
        if components[1] == "" {
            components[1] = "0"
        }
        
        var startIndex = frequencyString.startIndex
        var endIndex = frequencyString.endIndex
        
        switch frequencyString.count {
        case 8: // 24048940.0 - 2404.894.00
            startIndex = frequencyString.startIndex
            endIndex = frequencyString.index(startIndex, offsetBy: 4)
            let start = frequencyString[startIndex..<endIndex]
            startIndex = frequencyString.index(frequencyString.startIndex, offsetBy: 4)
            endIndex = frequencyString.index(startIndex, offsetBy: 3)
            let end = frequencyString[startIndex..<endIndex]
            converted = ("\(start).\(end)")
        case 7: // 1296.789.000 - "2320905."
            startIndex = frequencyString.startIndex
            endIndex = frequencyString.index(startIndex, offsetBy: 4)
            let start = frequencyString[startIndex..<endIndex]
            startIndex = frequencyString.index(frequencyString.startIndex, offsetBy: 4)
            endIndex = frequencyString.endIndex
            let end = frequencyString[startIndex..<endIndex]
            converted = ("\(start).\(end)")
        case 6: //144.234.0 432174.0
            startIndex = frequencyString.startIndex
            endIndex = frequencyString.index(startIndex, offsetBy: 3)
            let start = frequencyString[startIndex..<endIndex]
            startIndex = frequencyString.index(frequencyString.startIndex, offsetBy: 3)
            endIndex = frequencyString.endIndex
            let end = frequencyString[startIndex..<endIndex]
            converted = ("\(start).\(end)")
        case 5: // 10.113
            startIndex = frequencyString.startIndex
            endIndex = frequencyString.index(startIndex, offsetBy: 2)
            let start = frequencyString[startIndex..<endIndex]
            startIndex = frequencyString.index(frequencyString.startIndex, offsetBy: 2)
            endIndex = frequencyString.endIndex
            let end = frequencyString[startIndex..<endIndex]
            converted = ("\(start).\(end)")
        case 4: // 3.563.0
            startIndex = frequencyString.startIndex
            endIndex = frequencyString.index(startIndex, offsetBy: 1)
            let start = frequencyString[startIndex..<endIndex]
            startIndex = frequencyString.index(frequencyString.startIndex, offsetBy: 1)
            endIndex = frequencyString.endIndex
            let end = frequencyString[startIndex..<endIndex]
            converted = ("\(start).\(end)")
        default:
            return frequency
        }
        
        if components[1] != "0" {
            converted += (".\(components[1])")
        }
        
        return converted
    }
    
} // end class

//send("set/ve7cc")
// CC11^14197.0^R7DN^27-Feb-2019^1628Z^59+9^PI3CQ^179^139^EA7URM-5^30^16^27^14^^^Eur-Russia-UA^Netherlands-PA^^\r\n
// DX de F4FGC:     14074.0  K7QXG        FT8 Tnx                        1630Z\u{07}\u{07}\r\n
// CC11^14173.0^AA3B^27-Feb-2019^1625Z^^IU7EKB^226^85^OH8X-12^8^5^28^15^^^DC-K^Italy-I^FN20^
// 14197.0  R7DN        27-Feb-2019 1628Z  59+9                         <PI3CQ>
