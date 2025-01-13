//
//  CacheInterceptor.swift
//  TeaElephant
//
//  Created by Andrew Khasanov on 03/08/2023.
//

import Foundation
import Apollo
import ApolloAPI

class NoCachedErrorsWrapperInterceptor: ApolloInterceptor {
    let cacheWriteInterceptor: CacheWriteInterceptor
    var id: String = UUID().uuidString
    
    init(wrapping cacheWriteInterceptor: CacheWriteInterceptor) {
        self.cacheWriteInterceptor = cacheWriteInterceptor
        self.id = cacheWriteInterceptor.id
      }
    
    func interceptAsync<Operation>(chain: RequestChain, request: HTTPRequest<Operation>, response: HTTPResponse<Operation>?, completion: @escaping (Result<GraphQLResult<Operation.Data>, Error>) -> Void) where Operation : GraphQLOperation {
      guard let errors = response?.parsedResponse?.errors else {
        // No errors, or response not parsed yet - just continue
        cacheWriteInterceptor.interceptAsync(chain: chain, request: request, response: response, completion: completion)
        return
      }
      
      if errors.count == 0 {
        cacheWriteInterceptor.interceptAsync(chain: chain, request: request, response: response, completion: completion)
      }
      else {
        // Don't cache any response with errors
        chain.proceedAsync(request: request, response: response, interceptor: cacheWriteInterceptor, completion: completion)
      }
    }
}

