//
//  AuthorizationGrantFlow.swift
//  EldersIdentityKit
//
//  Created by Milen Halachev on 4/11/17.
//  Copyright © 2017 Milen Halachev. All rights reserved.
//

import Foundation

//A type that performs an authorization grant flow in order to authenticate a client.
@MainActor
public protocol AuthorizationGrantFlow {
        
    /**
     Executes the flow that authenticates the user and upon success returns an access token that can be used to authorize client's requests
     
     - parameter handler: The callback, executed when the authentication is complete. The callback takes 2 arguments - a Token and an Error
     */
    func authenticate(handler: @escaping @Sendable @MainActor (AccessTokenResponse?, Error?) -> Void)
}

extension AuthorizationGrantFlow {
    
    /**
     Asynchronously executes the flow that authenticates the user and upon success returns an access token that can be used to authorize client's requests
     
     - throws: If authentication fails
     
     - returns: The access token
     */
    @available(iOS 13, tvOS 13, macOS 10.15, watchOS 6, *)
    public func authenticate() async throws -> AccessTokenResponse {
        
        return try await withCheckedThrowingContinuation { continuation in
            self.authenticate { response, error in
                
                if let error = error {
                    continuation.resume(throwing: error)
                }
                else {
                    
                    guard let response = response else {
                        continuation.resume(throwing: EldersIdentityKitError.Reason.invalidAccessTokenResponse)
                        return
                    }
                    
                    continuation.resume(returning: response)
                }
            }
        }
    }
}
