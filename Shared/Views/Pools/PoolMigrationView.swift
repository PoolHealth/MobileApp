//
//  PoolMigrationView.swift
//  PoolHealth
//
//  Created by user on 27/01/2025.
//

import SwiftUI

struct PoolMigrationView: View {
    @State var sheetLink: String = ""
    @ObservedObject var manager: PoolManager
    var body: some View {
        Section {
            Text("DANGER ZONE: Migrate pools, if you changed something in structure of sheet it can corrupt data in database").foregroundColor(.red).border(.red)
            if manager.migrationStatus != .notStarted {
                HStack {
                    Text("Migration status:")
                    Spacer()
                    Text(manager.migrationStatus.rawValue).bold()
                }
            }
            if manager.migrationStatus != .inProgress {
                Spacer()
                HStack {
                    Text("Insert link to the sheet:")
                    Spacer()
                    TextField("Sheet link", text: $sheetLink)
                }
                Button("Start migration"){
                    Task{
                        await manager.migrate(sheetLink: sheetLink)
                        sheetLink = ""
                    }
                }.disabled(sheetLink == "")
                Spacer()
            }
        }.navigationBarTitle("List of pools").padding(.horizontal, 20).onAppear{
            Task {
                await manager.startCheckMigrationStatus()
            }
        }
    }
}

#Preview {
    PoolMigrationView(manager: PoolManager())
}
