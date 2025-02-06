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
    var settings: PoolSettings?
    var measurementDate: Date = Date()
    @ObservedObject var manager: PoolManager
    @ObservedObject var measureManager: MeasureManager
    var body: some View {
        VStack  {
            HStack{
                Text("Volume \(volume, format: .number.precision(.fractionLength(0))) liters").bold()
                NavigationLink(destination: PoolChangeSettingsView(id: id, name: name, currentSettings: settings, manager:  manager), label: {
                    Image(systemName: "gear")
                })
            }
            Spacer()
            if measureManager.lastMeasurmentLoading {
                ProgressView()
                Spacer()
            } else if let last = measureManager.poolDetails {
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
            HStack{
                Text("Measurements")
                Spacer()
                NavigationLink(destination: PoolAddMeasurementView(poolID: id, manager: measureManager)) {
                    Image(systemName: "plus")
                }
                NavigationLink(destination: PoolMeasurementHistoryView(id: id, manager: measureManager)) {
                    Image(systemName: "clock.arrow.circlepath")
                }
            }
            Spacer()
            HStack{
                Text("Chemicals")
                Spacer()
                NavigationLink(destination: PoolAddChemicalsView(poolID: id, manager: manager, measureManager: measureManager)) {
                    Image(systemName: "plus")
                }
                NavigationLink(destination: PoolAddingHistoryView(id: id, manager: manager)) {
                    Image(systemName: "clock.arrow.circlepath")
                }
            }
            Spacer()
            HStack{
                Text("Actions")
                Spacer()
                NavigationLink(destination: LogActionView(poolID: id, manager: manager)) {
                    Image(systemName: "plus")
                }
                NavigationLink(destination: ActionsHistoryView(poolID: id, manager: manager)) {
                    Image(systemName: "clock.arrow.circlepath")
                }
            }
            Spacer()
        }.padding(.horizontal, 20).navigationBarTitle(name).onAppear{
            Task{
                await measureManager.poolDetails(poolID: id)
            }
        }
    }
}

#Preview {
    NavigationStack {
        PoolView(id: UUID().uuidString, name: "Eleanor", volume: 10000000, manager: PoolManager(), measureManager: MeasureManager())
    }
}
