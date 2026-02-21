//
//  RoutePoint.swift
//  Stray
//
//  Created by Codex on 22.02.26.
//

import CoreLocation
import Foundation
import SwiftData

@Model
final class RoutePoint {
    var latitude: Double?
    var longitude: Double?
    var timestamp: Date?

    init(latitude: Double, longitude: Double, timestamp: Date = .now) {
        self.latitude = latitude
        self.longitude = longitude
        self.timestamp = timestamp
    }
}

extension RoutePoint {
    var coordinate: CLLocationCoordinate2D? {
        guard let latitude, let longitude else { return nil }
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}
