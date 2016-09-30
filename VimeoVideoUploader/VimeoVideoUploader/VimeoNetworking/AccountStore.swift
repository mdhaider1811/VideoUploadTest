//
//  AccountStore.swift
//  VimeoNetworkingExample-iOS
//
//  Created by Huebner, Rob on 3/24/16.
//  Copyright © 2016 Vimeo. All rights reserved.
//

import Foundation

/// `AccountStore` handles saving and loading authenticated accounts securely using the keychain
final class AccountStore
{
    /// `AccountType` categorizes an account based on its level of access
    enum AccountType: String
    {
        /// Client credentials accounts can access only public resources
        case ClientCredentials
        
        /// User accounts have an authenticated user and can act on the user's behalf
        case User
    }
    
    // MARK: - 
    
    private static let ErrorDomain = "AccountStoreErrorDomain"
    
    // MARK: - 
    
    private let dataStore: SecureDataStore
    
    // MARK: -
    
    /**
     Create a new account store
     
     - parameter configuration: your application's configuration
     
     - returns: an initialized `AccountStore`
     */
    init(configuration: AppConfiguration)
    {
        self.dataStore = KeychainStore(service: configuration.keychainService, accessGroup: configuration.keychainAccessGroup)
    }
    
    // MARK: -
    
    /**
     Save an account
     
     - parameter account: the account to save
     - parameter type:    the type of the account
     
     - throws: an error if the data could not be saved
     */
    func saveAccount(account: VIMAccount, type: AccountType) throws
    {
        let data = NSMutableData()
        let archiver = NSKeyedArchiver(forWritingWithMutableData: data)
        archiver.encodeObject(account)
        archiver.finishEncoding()
        
        try self.dataStore.setData(data, forKey: type.rawValue)
    }
    
    /**
     Load an account
     
     - parameter type: type of account requested
     
     - throws: an error if data could not be loaded
     
     - returns: an account of the specified type, if one was found
     */
    func loadAccount(type: AccountType) throws -> VIMAccount?
    {
        do
        {
            guard let data = try self.dataStore.dataForKey(type.rawValue)
            else
            {
                return nil
            }
            
            let unarchiver = NSKeyedUnarchiver(forReadingWithData: data)
            var decodedAccount: VIMAccount? = nil
            try ExceptionCatcher.doUnsafe
            {
                decodedAccount = unarchiver.decodeObject() as? VIMAccount
            }
            
            guard let account = decodedAccount
            else
            {
                let description = "Received corrupted VIMAccount data from keychain"
                let error = NSError(domain: self.dynamicType.ErrorDomain, code: LocalErrorCode.AccountCorrupted.rawValue, userInfo: [NSLocalizedDescriptionKey: description])
                
                throw error
            }
            
            if let userJSON = account.userJSON as? VimeoClient.ResponseDictionary
            {
                try account.user = VIMObjectMapper.mapObject(userJSON) as VIMUser
            }
            
            return account
        }
        catch let error
        {
            _ = try? self.removeAccount(type)
            
            throw error
        }
    }
    
    /**
     Removes a saved account
     
     - parameter type: type of account to remove
     
     - throws: an error if the data exists but could not be removed
     */
    func removeAccount(type: AccountType) throws
    {
        try self.dataStore.deleteDataForKey(type.rawValue)
    }
}