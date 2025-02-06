//
//  UserAreaUIView.swift
//  TeaElephant
//
//  Created by Andrew Khasanov on 13/08/2023.
//

import SwiftUI
import CoreSpotlight

struct UserAreaUIView: View {
    @ObservedObject private var manager = PoolManager()
    @ObservedObject var authManager = AuthManager()
    @State private var navigationPath = NavigationPath()
    
    var body: some View {
        if authManager.loading {
            ProgressView().onAppear{
                Task{
                    await authManager.authorized()
                }
            }
        } else if authManager.auth {
            if #available(iOS 18.0, *) {
                NavigationStack(path: $navigationPath){
                    ListView(manager: manager).navigationDestination(for: String.self) { poolID in
                        let pool = manager.pools.first { p in
                            p.id == poolID
                        }
                        PoolView(id: poolID, name: pool?.name ?? "", volume: pool?.volume ?? 0, manager: manager, measureManager: MeasureManager())
                    }
                    // Listen for the Spotlight NSUserActivity
                    .onContinueUserActivity(CSSearchableItemActionType) { userActivity in
                        if let poolLink = userActivity.userInfo?[CSSearchableItemActivityIdentifier] as? String,
                               let poolID = poolLink.split(separator: "/").last {
                                print("Received pool id: \(poolID)")
                                navigationPath.append(String(poolID))
                            }
                    }
                }
            } else {
                Text("Unsupported")
            }
        } else {
            AuthUIView()
        }
    }
}

struct UserAreaUIView_Previews: PreviewProvider {
    static var previews: some View {
        UserAreaUIView(authManager: AuthManager.shared)
    }
}
