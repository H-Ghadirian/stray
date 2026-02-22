//
//  LocationTracker.swift
//  Stray
//
//  Created by Codex on 22.02.26.
//

import Combine
import CoreLocation
import Foundation

final class LocationTracker: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published private(set) var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published private(set) var latestLocation: CLLocation?

    var onRoutePoint: ((CLLocation) -> Void)?

    private let locationManager = CLLocationManager()
    private var lastRecordedLocation: CLLocation?

    private let minDistanceMeters: CLLocationDistance = 10
    private let minTimeInterval: TimeInterval = 5

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 5
        locationManager.activityType = .fitness
        authorizationStatus = locationManager.authorizationStatus
    }

    func start() {
        switch locationManager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.startUpdatingLocation()
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            break
        @unknown default:
            break
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        if authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways {
            manager.startUpdatingLocation()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        for location in locations where location.horizontalAccuracy >= 0 {
            latestLocation = location
            if shouldRecord(location: location) {
                lastRecordedLocation = location
                onRoutePoint?(location)
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location update failed: \(error.localizedDescription)")
    }

    private func shouldRecord(location: CLLocation) -> Bool {
        guard let lastRecordedLocation else { return true }

        let movedEnough = location.distance(from: lastRecordedLocation) >= minDistanceMeters
        let waitedEnough = location.timestamp.timeIntervalSince(lastRecordedLocation.timestamp) >= minTimeInterval
        return movedEnough || waitedEnough
    }
}
