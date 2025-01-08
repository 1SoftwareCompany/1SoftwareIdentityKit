//
//  AccessTokenResponseHandler.swift
//  EldersIdentityKit
//
//  Created by Milen Halachev on 6/1/17.
//  Copyright © 2017 Milen Halachev. All rights reserved.
//

import Foundation
import XCTest
@testable import EldersIdentityKit

@MainActor
class AccessTokenResponseHandlerTests: XCTestCase {
    
    func testSuccess() {
        
        self.performExpectation { (e) in
            
            e.fulfilUnlessThrowing {
                
                let data = "{\"access_token\":\"gg\", \"token_type\":\"Bearer\", \"expires_in\": 1234, \"refresh_token\":\"rtgg\", \"scope\":\"read write\"}".data(using: .utf8)
                let response = HTTPURLResponse(url: URL(string: "http://foo.bar")!, statusCode: 200, httpVersion: nil, headerFields: nil)
                let accessTokenResponse = try AccessTokenResponseHandler().handle(response: NetworkResponse(data: data, response: response, error: nil))
                XCTAssertEqual(accessTokenResponse.accessToken, "gg")
                XCTAssertEqual(accessTokenResponse.tokenType, "Bearer")
                XCTAssertEqual(accessTokenResponse.expiresIn, 1234)
                XCTAssertEqual(accessTokenResponse.refreshToken, "rtgg")
                XCTAssertEqual(accessTokenResponse.scope?.rawValue, "read write")
            }
        }
    }
    
    func testNetworkClientError() {
        
        self.performExpectation { (e) in
            
            e.fulfilOnThrowing("err", { 
                
                _ = try AccessTokenResponseHandler().handle(response: NetworkResponse(data: nil, response: nil, error: "err"))
            })
        }
    }
    
    func testMissingResponseError() {
        
        self.performExpectation { (e) in
            
            e.fulfilOnThrowing(EldersIdentityKitError.Reason.unknownURLResponse, {
                
                _ = try AccessTokenResponseHandler().handle(response: NetworkResponse(data: nil, response: nil, error: nil))
            })
        }
    }
    
    func testMissingURLError() {
        
        self.performExpectation { (e) in
            
            e.fulfilOnThrowing(EldersIdentityKitError.Reason.unknownURLResponse, {
                
                _ = try AccessTokenResponseHandler().handle(response: NetworkResponse(data: nil, response: URLResponse(), error: nil))
            })
        }
    }
    
    func testNilDataError() {
        
        self.performExpectation { (e) in
            
            e.fulfilOnThrowing(EldersIdentityKitError.Reason.invalidAccessTokenResponse, {
                
                let response = HTTPURLResponse(url: URL(string: "http://foo.bar")!, statusCode: 555, httpVersion: nil, headerFields: nil)
                _ = try AccessTokenResponseHandler().handle(response: NetworkResponse(data: nil, response: response, error: nil))
            })
        }
    }
    
    func testOAuth2Error() {
        
        self.performExpectation { (e) in
            
            e.fulfilOnThrowing(ErrorResponse(code: .invalidGrant), {
                
                let data = "{\"error\":\"invalid_grant\"}".data(using: .utf8)
                let response = HTTPURLResponse(url: URL(string: "http://foo.bar")!, statusCode: 555, httpVersion: nil, headerFields: nil)
                _ = try AccessTokenResponseHandler().handle(response: NetworkResponse(data: data, response: response, error: nil))
            })
        }
    }
    
    func testServerError() {
        
        self.performExpectation { (e) in
            
            e.fulfilOnThrowing(EldersIdentityKitError.Reason.unknownHTTPResponse(code: 555), {
                
                let data = "{}".data(using: .utf8)
                let response = HTTPURLResponse(url: URL(string: "http://foo.bar")!, statusCode: 555, httpVersion: nil, headerFields: nil)
                _ = try AccessTokenResponseHandler().handle(response: NetworkResponse(data: data, response: response, error: nil))
            })
        }
    }
    
    func testEmptyJSONError() {
        
        self.performExpectation { (e) in
            
            e.fulfilOnThrowing(EldersIdentityKitError.Reason.invalidAccessTokenResponse, {
                
                let data = "{}".data(using: .utf8)
                let response = HTTPURLResponse(url: URL(string: "http://foo.bar")!, statusCode: 200, httpVersion: nil, headerFields: nil)
                _ = try AccessTokenResponseHandler().handle(response: NetworkResponse(data: data, response: response, error: nil))
            })
        }
    }
    
    func testAdditioanlParameteres() {
        
        self.performExpectation { (e) in
            
            e.fulfilUnlessThrowing {
                
                let data =
                """
                { "access_token":"gg", "token_type":"Bearer", "expires_in": 1234, "refresh_token":"rtgg", "scope":"read write", "custom_param1": true, "custom_str": "zagreo", "my_int": 5 }
                """
                .data(using: .utf8)
                
                let response = HTTPURLResponse(url: URL(string: "http://foo.bar")!, statusCode: 200, httpVersion: nil, headerFields: nil)
                let accessTokenResponse = try AccessTokenResponseHandler().handle(response: NetworkResponse(data: data, response: response, error: nil))
                XCTAssertEqual(accessTokenResponse.accessToken, "gg")
                XCTAssertEqual(accessTokenResponse.tokenType, "Bearer")
                XCTAssertEqual(accessTokenResponse.expiresIn, 1234)
                XCTAssertEqual(accessTokenResponse.refreshToken, "rtgg")
                XCTAssertEqual(accessTokenResponse.scope?.rawValue, "read write")
                XCTAssertEqual(accessTokenResponse.additionalParameters["custom_param1"] as? Bool, true)
                XCTAssertEqual(accessTokenResponse.additionalParameters["custom_str"] as? String, "zagreo")
                XCTAssertEqual(accessTokenResponse.additionalParameters["my_int"] as? Int, 5)
            }
        }
    }
    
    func testMissingRequiredParameters() {
        
        self.performExpectation { (e) in
            
            e.fulfilOnThrowing(EldersIdentityKitError.Reason.invalidAccessTokenResponse) {
                
                let data =
                """
                { "access_token":"gg", "expires_in": 1234, "refresh_token":"rtgg", "scope":"read write", "custom_param1": true, "custom_str": "zagreo", "my_int": 5 }
                """
                .data(using: .utf8)
                
                let response = HTTPURLResponse(url: URL(string: "http://foo.bar")!, statusCode: 200, httpVersion: nil, headerFields: nil)
                _ = try AccessTokenResponseHandler().handle(response: NetworkResponse(data: data, response: response, error: nil))
            }
        }
    }
}
