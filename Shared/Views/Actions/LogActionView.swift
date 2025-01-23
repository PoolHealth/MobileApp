//
//  LogActionView.swift
//  PoolHealth
//
//  Created by user on 20/01/2025.
//

import SwiftUI

struct LogActionView: View {
    var poolID: String
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @ObservedObject var manager: PoolManager
    @State var net: Bool = false
    @State var brush: Bool = false
    @State var vacuum: Bool = false
    @State var backwash: Bool = false
    @State var scumLine: Bool = false
    @State var pumpBasketClean: Bool = false
    @State var skimmerBasketClean: Bool = false
    @State var actions: Set<ActionType> = []
    var body: some View {
        Section{
            ActionToggleView(actionType: .net, actions: $actions)
            ActionToggleView(actionType: .backwash, actions: $actions)
            ActionToggleView(actionType: .brush, actions: $actions)
            ActionToggleView(actionType: .pumpBasketClean, actions: $actions)
            ActionToggleView(actionType: .scumLine, actions: $actions)
            ActionToggleView(actionType: .skimmerBasketClean, actions: $actions)
            ActionToggleView(actionType: .vacuum, actions: $actions)
            Button("Log") {
                Task {
                    await manager.logActions(poolID: poolID, actions: Array(actions))
                    
                    if manager.error == nil {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }.navigationBarTitle("Log actions").padding(.horizontal, 20)
    }
}

#Preview {
    LogActionView(poolID: UUID().uuidString, manager: PoolManager())
}
