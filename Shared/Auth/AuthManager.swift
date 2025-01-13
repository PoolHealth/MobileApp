//
//  collectionsMnagement.swift
//  TeaElephant
//
//  Created by Andrew Khasanov on 11/08/2023.
//

import Foundation
@preconcurrency import Apollo
import PoolHealthSchema
import os
import KeychainSwift
import UIKit

@preconcurrency
class AuthManager: ObservableObject {
    @Published var error: Error?
    @Published var loading = true
    @Published var auth = false
    static let shared = AuthManager()
    let log = Logger(subsystem: "xax.PoolHealth", category: "AuthManager")
    let keychain = KeychainSwift()
    
    private enum Key {
        static var deviceID = "deviceID"
    }
    
    var deviceId: String {
        if let deviceID = UserDefaults.standard.string(forKey: Key.deviceID) {
            return deviceID
        }
        let deviceID: String = (UIDevice.current.identifierForVendor ?? UUID()).uuidString
        UserDefaults.standard.set(deviceID, forKey: Key.deviceID)
        return deviceID
    }
    
    func authorized() async {
        await MainActor.run {
            self.loading = true
        }
        do {
            for try await result in Network.shared.apollo.fetchAsync(query: MeQuery(), cachePolicy: .fetchIgnoringCacheData) {
                await MainActor.run {
                    guard let err = result.errors?.first else {
                        self.auth = true
                        return
                    }
                    self.auth = false
                    guard let code = err.extensions?["code"] as? Int else {
                        self.error = err
                        return
                    }
                    switch code {
                    case -1:
                            return
                    default:
                            self.error = err
                        return
                    }
                }
            }
        } catch {
            await MainActor.run {
                self.auth = false
                self.error = error
            }
        }
        await MainActor.run {
            self.loading = false
        }
    }
    
    func Auth(_ code: String) async {
        self.keychain.delete(tokenKey)
        log.debug("code: \(code), deviceID: \(self.deviceId)")
        let result = await Network.shared.apollo.performAsync(mutation: AuthMutation(code: code, deviceID: deviceId))
        switch result {
        case .success(let graphQLResult):
            if let errors = graphQLResult.errors {
                print(errors)
                return
            }
            guard let token = graphQLResult.data?.authApple.token else { return }
            await MainActor.run {
                self.log.debug("new token \(token)")
                self.keychain.synchronizable = true
                self.keychain.set(token, forKey: tokenKey)
                self.auth = true
                self.error = nil
                Network.shared.Auth(token)
            }
            
        case .failure(let error):
            print(error)
        }
    }
    
    func checkAuth(errors: [GraphQLError]?) async {
        await MainActor.run {
            guard let err = errors?.first else {
                self.auth = true
                return
            }
            guard let code = err.extensions?["code"] as? Int else {
                return
            }
            if code == -1 {
                self.auth = false
            }
        }
    }
}
