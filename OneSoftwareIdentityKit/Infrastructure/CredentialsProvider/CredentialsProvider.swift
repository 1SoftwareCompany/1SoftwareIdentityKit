//
//  CredentialsProvider.swift
//  OneSoftwareIdentityKit
//
//  Created by Milen Halachev on 4/12/17.
//  Copyright © 2017 Milen Halachev. All rights reserved.
//

import Foundation

///A type that provides credentials
public protocol CredentialsProvider: Sendable {
    
    typealias Username = String
    typealias Password = String
    
    ///Provides credentials in an asynchronous manner. Can be implemented in a way to show a login screen.
    func credentials(handler: @escaping @Sendable (Username, Password) -> Void)
    
    ///(Optional) Called to notify the receiver that authentication has been successful with the suplied credentials.
    func didFinishAuthenticating()
    
    ///(Optional) Called to notify the receiver that authentication has failed with the suplied credentials
    func didFailAuthenticating(with error: Error)
}

extension CredentialsProvider {

    ///Provides credentials asynchronously. Can be implemented in a way to show a login screen.
    @available(iOS 13, tvOS 13, macOS 10.15, watchOS 6, *)
    public func credentials() async -> (Username, Password) {
        
        return await withCheckedContinuation { continuation in
            
            self.credentials { (username, password) in
                
                continuation.resume(returning: (username, password))
            }
        }
    }
}

extension CredentialsProvider {
    
    public func didFinishAuthenticating() {
        
        
    }
    
    public func didFailAuthenticating(with error: Error) {
        
    }
}


