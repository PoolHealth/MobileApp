//
//  PoolView.swift
//  PoolHealth
//
//  Created by user on 05/01/2025.
//

import SwiftUI

struct PoolView: View {
    var id: String
    var name: String
    var volume: Double
    var measurementDate: Date = Date()
    @ObservedObject var manager: PoolManager
    var body: some View {
        VStack  {
            Text("\(name), volume \(volume, format: .number.precision(.fractionLength(0))) liters").bold()
            Spacer()
            if manager.lastMeasurmentLoading {
                ProgressView()
                Spacer()
            } else if let last = manager.poolDetails {
                HStack{
                    Text("Last measurement made on")
                    Spacer()
                    Text(last.measurementsCreatedAt, format: .dateTime.day().month().year())
                }.padding(.vertical, 10)
                PoolDetailFieldView(text: "Free Chlorine:", value: last.freeChlorine)
                PoolDetailFieldView(text: "Chlorine demand:", value: last.chlorineDemand)
                PoolDetailFieldView(text: "PH:", value: last.ph)
                PoolDetailFieldView(text: "PH changes:", value: last.phChanges)
                PoolDetailFieldView(text: "Alkalinity:", value: last.alkalinity)
                PoolDetailFieldView(text: "Alkalinity change:", value: last.alkalinityChanges)
                Spacer()
            }
            NavigationLink("Watch history of measurement", destination: PoolMeasurementHistoryView(id: id, manager: manager))
            NavigationLink("Add measurement", destination: PoolAddMeasurementView(poolID: id, manager: manager))
            Spacer()
            NavigationLink("Watch history of adding chemicals", destination: PoolAddingHistoryView(id: id, manager: manager))
            NavigationLink("Add chemicals", destination: PoolAddChemicalsView(poolID: id, manager: manager))
        }.padding(.horizontal, 20).navigationBarTitle("Pool details").onAppear{
            Task{
                await manager.poolDetails(poolID: id)
            }
        }
    }
}

#Preview {
    NavigationStack {
        PoolView(id: UUID().uuidString, name: "Eleanor", volume: 10000000, manager: PoolManager())
    }
}
