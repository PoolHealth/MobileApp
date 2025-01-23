//
//  ActionsHistoryDumbView.swift
//  PoolHealth
//
//  Created by user on 22/01/2025.
//

import SwiftUI

struct ActionsHistoryDumbView: View {
    var actions: [Action]
    var body: some View {
        List {
            ForEach(actions,id: \.createdAt) { el in
                Section(header:Text(el.createdAt, format: .dateTime.day().month().year().hour().minute()) ){
                    HStack{
                        ForEach(el.actions, id: \.self) { value in
                            Text("\(value.rawValue)").bold()
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    ActionsHistoryDumbView(actions: [
        Action(actions: [.net, .brush, .backwash, .pumpBasketClean, .scumLine, .scumLine, .vacuum], createdAt: Date())])
}
