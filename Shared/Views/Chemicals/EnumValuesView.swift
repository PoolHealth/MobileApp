//
//  ChemicalValuesView.swift
//  PoolHealth
//
//  Created by user on 12/01/2025.
//

import SwiftUI

struct EnumValuesView<T>: View where T: Hashable, T: Comparable, T: RawRepresentable<String> {
    public var values: Dictionary<T, Double>?
    public var units: Dictionary<T, Units>
    var body: some View {
        if let vals = values {
            ForEach(vals.sorted(by: >), id: \.key) { key, value in
                EnumHistoryElementView(name: key.rawValue, value: value, unit: units[key])
            }
        }
    }
}

#Preview {
    List{
        EnumValuesView<ChlorineChemicals>(values: [.dichlor65Percent:1.2], units:ChlorineChemicalsUnits)
    }
}
