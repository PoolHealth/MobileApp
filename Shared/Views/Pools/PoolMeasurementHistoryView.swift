//
//  PoolMeasurementHistoryView.swift
//  PoolHealth
//
//  Created by user on 05/01/2025.
//

import SwiftUI

struct PoolMeasurementHistoryView: View {
    var id: String
    @ObservedObject var manager: PoolManager
    var body: some View {
        List {
            PoolMeasurementHistoryDumbView(measurements: manager.measurements)
        }.onAppear{
            Task{
                await manager.loadMesurements(poolID: id)
            }
        }.navigationBarTitle("Measurements").refreshable {
            Task{
                await manager.loadMesurements(poolID: id)
            }
        }
    }
}

#Preview {
    PoolMeasurementHistoryView(id: UUID().uuidString, manager: PoolManager())
}
