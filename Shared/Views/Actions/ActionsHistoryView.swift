//
//  ActionsHistoryView.swift
//  PoolHealth
//
//  Created by user on 20/01/2025.
//

import SwiftUI

struct ActionsHistoryView: View {
    var poolID: String
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @ObservedObject var manager: PoolManager
    var body: some View {
        ActionsHistoryDumbView(actions: manager.actions).onAppear{
            Task{
                await manager.loadActions(poolID: poolID)
            }
        }.navigationBarTitle("Actions").refreshable {
            Task{
                await manager.loadActions(poolID: poolID)
            }
        }
    }
}

#Preview {
    ActionsHistoryView(poolID: UUID().uuidString, manager: PoolManager())
}
