//
//  CacheInterceptor.swift
//  TeaElephant
//
//  Created by Andrew Khasanov on 03/08/2023.
//

import Foundation
import Apollo
import ApolloAPI
import KeychainSwift

class UnauthInterceptor: ApolloInterceptor {
    var id =  "UnAuthorizationInterceptor"
    
    func interceptAsync<Operation>(chain: RequestChain, request: HTTPRequest<Operation>, response: HTTPResponse<Operation>?, completion: @escaping (Result<GraphQLResult<Operation.Data>, Error>) -> Void) where Operation : GraphQLOperation {
        guard let err = response?.parsedResponse?.errors?.first else {
            // No errors, or response not parsed yet - just continue
            AuthManager.shared.auth = true
            chain.proceedAsync(request: request, response: response, interceptor: self, completion: completion)
            return
        }
        guard let code = err.extensions?["code"] as? String else {
            chain.proceedAsync(request: request, response: response, interceptor: self, completion: completion)
            return
        }
        if Int(code) == -1 {
            AuthManager.shared.keychain.delete(tokenKey)
            print("token was wiped")
            AuthManager.shared.auth = false
        }
        chain.proceedAsync(request: request, response: response, interceptor: self, completion: completion)
    }
}

