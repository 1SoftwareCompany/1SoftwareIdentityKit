//
//  AnyRequestAuthorizer.swift
//  OneSoftwareIdentityKit
//
//  Created by Milen Halachev on 11.08.18.
//  Copyright © 2018 Milen Halachev. All rights reserved.
//

import Foundation

///A default, closure based implementation of RequestAuthorizer
public struct AnyRequestAuthorizer: RequestAuthorizer, @unchecked Sendable {
    
    public let handler: (_ request: URLRequest, _ handler: @escaping @Sendable (URLRequest, Error?) -> Void) -> Void
    
    public init(handler: @escaping (_ request: URLRequest, _ handler: @escaping @Sendable (URLRequest, Error?) -> Void) -> Void) {
        
        self.handler = handler
    }
    
    public init(other requestAuthorizer: RequestAuthorizer) {
        
        self.handler = requestAuthorizer.authorize(request:handler:)
    }
    
    public func authorize(request: URLRequest, handler: @escaping @Sendable (URLRequest, Error?) -> Void) {
        
        self.handler(request, handler)
    }
}
