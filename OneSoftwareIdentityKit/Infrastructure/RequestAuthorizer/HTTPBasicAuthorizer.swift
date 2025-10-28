//
//  ClientHTTPBasicAuthorizer.swift
//  OneSoftwareIdentityKit
//
//  Created by Milen Halachev on 5/26/17.
//  Copyright © 2017 Milen Halachev. All rights reserved.
//

import Foundation

///Authorizes a request using HTTP Basic authentication scheme
public struct HTTPBasicAuthorizer: RequestAuthorizer {
    
    public var username: String
    public var password: String
    
    public init(username: String, password: String) {
        
        self.username = username
        self.password = password
    }
    
    public func authorize(request: URLRequest, handler: @escaping @Sendable (URLRequest, Error?) -> Void) {
        
        guard let credentials = (username + ":" + password).data(using: .utf8)?.base64EncodedString() else {
            
            let error = OneSoftwareIdentityKitError.authorizationFailed(reason: OneSoftwareIdentityKitError.Reason.buildAuthenticationHeaderFailed)
            handler(request, error)
            return
        }
        
        var request = request
        let header = "Basic " + credentials
        request.setValue(header, forHTTPHeaderField: "Authorization")
        handler(request, nil)
    }
}

extension HTTPBasicAuthorizer {
    
    public init(clientID: String, secret: String) {
        
        self.init(username: clientID, password: secret)
    }
}
