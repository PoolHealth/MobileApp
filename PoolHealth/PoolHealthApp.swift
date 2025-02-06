//
//  PoolHealthApp.swift
//  PoolHealth
//
//  Created by user on 03/01/2025.
//

import SwiftUI
import SwiftData

@main
struct PoolHealthApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            NavigationStack{
                ContentView()
            }
        }
        .modelContainer(sharedModelContainer)
    }
}
