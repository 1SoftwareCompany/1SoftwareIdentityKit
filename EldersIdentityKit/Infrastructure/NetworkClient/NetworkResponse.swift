//
//  NetworkResponse.swift
//  EldersIdentityKit
//
//  Created by Milen Halachev on 6/5/17.
//  Copyright © 2017 Milen Halachev. All rights reserved.
//

import Foundation

public struct NetworkResponse: Sendable {
    
    public var data: Data?
    public var response: URLResponse?
    public var error: Error?
    
    public init(data: Data? = nil, response: URLResponse? = nil, error: Error? = nil) {
        
        self.data = data
        self.response = response
        self.error = error
    }
}
