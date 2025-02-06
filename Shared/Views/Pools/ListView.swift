//
//  ListView.swift
//  PoolHealth
//
//  Created by user on 03/01/2025.
//

import SwiftUI

struct ListView: View {
    @ObservedObject var manager: PoolManager
    @State var showAdd: Bool = false
    var body: some View {
        ZStack{
            VStack {
                if showAdd {
                    AddView(manager: manager, showAdd: $showAdd)
                } else {
                    HStack{
                        Spacer()
                        Button(action:  {
                            showAdd = true
                        }) {
                            Image(systemName: "plus")
                        }.foregroundColor(.green).bold()
                    }.padding(10)
                    if manager.poolsLoading {
                        ProgressView().onAppear{
                            Task{
                                await manager.loadPools()
                            }
                        }.navigationBarTitle("Loading...")
                    } else {
                        List{
                            ForEach($manager.pools, id: \.id) { $el in
                                NavigationLink(el.name, destination: PoolView(id: el.id, name: el.name, volume: el.volume, settings: el.settings, manager: manager, measureManager: MeasureManager()))
                            }.onDelete(perform: { indexSet in
                                for index in indexSet {
                                    Task{
                                        await manager.deletePool(manager.pools[index].id)
                                    }
                                }
                            })
                        }.navigationBarTitle("List of pools").refreshable {
                            Task{
                                await manager.loadPools()
                            }
                        }
                    }
                    NavigationLink("Magic button", destination: PoolMigrationView(manager: manager))
                }
            }
            VStack{
                if let error = manager.error {
                    Text("netowrk error \(error.localizedDescription)").foregroundStyle(.red)
                }
                Spacer()
            }
        }
    }
}

#Preview {
    ListView(manager: PoolManager())
}
