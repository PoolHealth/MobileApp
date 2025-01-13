//
//  PoolAddMeasurementView.swift
//  PoolHealth
//
//  Created by user on 07/01/2025.
//

import SwiftUI

struct PoolAddMeasurementView: View {
    var poolID: String
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @ObservedObject var manager: PoolManager
    @State var chlorine: Double?
    @State var alkalinity: Double?
    @State var pH: Double?
    var body: some View {
        VStack{
            Spacer()
            HStack{
                Text("Chlorine: ")
                TextField("Enter chlorine", value: $chlorine, format: .number).keyboardType(.decimalPad)
            }.padding(.vertical, 30)
            HStack{
                Text("Alkalinity: ")
                TextField("Enter alkalinity", value: $alkalinity, format: .number).keyboardType(.decimalPad)
            }.padding(.vertical, 30)
            HStack{
                Text("PH: ")
                TextField("Enter pH", value: $pH, format: .number).keyboardType(.decimalPad)
            }.padding(.vertical, 30)
            Spacer()
            Button("Add") {
                Task {
                    await manager.addMeasurement(poolID: poolID, chlorine: chlorine, alkalinity: alkalinity, pH: pH)
                    if manager.error == nil {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }.navigationBarTitle("Add measurement").padding(.horizontal, 20)
    }
}

#Preview {
    NavigationStack {
        PoolAddMeasurementView(poolID: UUID().uuidString, manager: PoolManager())
    }
}
