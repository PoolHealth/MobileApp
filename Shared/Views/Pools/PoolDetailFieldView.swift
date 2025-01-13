//
//  PoolDetailFieldView.swift
//  PoolHealth
//
//  Created by user on 12/01/2025.
//

import SwiftUI

struct PoolDetailFieldView: View {
    public var text: String
    public var value: Double?
    var body: some View {
        if let val = value {
            HStack{
                Text(text)
                Spacer()
                Text(val, format: .number.precision(.fractionLength(2)))
            }
        }
    }
}

#Preview {
    PoolDetailFieldView(text: "Sone text", value: 123)
}
