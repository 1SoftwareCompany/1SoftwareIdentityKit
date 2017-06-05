//
//  NetworkResponse.swift
//  MHIdentityKit
//
//  Created by Milen Halachev on 6/5/17.
//  Copyright © 2017 Milen Halachev. All rights reserved.
//

import Foundation

public struct NetworkResponse {
    
    let data: Data?
    let response: URLResponse?
    let error: Error?
}
