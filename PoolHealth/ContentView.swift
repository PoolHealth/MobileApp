//
//  ContentView.swift
//  PoolHealth
//
//  Created by user on 03/01/2025.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        UserAreaUIView(authManager: AuthManager.shared)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
}
