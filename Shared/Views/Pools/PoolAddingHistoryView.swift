//
//  PoolAddingHistoryView.swift
//  PoolHealth
//
//  Created by user on 05/01/2025.
//

import SwiftUI

struct PoolAddingHistoryView: View {
    var id: String
    @ObservedObject var manager: PoolManager
    var body: some View {
        PoolAddingHistoryDumbView(chemicals: manager.chemicals).onAppear{
            Task{
                await manager.loadChemicals(poolID: id)
            }
        }.navigationBarTitle("Adding chemicals").refreshable {
            Task{
                await manager.loadChemicals(poolID: id)
            }
        }
    }
}

#Preview {
    NavigationStack {
        PoolAddingHistoryView(id: UUID().uuidString, manager: PoolManager())
    }
}
