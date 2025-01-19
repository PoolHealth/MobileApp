//
//  PoolParameterView.swift
//  PoolHealth
//
//  Created by user on 18/01/2025.
//

import SwiftUI

struct PoolParameterView<T>: View where T: Hashable, T: RawRepresentable<String> {
    var title: String
    var initialValue: T?
    public var options: [T]
    @Binding var parameter: T
    var body: some View {
        HStack{
            Text(title)
            Spacer()
            Picker(title, selection: $parameter) {
                ForEach(options, id: \.self) { type in
                    Text(type.rawValue).tag(type)
                }
            }
        }.onAppear {
            guard let p = initialValue else {
                return
            }
            self.parameter = p
        }
        
    }
}

#Preview {
    PoolParameterView(title: "Pool type", options: PoolType.allCases, parameter: .constant(PoolType.skimmer))
}
