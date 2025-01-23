//
//  ActionToggleView.swift
//  PoolHealth
//
//  Created by user on 21/01/2025.
//

import SwiftUI

struct ActionToggleView: View {
    var actionType: ActionType
    @Binding var actions: Set<ActionType>
    @State var value: Bool = false
    var body: some View {
        Toggle(isOn: $value) {
            Text(actionType.rawValue)
        }.onChange(of: value) { oldValue, newValue in
            if oldValue {
                actions.remove(actionType)
            }
            if newValue {
                actions.insert(actionType)
            }
        }
    }
}

#Preview {
    ActionToggleView(actionType: .net, actions: .constant([]))
}
