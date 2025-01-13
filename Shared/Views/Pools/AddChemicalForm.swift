//
//  AddChemicalForm.swift
//  PoolHealth
//
//  Created by user on 12/01/2025.
//

import SwiftUI

struct AddChemicalForm<T>: View where T: Hashable, T: RawRepresentable<String> {
    public var title: String
    public var options: [T]
    @Binding var key: T?
    @Binding var value: Double?
    var onChange: () -> Void
    var body: some View {
        Section(header: Text(title)){
            HStack{
                Picker(title, selection: $key) {
                    Text("None").tag(T?(nil))
                    ForEach(options, id: \.self) { chemical in
                        Text(chemical.rawValue).tag(chemical)
                    }
                }.pickerStyle(.wheel).onChange(of: key, onChange)
                TextField("Enter value", value: $value, format: .number).keyboardType(.decimalPad).onChange(of: value, onChange).frame(maxWidth: 40,alignment: .trailing)
            }
        }
    }
}

#Preview {
    AddChemicalForm<ChlorineChemicals>(title: "Add Chlorine", options:ChlorineChemicals.allCases, key: .constant(ChlorineChemicals.calciumHypochlorite65Percent), value: .constant(10.12)){
        print("123")
    }
}
