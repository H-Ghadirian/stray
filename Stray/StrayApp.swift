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

        let cloudConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .automatic
        )

        do {
            return try ModelContainer(for: schema, configurations: [cloudConfiguration])
        } catch {
            print("Cloud-backed container unavailable, falling back to local store: \(error)")
            let localConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            do {
                return try ModelContainer(for: schema, configurations: [localConfiguration])
            } catch {
                let inMemoryConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
                do {
                    return try ModelContainer(for: schema, configurations: [inMemoryConfiguration])
                } catch {
                    fatalError("Could not create ModelContainer: \(error)")
                }
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
