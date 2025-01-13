//
//  PoolAddingHistoryElementView.swift
//  PoolHealth
//
//  Created by user on 09/01/2025.
//

import SwiftUI

struct PoolAddingHistoryElementView: View {
    var name: String
    var value: Double?
    var body: some View {
        if value != nil {
            HStack{
                Text("\(name):").bold()
                Text(value!, format: .number.precision(.fractionLength(2)))
            }
        }
    }
}

#Preview {
    PoolAddingHistoryElementView(name: "Calcium Hypochlorite 65%",
                                 value: 2.223423)
}
