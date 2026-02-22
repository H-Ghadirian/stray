//
//  StrayApp.swift
//  Stray
//
//  Created by ghadirianh on 22.02.26.
//

import SwiftUI
import SwiftData

@main
struct StrayApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            RoutePoint.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            let fallbackConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            do {
                return try ModelContainer(for: schema, configurations: [fallbackConfiguration])
            } catch {
                fatalError("Could not create ModelContainer, including in-memory fallback: \(error)")
            }
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
