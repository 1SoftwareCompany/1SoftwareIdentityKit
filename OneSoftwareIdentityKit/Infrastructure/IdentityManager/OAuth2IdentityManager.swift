//
//  OAuth2IdentityManager.swift
//  OneSoftwareIdentityKit
//
//  Created by Milen Halachev on 6/5/17.
//  Copyright © 2017 Milen Halachev. All rights reserved.
//

import Foundation

///Perform an authorization using an OAuth2 AuthorizationGrantFlow for authentication with a behaviour that refresh a token if possible and preserves a state.
///The core logic is ilustrated here - https://tools.ietf.org/html/rfc6749#section-1.5
open class OAuth2IdentityManager: IdentityManager {
    
    //used for authentication - getting OAuth2 access token
    public let flow: AuthorizationGrantFlow
    
    //used to refresh an access token using a refresh token if aplicable
    public let refresher: AccessTokenRefresher?
    
    //used to store state, like the refresh token
    public let storage: IdentityStorage?
    
    //used to provide an authorizer that authorize the request using the provided access token response
    public let tokenAuthorizerProvider: (AccessTokenResponse) -> RequestAuthorizer
    
    //    private let queue = DispatchQueue(label: bundleIdentifier + ".OAuth2IdentityManager", qos: .default)
    private var queue: OperationQueue = {
        
        let queue = OperationQueue()
        queue.name = bundleIdentifier + ".OAuth2IdentityManager"
        queue.maxConcurrentOperationCount = 1
        
        return queue
    }()
    
    /**
     Creates an instnce of the receiver.
     
     - parameter flow: An OAuth2 authorization grant flow used for authentication.
     - parameter refresher: An optional access token refresher, used to refresh an access token if expired and when possible.
     - parameter storage: An identity storage, used to store some state, like the refresh token.
     - parameter tokenAuthorizerProvider: A closure that provides a request authorizer used to authorize incoming requests with the provided access token
     
     */
    
    public init(flow: AuthorizationGrantFlow, refresher: AccessTokenRefresher?, storage: IdentityStorage?, tokenAuthorizerProvider: @escaping (AccessTokenResponse) -> RequestAuthorizer) {
        
        self.flow = flow
        self.refresher = refresher
        self.storage = storage
        self.tokenAuthorizerProvider = tokenAuthorizerProvider
    }
    
    //MARK: - Configuration
    
    ///Controls whenver an authentication should be forced if a refresh fails. If `true`, when a refresh token fails, an authentication will be performed automatically using the flow provided. If `false` an error will be returned. Default to `true`.
    open var forceAuthenticateOnRefreshError = true
    
    /***
     Controls whenever an authorization should be retried if an authentication fails. If `true`, when an authentication fails - the authorization will be retried automatically untill there is a successfull authentication. If `false` an error will be returned. Default to `false`.
     
     - note: This behaviour is needed when the authorization requires user input, like in the `ResourceOwnerPasswordCredentialsGrantFlow` where the `CredentialsProvider` is a login screen. As opposite it is not needed when user input is not involved, because it could lead to infinite loop of authorizations.
     
     */
    
    open var retryAuthorizationOnAuthenticationError = false
    
    //MARK: - State
    
    public private(set) var accessTokenResponse: AccessTokenResponse? {
        
        didSet {
            
            self.storage?.refreshToken = self.accessTokenResponse?.refreshToken
            self.storage?.scope = self.accessTokenResponse?.scope
        }
    }
    
    ///The available refresh token - either from the access token response or from the storage.
    var refreshToken: String? {
        
        let refreshToken = self.accessTokenResponse?.refreshToken ?? self.storage?.refreshToken
        
        //if token is empty string - ignore it
        if refreshToken?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == true {
            
            return nil
        }
        
        return refreshToken
    }
    
    private var scope: Scope? {
        
        let scope = self.accessTokenResponse?.scope ?? self.storage?.scope
        return scope
    }
    
    //MARK: - IdentityManager
    
    private func performAuthentication(handler: @escaping (AccessTokenResponse?, Error?) -> Void) {
        
        self.postWillAuthenticateNotification()
        
        self.flow.authenticate { (response, error) in
            Task { @MainActor in
                self.didFinishAuthenticating(with: response, error: error)
                handler(response, error)
            }
        }
    }
    
