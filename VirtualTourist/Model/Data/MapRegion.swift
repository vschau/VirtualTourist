//
//  MapRegion.swift
//  VirtualTourist
//
//  Created by Vanessa on 5/25/20.
//  Copyright © 2020 Vanessa. All rights reserved.
//

import Foundation
import MapKit

struct MapRegion: Codable {
    let latitude: Double
    let longitude: Double
    let latSpan: Double
    let lonSpan: Double
}

extension MapRegion {
    var region: MKCoordinateRegion {
        return MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
                                    span: MKCoordinateSpan(latitudeDelta: latSpan, longitudeDelta: lonSpan))
    }
}
