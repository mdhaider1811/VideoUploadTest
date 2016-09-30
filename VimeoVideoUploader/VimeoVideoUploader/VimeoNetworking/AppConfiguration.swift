//
//  AppConfiguration.swift
//  VimeoNetworkingExample-iOS
//
//  Created by Huebner, Rob on 3/28/16.
//  Copyright © 2016 Vimeo. All rights reserved.
//

import Foundation

/**
 *  Stores all static information relevant to a client application
 */
public struct AppConfiguration
{
        /// Keychain identifier for the Vimeo application
    public static let KeychainServiceVimeo = "Vimeo"
    
        /// Keychain identifier for the Cameo application
    public static let KeychainServiceCameo = "Cameo"
    
    let clientIdentifier: String
    let clientSecret: String
    let scopes: [Scope]
    
    let keychainService: String
    let keychainAccessGroup: String?
    
    let apiVersion: String
    
    /**
     Create a new `AppConfiguration`
     
     - parameter clientIdentifier:           The client key designated by the api for your application
     - parameter clientSecret:        The client secret designated by the api for your application
     - parameter scopes:              An array of `Scope`s that your application requests
     - parameter keychainService:     Identifes your application to the system keychain, defaults to `KeychainServiceVimeo`
     - parameter keychainAccessGroup: Access group your application should use for the system keychain, defaults to nil
     - parameter apiVersion:          API version your requests should use, defaults to `VimeoDefaultAPIVersionString`
     
     - returns: an initialized AppConfiguration
     */
    public init(clientIdentifier: String,
                clientSecret: String,
                scopes: [Scope],
                keychainService: String = KeychainServiceVimeo,
                keychainAccessGroup: String? = nil,
                apiVersion: String = VimeoDefaultAPIVersionString)
    {
        self.clientIdentifier = clientIdentifier
        self.clientSecret = clientSecret
        self.scopes = scopes
        self.keychainService = keychainService
        self.keychainAccessGroup = keychainAccessGroup
        self.apiVersion = apiVersion
    }
}