    private func performAuthentication() async throws -> AccessTokenResponse {
        self.postWillAuthenticateNotification()
        
        return try await withCheckedThrowingContinuation { continuation in
            self.flow.authenticate { response, error in
                Task { @MainActor in
                    self.didFinishAuthenticating(with: response, error: error)
                    
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else if let response = response {
                        continuation.resume(returning: response)
                    } else {
                        continuation.resume(throwing: NSError(domain: "AuthenticationError", code: 0, userInfo: nil))
                    }
                }
            }
        }
    }
    
    private func authenticate(forced: Bool) async throws -> AccessTokenResponse {
        
        if forced {
            return try await self.performAuthentication()
        }
        
        if let refresher = self.refresher,
           let refreshToken = self.refreshToken {
            let request = AccessTokenRefreshRequest(refreshToken: refreshToken, scope: self.scope)
            
            do {
                return try await withCheckedThrowingContinuation { continuation in
                    refresher.refresh(using: request) { [weak self] response, error in
                        Task { @MainActor in
                            if let error = error as? OneSoftwareIdentityKitError, error.contains(error: ErrorResponse.self) {
                                
                                self?.accessTokenResponse?.refreshToken = nil
                                
                                if self?.forceAuthenticateOnRefreshError == true {
                                    continuation.resume(with: .failure(error))
                                    return
                                }
                            }
                            
                            // Resume the continuation
                            if let error = error {
                                continuation.resume(with: .failure(error))
                            } else if let response = response {
                                continuation.resume(with: .success(response))
                            } else {
                                continuation.resume(with: .failure(NSError(domain: "AuthenticationError", code: 0, userInfo: nil)))
                            }
                        }
                    }
                }
            } catch {
                
                if self.forceAuthenticateOnRefreshError {
                    return try await self.performAuthentication()
                } else {
                    throw error
                }
            }
        }
        
        return try await self.performAuthentication()
    }
    
    private func performAuthorization(request: URLRequest, forceAuthenticate: Bool, handler: @escaping @Sendable @MainActor (URLRequest, Error?) -> Void) async {
        
        var handlerCalled = false
        
        let safeHandler: @Sendable @MainActor (URLRequest, Error?) -> Void = { request, error in
            guard !handlerCalled else { return }
            handlerCalled = true
            handler(request, error)
        }
        
        // Use cached token if available and valid
        if !forceAuthenticate, let response = self.accessTokenResponse, !response.isExpired {
            
            self.tokenAuthorizerProvider(response).authorize(request: request, handler: safeHandler)
            return
        }
        
        do {
            let response = try await self.authenticate(forced: forceAuthenticate)
            self.accessTokenResponse = response
            self.tokenAuthorizerProvider(response).authorize(request: request, handler: safeHandler)
        } catch {
            
            if self.retryAuthorizationOnAuthenticationError, error is ErrorResponse {
                
                await self.performAuthorization(request: request, forceAuthenticate: forceAuthenticate, handler: handler)
            } else {
                safeHandler(request, error)
            }
        }
    }
    
    //MARK: - IdentityManager
    
    open func authorize(request: URLRequest, forceAuthenticate: Bool, handler: @escaping  @Sendable @MainActor (URLRequest, Error?) -> Void) {
        
        queue.addOperation {
            let semaphore = DispatchSemaphore(value: 0)
            
            Task { @MainActor in
                await self.performAuthorization(request: request, forceAuthenticate: forceAuthenticate, handler: { request, error in
                    handler(request, error)
                    semaphore.signal()
                })
            }
            
            semaphore.wait()
        }
    }
    
    open func revokeAuthenticationState() {
        
        self.queue.addOperation {
            Task { @MainActor in
                self.accessTokenResponse = nil
            }
            
            //TODO: implement token revocation trough server
        }
    }
    
    open func revokeAuthorizationState() {
        
        self.queue.addOperation {
            Task { @MainActor in
                self.accessTokenResponse?.expiresIn = 0
            }
        }
    }
    
