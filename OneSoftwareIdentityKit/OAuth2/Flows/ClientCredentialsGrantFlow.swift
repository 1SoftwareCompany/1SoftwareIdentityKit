//
//  ClientCredentialsGrantFlow.swift
//  OneSoftwareIdentityKit
//
//  Created by Milen Halachev on 6/2/17.
//  Copyright © 2017 Milen Halachev. All rights reserved.
//

import Foundation

//https://tools.ietf.org/html/rfc6749#section-4.4
open class ClientCredentialsGrantFlow: AuthorizationGrantFlow, @unchecked Sendable {
    
    public let tokenEndpoint: URL
    public let scope: Scope?
    public let clientAuthorizer: RequestAuthorizer
    public let networkClient: NetworkClient
    
    ///You can specify additional access token request parameters. If existing key is duplicated, the one specified by this property will be used.
    public var additionalAccessTokenRequestParameters: [String: Any] = [:]
    
    /**
     Creates an instance of the receiver.
     
     - parameter tokenEndpoint: The URL of the token endpoint
     - parameter scope: The scope of the access request.
     - parameter clientAuthorizer: An authorizer used to authorize the authentication request. Usually an instance of HTTPBasicAuthorizer with your clientID and secret.
     - parameter networkClient: A network client used to perform the authentication request.
     
     */
    
    public init(tokenEndpoint: URL, scope: Scope? = nil, clientAuthorizer: RequestAuthorizer, networkClient: NetworkClient = _defaultNetworkClient) {
        
        self.tokenEndpoint = tokenEndpoint
        self.scope = scope
        self.clientAuthorizer = clientAuthorizer
        self.networkClient = networkClient
    }
    
    //MARK: - Flow logic
    
    open func parameters(from accessTokenRequest: AccessTokenRequest) -> [String: Any] {
        
        return accessTokenRequest.dictionary.merging(self.additionalAccessTokenRequestParameters, uniquingKeysWith: { $1 })
    }
    
    open func data(from parameters: [String: Any]) -> Data? {
        
        return parameters.urlEncodedParametersData
    }
    
    open func urlRequest(from accessTokenRequest: AccessTokenRequest) -> URLRequest {
        
        var request = URLRequest(url: self.tokenEndpoint)
        request.httpMethod = "POST"
        request.httpBody = self.data(from: self.parameters(from: accessTokenRequest))
        
        return request
    }
    
    open func authorize(_ request: URLRequest, handler: @escaping @Sendable (URLRequest, Error?) -> Void) {
        
        self.clientAuthorizer.authorize(request: request, handler: handler)
    }
    
    open func perform(_ request: URLRequest, completion: @escaping @Sendable (NetworkResponse) -> Void) {
        
        self.networkClient.perform(request, completion: completion)
    }
    
    open func accessTokenResponse(from networkResponse: NetworkResponse) throws -> AccessTokenResponse {
        
        return try AccessTokenResponseHandler().handle(response: networkResponse)
    }
    
    open func validate(_ accessTokenResponse: AccessTokenResponse) throws {
        
        //https://tools.ietf.org/html/rfc6749#section-4.4.3
        //A refresh token SHOULD NOT be included
        guard accessTokenResponse.refreshToken == nil else {
            
            throw OneSoftwareIdentityKitError.authenticationFailed(reason: OneSoftwareIdentityKitError.Reason.invalidAccessTokenResponse)
        }
    }
    
    open func authenticate(using request: URLRequest, handler: @escaping @Sendable (AccessTokenResponse?, Error?) -> Void) {
        
        self.authorize(request, handler: { (request, error) in
            
            guard error == nil else {
                
                handler(nil, error)
                return
            }
            
            self.perform(request, completion: { (response) in
                do {
                    
                    let accessTokenResponse = try self.accessTokenResponse(from: response)
                    try self.validate(accessTokenResponse)
                    
                    handler(accessTokenResponse, nil)
                }
                catch {
                    
                    DispatchQueue.main.async {
                        
                        handler(nil, error)
                    }
                }
            })
        })
    }
    
    //MARK: - AuthorizationGrantFlow
    
    open func authenticate(handler: @escaping @Sendable (AccessTokenResponse?, Error?) -> Void) {
        
        //build the request
        let accessTokenRequest = AccessTokenRequest(scope: self.scope)
        let request = self.urlRequest(from: accessTokenRequest)
        self.authenticate(using: request, handler: handler)
    }
}

//MARK: - Models

extension ClientCredentialsGrantFlow {
    
    //https://tools.ietf.org/html/rfc6749#section-4.4.2
    public struct AccessTokenRequest {
        
        public let grantType: GrantType = .clientCredentials
        public var scope: Scope?
        
        public init(scope: Scope? = nil) {
         
            self.scope = scope
        }
        
        public var dictionary: [String: Any] {
            
            var dictionary = [String: Any]()
            dictionary["grant_type"] = self.grantType.rawValue
            dictionary["scope"] = self.scope?.value
            
            return dictionary
        }
    }
    
    
}
