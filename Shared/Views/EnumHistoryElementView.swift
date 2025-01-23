//
//  PoolAddingHistoryElementView.swift
//  PoolHealth
//
//  Created by user on 09/01/2025.
//

import SwiftUI

struct EnumHistoryElementView: View {
    var name: String
    var value: Double?
    var unit: Units?
    var body: some View {
        if value != nil {
            HStack{
                Text("\(name):").bold()
                Text(value!, format: .number.precision(.fractionLength(2)))
                if let u = unit {
                    Text(u.rawValue)
                }
            }
        }
    }
}

#Preview {
    EnumHistoryElementView(name: "Calcium Hypochlorite 65%", value: 2.223423, unit:.kg)
}
