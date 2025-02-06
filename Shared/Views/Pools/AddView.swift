//
//  AddView.swift
//  PoolHealth
//
//  Created by user on 03/01/2025.
//

import SwiftUI

struct AddView: View {
    @ObservedObject var manager: PoolManager
    @State private var name = ""
    @State private var volume: Double?
    @Binding var showAdd: Bool
    var body: some View {
        VStack{
            Text("Add new pool")
            Spacer()
            HStack{
                Text("Name")
                TextField("Name of the pool", text: $name)
            }
            HStack{
                Text("Volume")
                TextField("Volume of the pool", value: $volume, format: .number).keyboardType(.decimalPad)
                Text("liters")
            }
            Spacer()
            HStack{
                Button("Cancel") {
                    showAdd = false
                }.foregroundStyle(.red)
                Spacer()
                Button("Add") {
                    guard let volume = volume else {
                        return
                    }
                    Task {
                        await manager.addPool(name: name, volume: Double(volume))
                        showAdd = false
                    }
                }.disabled(volume == nil || name == "")
                
            }
        }.padding(.horizontal, 30).padding(.vertical, 20)
    }
}

#Preview {
    AddView(manager: PoolManager(), showAdd: .constant(true))
}
