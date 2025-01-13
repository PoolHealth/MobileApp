//
//  ChemicalValuesView.swift
//  PoolHealth
//
//  Created by user on 12/01/2025.
//

import SwiftUI

struct ChemicalValuesView<T>: View where T: Hashable, T: Comparable, T: RawRepresentable<String> {
    public var values: Dictionary<T, Double>?
    var body: some View {
        if let vals = values {
            ForEach(vals.sorted(by: >), id: \.key) { key, value in
                PoolAddingHistoryElementView(name: key.rawValue, value: value)
            }
        }
    }
}

#Preview {
    List{
        ChemicalValuesView<ChlorineChemicals>(values: [.dichlor65Percent:1.2])
    }
}
