//
//  MapModel.swift
//  VirtualTourist
//
//  Created by Vanessa on 5/25/20.
//  Copyright © 2020 Vanessa. All rights reserved.
//

import Foundation
import MapKit

class MapModel {
    private let mapKey = "Map Defaults"
    static let instance = MapModel()
    
    func loadSavedMapRegion(latitude: Double = 39.9042, longitude: Double = 116.4074, span: Double = 0.3) -> MKCoordinateRegion {
        if let data = UserDefaults.standard.data(forKey: mapKey),
            let mapRegion = try? JSONDecoder().decode(MapRegion.self, from: data) {
            return mapRegion.region
        }
        let center = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        let coordSpan = MKCoordinateSpan(latitudeDelta: span, longitudeDelta: span)
        return MKCoordinateRegion(center: center, span: coordSpan)
    }
    
    func saveMapRegion(region: MKCoordinateRegion) {
        let mapRegion = MapRegion(latitude: region.center.latitude, longitude: region.center.longitude, latSpan: region.span.latitudeDelta, lonSpan: region.span.longitudeDelta)
        if let encoded = try? JSONEncoder().encode(mapRegion) {
            UserDefaults.standard.set(encoded, forKey: mapKey)
        }
    }
}

