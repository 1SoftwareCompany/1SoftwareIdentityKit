//
//  IdentityStorageTests.swift
//  EldersIdentityKit
//
//  Created by Milen Halachev on 6/2/17.
//  Copyright © 2017 Milen Halachev. All rights reserved.
//

import Foundation
import XCTest
@testable import EldersIdentityKit

class IdentityStorageTests: XCTestCase {
    
    func testInMemoryIdentityStorage() {
        
        let storage: IdentityStorage = InMemoryIdentityStorage()
        
        storage.set(nil, forKey: "gg5")
        XCTAssertNil(storage.value(forKey: "gg5"))
        
        storage.set("tv", forKey: "tk")
        XCTAssertEqual(storage.value(forKey: "tk"), "tv")
        XCTAssertNil(storage.value(forKey: "tk2"))
        
        storage.set("tv5", forKey: "tk")
        XCTAssertEqual(storage.value(forKey: "tk"), "tv5")
        
        storage.set(nil, forKey: "tk")
        XCTAssertNil(storage.value(forKey: "tk"))
    }
    
    func testKeychainIdentityStorage() {
        
        let storage: IdentityStorage = KeychainIdentityStorage(service: "test")
        
        storage.set(nil, forKey: "gg5")
        XCTAssertNil(storage.value(forKey: "gg5"))
        
        storage.set("tv", forKey: "tk")
        XCTAssertEqual(storage.value(forKey: "tk"), "tv")
        XCTAssertNil(storage.value(forKey: "tk2"))
        
        storage.set("tv5", forKey: "tk")
        XCTAssertEqual(storage.value(forKey: "tk"), "tv5")
        
        storage.set(nil, forKey: "tk")
        XCTAssertNil(storage.value(forKey: "tk"))
    }
    
    func testKeychainAccessGroupStorage() {
        
        let storage: IdentityStorage = KeychainIdentityStorage(service: "test", accessGroup: nil)
        
        // test nil set
        storage.set(nil, forKey: "k1")
        XCTAssertNil(storage.value(forKey: "k1"))
        
        // test set
        storage.set("v1", forKey: "k1")
        XCTAssertEqual(storage.value(forKey: "k1"), "v1")
        XCTAssertNil(storage.value(forKey: "k0"))
        
        // test override
        storage.set("v2", forKey: "k1")
        XCTAssertEqual(storage.value(forKey: "k1"), "v2")
        
        // test delete
        storage.set(nil, forKey: "k1")
        XCTAssertNil(storage.value(forKey: "k1"))
    }
    
    #if !os(macOS)
    // App Groups behave differently on macOS so we don't expect this test to work the same as on iOS targets
    // System Extension app-group entitlement explanation - https://developer.apple.com/forums/thread/133677?answerId=422887022#422887022
    func testKeychainMissingAccessGroupStorage() {
        
        // test set missing entitlements access group
        let storage: IdentityStorage = KeychainIdentityStorage(service: "test", accessGroup: "group1")
        
        storage.set("v1", forKey: "k1")
        XCTAssertNil(storage.value(forKey: "k1"))
    }
    #endif
}
