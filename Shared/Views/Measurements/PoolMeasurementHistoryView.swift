//
//  PoolMeasurementHistoryView.swift
//  PoolHealth
//
//  Created by user on 05/01/2025.
//

import SwiftUI

struct PoolMeasurementHistoryView: View {
    var id: String
    @ObservedObject var manager: MeasureManager
    var body: some View {
        List {
            PoolMeasurementHistoryDumbView(measurements: manager.measurements){ createdAt in
                Task {
                    await manager.deleteMeasurement(poolID: id, createdAt: createdAt)
                }
                
            }
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
    PoolMeasurementHistoryView(id: UUID().uuidString, manager: MeasureManager())
}
