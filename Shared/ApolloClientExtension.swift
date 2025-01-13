//
//  ApolloClientExtension.swift
//  ApolloClientExtension
//
//  Created by Andrew Khasanov on 29.08.2021.
//

import Foundation
import Apollo
import PoolHealthSchema

extension ApolloClient {
    public func fetchAsync<Query: GraphQLQuery>(query: Query,
                                                cachePolicy: CachePolicy = .default,
                                                contextIdentifier: UUID? = nil,
                                                queue: DispatchQueue = .main) -> AsyncThrowingStream<GraphQLResult<Query.Data>, Error> {
        AsyncThrowingStream { continuation in
                    let request = fetch(
                        query: query,
                        cachePolicy: cachePolicy,
                        contextIdentifier: contextIdentifier,
                        queue: queue
                    ) { response in
                        switch response {
                        case .success(let result):
                            continuation.yield(result)
                            if result.isFinalForCachePolicy(cachePolicy) {
                                continuation.finish()
                            }
                        case .failure(let error):
                            continuation.finish(throwing: error)
                        }
                    }
                    continuation.onTermination = { @Sendable _ in
                        request.cancel()
                    }
                }
    }
    
    public func performAsync<Mutation: GraphQLMutation>(mutation: Mutation, publishResultToStore: Bool = true, queue: DispatchQueue = .main) async -> Result<GraphQLResult<Mutation.Data>, Error> {
        await withCheckedContinuation{ continuation in
            self.perform(mutation: mutation, publishResultToStore: publishResultToStore, queue: queue) { result in
                continuation.resume(returning: result)
            }
        }
    }
    
}

fileprivate extension GraphQLResult {
    func isFinalForCachePolicy(_ cachePolicy: CachePolicy) -> Bool {
        switch cachePolicy {
        case .returnCacheDataAndFetch:
            return source == .server
        default:
            return true
        }
    }
}
