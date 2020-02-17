//
//  TokenKeychainStore.swift
//  DOITTestApp
//
//  Created by Kirill Andreyev on 2/15/20.
//  Copyright © 2020 Kirill Andreyev. All rights reserved.
//

import KeychainAccess

public class TokenKeychainStore {
    private let keychain: Keychain
    
    public init(service: String = "com.doit.DOITTestApp") {
        self.keychain = Keychain(service: service)
    }
    
    public func storeAccessToken(_ accessToken:Token?) {
        if let token = accessToken {
            keychain[Constants.userAuthToken] = token.id
            keychain[Constants.tokenValidUntil] = String(token.validUntil.timeIntervalSince1970)
        }
    }
    
    public func clearAccessToken() {
        do {
            try keychain.removeAll()
        } catch let error {
            print(error)
        }
    }
    
    public func retrieveAccessToken() -> Token? {
        
        guard let id = keychain[Constants.userAuthToken],
            let dateStr = keychain[Constants.tokenValidUntil],
            let time = Double(dateStr)
            else {
                return nil
        }
        
        let date = Date(timeIntervalSince1970: time)
        if date.compare(Date()) != .orderedAscending {
            return Token(
                id: id,
                validUntil: date
            )
        }
        else {
            self.clearAccessToken()
        }
        
        return nil
    }
}