    open var responseValidator: NetworkResponseValidator = {
        
        struct PlaceholderIdentityManager: IdentityManager {
            
            func authorize(request: URLRequest, forceAuthenticate: Bool, handler: @escaping @Sendable @MainActor (URLRequest, Error?) -> Void) {}
            func revokeAuthenticationState() {}
            func revokeAuthorizationState() {}
            
            static let defaultResponseValidator = PlaceholderIdentityManager().responseValidator
        }
        
        return PlaceholderIdentityManager.defaultResponseValidator
    }()
}

extension OAuth2IdentityManager {
    
    /**
     Creates an instnce of the receiver when the access token is expected to be of a Bearer type with a specified authorization method.
     
     - parameter flow: An OAuth2 authorization grant flow used for authentication.
     - parameter refresher: An optional access token refresher, used to refresh an access token if expired and when possible.
     - parameter storage: An identity storage, used to store some state, like the refresh token.
     - parameter authorizationMethod: The authorization method used to authorize the requests. Default to `.header`
     
     */
    
    public convenience init(flow: AuthorizationGrantFlow, refresher: AccessTokenRefresher?, storage: IdentityStorage?, authorizationMethod: BearerAccessTokenAuthorizer.AuthorizationMethod = .header) {
        
        let tokenAuthorizerProvider = { (response: AccessTokenResponse) -> RequestAuthorizer in
            
            return BearerAccessTokenAuthorizer(token: response.accessToken, method: authorizationMethod)
        }
        
        self.init(flow: flow, refresher: refresher, storage: storage, tokenAuthorizerProvider: tokenAuthorizerProvider)
    }
}

extension OAuth2IdentityManager {
    
    public static let willAuthenticate = Notification.Name(rawValue: bundleIdentifier + ".OAuth2IdentityManager.willAuthenticate")
    public static let didAuthenticate = Notification.Name(rawValue: bundleIdentifier + ".OAuth2IdentityManager.didAuthenticate")
    public static let didFailToAuthenticate = Notification.Name(rawValue: bundleIdentifier + ".OAuth2IdentityManager.didFailToAuthenticate")
    
    public static let accessTokenResponseUserInfoKey = "accessTokenResponse"
    public static let errorUserInfoKey = "error"
    
    ///notify that authentication will begin
    func postWillAuthenticateNotification() {
        
        let notification = Notification(name: type(of: self).willAuthenticate, object: self, userInfo: nil)
        NotificationQueue.default.enqueue(notification, postingStyle: .now)
    }
    
    ///notify that authentication has finished
    func didFinishAuthenticating(with accessTokenResponse: AccessTokenResponse?, error: Error?) {
        
        var userInfo = [AnyHashable: Any]()
        userInfo[type(of: self).accessTokenResponseUserInfoKey] = accessTokenResponse
        userInfo[type(of: self).errorUserInfoKey] = error
        
        if error == nil {
            
            let notification = Notification(name: type(of: self).didAuthenticate, object: self, userInfo: userInfo)
            NotificationQueue.default.enqueue(notification, postingStyle: .now)
        }
        else {
            
            let notification = Notification(name: type(of: self).didFailToAuthenticate, object: self, userInfo: userInfo)
            NotificationQueue.default.enqueue(notification, postingStyle: .now)
        }
    }
}
@MainActor
extension Notification.Name {
    
    public static let OAuth2IdentityManagerWillAuthenticate = OAuth2IdentityManager.willAuthenticate
    public static let OAuth2IdentityManagerDidAuthenticate = OAuth2IdentityManager.didAuthenticate
    public static let OAuth2IdentityManagerDidFailToAuthenticate = OAuth2IdentityManager.didFailToAuthenticate
}

extension IdentityStorage {
    
    private var refreshTokenKey: String {
        
        return bundleIdentifier + ".OAuth2IdentityManager.refresh_token"
    }
    
    fileprivate var refreshToken: String? {
        
        get {
            
            return self[refreshTokenKey]
        }
        
        set {
            
            self[refreshTokenKey] = newValue
        }
    }
}

extension IdentityStorage {
    
    private var scopeValueKey: String {
        
        return bundleIdentifier + ".OAuth2IdentityManager.scope_value"
    }
    
    fileprivate var scope: Scope? {
        
        get {
            
            guard let value = self[scopeValueKey] else {
                
                return nil
            }
            
            return Scope(value: value)
        }
        
        set {
            
            self[scopeValueKey] = newValue?.value
        }
    }
}
