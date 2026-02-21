//
//  ContentView.swift
//  Stray
//
//  Created by ghadirianh on 22.02.26.
//

import CoreLocation
import MapKit
import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var routePoints: [RoutePoint]

    @StateObject private var locationTracker = LocationTracker()
    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var centeredOnUser = false
    @State private var currentLatitudeDelta: CLLocationDegrees = 0.01

    var body: some View {
        ZStack(alignment: .top) {
            Map(position: $cameraPosition) {
                ForEach(routeSegments.indices, id: \.self) { index in
                    MapPolyline(coordinates: routeSegments[index])
                        .stroke(.blue, lineWidth: routeLineWidth)
                }

                if shouldShowDots {
                    ForEach(sortedRoutePoints) { point in
                        if let coordinate = point.coordinate {
                            Annotation("", coordinate: coordinate) {
                                Circle()
                                    .fill(Color.blue)
                                    .frame(width: routeDotSize, height: routeDotSize)
                                    .overlay {
                                        if routeDotBorderWidth > 0 {
                                            Circle().stroke(.white, lineWidth: routeDotBorderWidth)
                                        }
                                    }
                            }
                        }
                    }
                }

                if let latestCoordinate = locationTracker.latestLocation?.coordinate {
                    Annotation("You", coordinate: latestCoordinate) {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 12, height: 12)
                            .overlay(
                                Circle().stroke(.white, lineWidth: 2)
                            )
                    }
                }
            }
            .mapControls {
                MapCompass()
                MapUserLocationButton()
            }
            .onMapCameraChange { context in
                currentLatitudeDelta = context.region.span.latitudeDelta
            }
            .ignoresSafeArea()

            VStack(spacing: 8) {
                statusBanner

                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Button {
                            centerOnLatestLocation()
                        } label: {
                            Label("Center", systemImage: "location.fill")
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(.regularMaterial, in: Capsule())
                        }
                    }
                }
            }
            .padding()
        }
        .onAppear(perform: configureLocationTracking)
    }

    private var routeSegments: [[CLLocationCoordinate2D]] {
        guard !sortedRoutePoints.isEmpty else { return [] }

        var segments: [[CLLocationCoordinate2D]] = []
        var currentSegment: [CLLocationCoordinate2D] = []
        var previousState: (location: CLLocation, timestamp: Date)?

        for point in sortedRoutePoints {
            guard let coordinate = point.coordinate, let timestamp = point.timestamp else { continue }
            let currentLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)

            if let previousState {
                let timeGap = timestamp.timeIntervalSince(previousState.timestamp)
                let distanceGap = currentLocation.distance(from: previousState.location)

                if timeGap > 15 * 60 || distanceGap > 500 {
                    if currentSegment.count >= 2 {
                        segments.append(currentSegment)
                    }
                    currentSegment = []
                }
            }

            currentSegment.append(coordinate)
            previousState = (currentLocation, timestamp)
        }

        if currentSegment.count >= 2 {
            segments.append(currentSegment)
        }

        return segments
    }

    private var shouldShowDots: Bool {
        currentLatitudeDelta < 0.09
    }

    private var sortedRoutePoints: [RoutePoint] {
        routePoints.sorted {
            ($0.timestamp ?? .distantPast) < ($1.timestamp ?? .distantPast)
        }
    }

    private var routeDotSize: CGFloat {
        currentLatitudeDelta < 0.02 ? 7 : 5
    }

    private var routeDotBorderWidth: CGFloat {
        currentLatitudeDelta < 0.02 ? 1 : 0
    }

    private var routeLineWidth: CGFloat {
        currentLatitudeDelta > 0.09 ? 4.5 : 3
    }

    @ViewBuilder
    private var statusBanner: some View {
        switch locationTracker.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            Text("Tracking walk routes")
                .font(.footnote.weight(.semibold))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(.regularMaterial, in: Capsule())
        case .denied, .restricted:
            Text("Enable location in Settings to track your path")
                .font(.footnote.weight(.semibold))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(.regularMaterial, in: Capsule())
        case .notDetermined:
            Text("Requesting location permission...")
                .font(.footnote.weight(.semibold))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(.regularMaterial, in: Capsule())
        @unknown default:
            EmptyView()
        }
    }

    private func configureLocationTracking() {
        locationTracker.onRoutePoint = { location in
            let routePoint = RoutePoint(
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude,
                timestamp: location.timestamp
            )
            modelContext.insert(routePoint)
            try? modelContext.save()

            if !centeredOnUser {
                centerOn(coordinate: location.coordinate)
                centeredOnUser = true
            }
        }
        locationTracker.start()
    }

    private func centerOnLatestLocation() {
        if let coordinate = locationTracker.latestLocation?.coordinate {
            centerOn(coordinate: coordinate)
        } else if let coordinate = sortedRoutePoints.last(where: { $0.coordinate != nil })?.coordinate {
            centerOn(coordinate: coordinate)
        }
    }

    private func centerOn(coordinate: CLLocationCoordinate2D) {
        let region = MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )
        cameraPosition = .region(region)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: RoutePoint.self, inMemory: true)
}
