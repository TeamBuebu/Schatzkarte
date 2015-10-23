//
//  Position.swift
//  Schatzkarte
//
//  Created by Raphael Bühlmann on 23.10.15.
//  Copyright © 2015 Toni Suter. All rights reserved.
//

import Foundation

class Position: NSObject, NSCoding {
    
    var lon: Double
    var lat: Double
    
    init(lon: Double, lat: Double) {
        self.lon = lon
        self.lat = lat
    }
    
    required init(coder decoder: NSCoder) {
        self.lon = (decoder.decodeObjectForKey("lon") as! Double)
        self.lat = (decoder.decodeObjectForKey("lat") as! Double)
    }
    
    func getJsonLon() -> Int  {
        
        return self.getJsonCoordinate(self.lon)
    }
    
    func getJsonLat() -> Int {
        
        return self.getJsonCoordinate(self.lat)
    }
    
    func getJsonCoordinate(value: Double) -> Int {
        
        return Int(value * pow(10, 6))
    }
    
    func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeObject(self.lon, forKey: "lon")
        aCoder.encodeObject(self.lat, forKey: "lat")
    }
}
