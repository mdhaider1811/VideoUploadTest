//
//  AuthenticationController.swift
//  VimeoNetworkingExample-iOS
//
//  Created by Huebner, Rob on 3/21/16.
//  Copyright © 2016 Vimeo. All rights reserved.
//

import Foundation

/**
 `AuthenticationController` is used to authenticate a `VimeoClient` instance, either by loading an account stored in the system keychain, or by interacting with the Vimeo API to authenticate a new account.  The two publicly accessible authentication methods are client credentials grant and code grant.  
 
 Client credentials grant is a public authentication method with no logged in user, which allows your application to access anything a logged out user could see on Vimeo (public content).  
 
 Code grant is a way of logging in with a user account, which can give your application access to that user's private content and permission to interact with Vimeo on their behalf.  This is achieved by first opening a generated URL in Safari which presents a user log in page.  When the user authenticates successfully, control is returned to your app through a redirect link, and you then make a final request to retrieve the authenticated account.
 
 - Note: This class contains implementation details of private Vimeo-internal authentication methods in addition to the public authentication methods mentioned above.  However, only client credentials grant and code grant authentication are supported for 3rd-party applications interacting with Vimeo.  None of the other authentication endpoints are enabled for non-official applications, nor will they ever be, so please don't attempt to use them.  Perhaps you're thinking, "Why are they here at all, then?"  Well, Vimeo's official applications use this very same library to interact with the Vimeo API, and this, more than anything, is what keeps `VimeoNetworking` healthy and well-maintained :).
 */
final public class AuthenticationController
{
    /// The domain for errors generated by `AuthenticationController`
    static let ErrorDomain = "AuthenticationControllerErrorDomain"
    
    private static let ResponseTypeKey = "response_type"
    private static let CodeKey = "code"
    private static let ClientIDKey = "client_id"
    private static let RedirectURIKey = "redirect_uri"
    private static let ScopeKey = "scope"
    private static let StateKey = "state"
    
    private static let CodeGrantAuthorizationPath = "oauth/authorize"
    
    private static let PinCodeRequestInterval: NSTimeInterval = 5
    
        /// Completion closure type for authentication requests
    public typealias AuthenticationCompletion = ResultCompletion<VIMAccount>.T
    
        /// State is tracked for the code grant request/response cycle, to avoid interception
    static let state = NSProcessInfo.processInfo().globallyUniqueString
    
        /// Application configuration used to retrieve authentication parameters
    private let configuration: AppConfiguration
    
        /// External client, authenticated on a successful request
    private let client: VimeoClient
    
        /// We need to use a separate client to make the actual auth requests, to ensure it's unauthenticated
    private let authenticatorClient: VimeoClient
    
        /// Persists authenticated accounts to disk
    private let accountStore: AccountStore
    
        /// Set to false to stop the refresh cycle for pin code auth
    private var continuePinCodeAuthorizationRefreshCycle = true
    
    /**
     Create a new `AuthenticationController`
     
     - parameter client: a client to authenticate
     
     - returns: a new `AuthenticationController`
     */
    public init(client: VimeoClient)
    {
        self.configuration = client.configuration
        self.client = client
        self.accountStore = AccountStore(configuration: client.configuration)
        
        self.authenticatorClient = VimeoClient(appConfiguration: client.configuration)
    }
    
    // MARK: - Public Saved Accounts
    
    public func loadClientCredentialsAccount() throws -> VIMAccount?
    {
        return try self.loadAccount(.ClientCredentials)
    }

    public func loadUserAccount() throws -> VIMAccount?
    {
        return try self.loadAccount(.User)
    }
    
    @available(*, deprecated, message="Use loadUserAccount or loadClientCredentialsAccount instead.")
    /**
     Load a saved User or Client credentials account from the `AccountStore`
     
     - throws: an error if storage returns a failure
     
     - returns: an account, if found
     */
    public func loadSavedAccount() throws -> VIMAccount?
    {
        var loadedAccount = try self.loadUserAccount()
        
        if loadedAccount == nil
        {
            loadedAccount = try self.loadClientCredentialsAccount()
        }
        
        if loadedAccount != nil
        {
            // TODO: refresh user [RH] (4/25/16)
            
            // TODO: after refreshing user, send notification [RH] (4/25/16)
        }
        
        return loadedAccount
    }
    
    // MARK: - Private Saved Accounts
    
    private func loadAccount(accountType: AccountStore.AccountType) throws -> VIMAccount?
    {
        let loadedAccount = try self.accountStore.loadAccount(accountType)
        
        if let loadedAccount = loadedAccount
        {
            print("Loaded \(accountType) account \(loadedAccount)")

            try self.setClientAccount(with: loadedAccount)
        }
        else
        {
            print("Failed to load \(accountType) account")
        }
        
        return loadedAccount
    }

    // MARK: - Public Authentication
    
    /**
     Execute a client credentials grant request.  This type of authentication allows access to public content on Vimeo.
     
     - parameter completion: handles authentication success or failure
     */
    public func clientCredentialsGrant(completion: AuthenticationCompletion)
    {
        let request = AuthenticationRequest.clientCredentialsGrantRequest(scopes: self.configuration.scopes)
        
        self.authenticate(request: request, completion: completion)
    }
    
        /// Returns the redirect URI used to launch this application after code grant authorization
    public var codeGrantRedirectURI: String
    {
        let scheme = "vimeo\(self.configuration.clientIdentifier)"
        let path = "auth"
        let URI = "\(scheme)://\(path)"
        
        return URI
    }
    
    /**
     Generate a URL to open the Vimeo code grant authorization page.  When opened in Safari, this page allows users to log into your application.
     
     - returns: the code grant authorization page URL
     */
    public func codeGrantAuthorizationURL() -> NSURL
    {
        let parameters = [self.dynamicType.ResponseTypeKey: self.dynamicType.CodeKey,
                          self.dynamicType.ClientIDKey: self.configuration.clientIdentifier,
                          self.dynamicType.RedirectURIKey: self.codeGrantRedirectURI,
                          self.dynamicType.ScopeKey: Scope.combine(self.configuration.scopes),
                          self.dynamicType.StateKey: self.dynamicType.state]
        
        guard let urlString = VimeoBaseURLString?.URLByAppendingPathComponent(self.dynamicType.CodeGrantAuthorizationPath)!.absoluteString
        else
        {
            fatalError("Could not make code grant auth URL")
        }
        
        var error: NSError?
        let urlRequest = VimeoRequestSerializer(appConfiguration: self.configuration).requestWithMethod(VimeoClient.Method.GET.rawValue, URLString: urlString, parameters: parameters, error: &error)
        
        guard let url = urlRequest.URL where error == nil
        else
        {
            fatalError("Could not make code grant auth URL")
        }
        
        return url
    }
    
    /**
     Finish code grant authentication.  This function initiates the final step of the code grant process.  After your application is relaunched with the redirect URL, make this request with the response URL to retrieve the authenticated account.
     
     - parameter responseURL: the URL that was used to relaunch your application
     - parameter completion:  handler for authentication success or failure
     */
    public func codeGrant(responseURL responseURL: NSURL, completion: AuthenticationCompletion)
    {
        guard let queryString = responseURL.query,
            let parameters = queryString.parametersFromQueryString(),
            let code = parameters[self.dynamicType.CodeKey],
            let state = parameters[self.dynamicType.StateKey]
        else
        {
            let errorDescription = "Could not retrieve parameters from code grant response"
            
            assertionFailure(errorDescription)
            
            let error = NSError(domain: self.dynamicType.ErrorDomain, code: LocalErrorCode.CodeGrant.rawValue, userInfo: [NSLocalizedDescriptionKey: errorDescription])
            
            completion(result: .Failure(error: error))
            
            return
        }
        
        if state != self.dynamicType.state
        {
            let errorDescription = "Code grant returned state did not match existing state"
            
            assertionFailure(errorDescription)
            
            let error = NSError(domain: self.dynamicType.ErrorDomain, code: LocalErrorCode.CodeGrantState.rawValue, userInfo: [NSLocalizedDescriptionKey: errorDescription])
            
            completion(result: .Failure(error: error))
            
            return
        }
        
        let request = AuthenticationRequest.codeGrantRequest(code: code, redirectURI: self.codeGrantRedirectURI)
        
        self.authenticate(request: request, completion: completion)
    }
    
    /**
     Execute a constant token grant request. This type of authentication allows access to public and personnal content on Vimeo. Constant token are usually generated for API apps see https://developer.vimeo.com/apps
     
     - parameter token: a constant token generated for your api's app
     - parameter completion: handles authentication success or failure
     */
    public func accessToken(token: String, completion: AuthenticationCompletion)
    {
        let customSessionManager =  VimeoSessionManager.defaultSessionManager(accessTokenProvider: {token})
        let adhocClient = VimeoClient(appConfiguration: self.configuration, sessionManager: customSessionManager)
        let request = AuthenticationRequest.verifyAccessTokenRequest()

        self.authenticate(adhocClient, request: request, completion: completion)
    }
    
    // MARK: - Private Authentication
    
    /**
     **(PRIVATE: Vimeo Use Only, will not work for third-party applications)**
     Log in with an email and password
     
     - parameter email:      a user's email
     - parameter password:   a user's password
     - parameter completion: handler for authentication success or failure
     */
    public func logIn(email email: String, password: String, completion: AuthenticationCompletion)
    {
        let request = AuthenticationRequest.logInRequest(email: email, password: password, scopes: self.configuration.scopes)
        
        self.authenticate(request: request, completion: completion)
    }
    
    /**
     **(PRIVATE: Vimeo Use Only, will not work for third-party applications)**
     Join with a username, email, and password
     
     - parameter name:       the new user's name
     - parameter email:      the new user's email
     - parameter password:   the new user's password
     - parameter completion: handler for authentication success or failure
     */
    public func join(name name: String, email: String, password: String, completion: AuthenticationCompletion)
    {
        let request = AuthenticationRequest.joinRequest(name: name, email: email, password: password, scopes: self.configuration.scopes)
        
        self.authenticate(request: request, completion: completion)
    }
    
    /**
     **(PRIVATE: Vimeo Use Only, will not work for third-party applications)**
     Log in with a facebook token
     
     - parameter facebookToken: token from facebook SDK
     - parameter completion:    handler for authentication success or failure
     */
    public func facebookLogIn(facebookToken facebookToken: String, completion: AuthenticationCompletion)
    {
        let request = AuthenticationRequest.logInFacebookRequest(facebookToken: facebookToken, scopes: self.configuration.scopes)
        
        self.authenticate(request: request, completion: completion)
    }
    
    /**
     **(PRIVATE: Vimeo Use Only, will not work for third-party applications)**
     Join with a facebook token
     
     - parameter facebookToken: token from facebook SDK
     - parameter completion:    handler for authentication success or failure
     */
    public func facebookJoin(facebookToken facebookToken: String, completion: AuthenticationCompletion)
    {
        let request = AuthenticationRequest.joinFacebookRequest(facebookToken: facebookToken, scopes: self.configuration.scopes)
        
        self.authenticate(request: request, completion: completion)
    }
    
    /**
     **(PRIVATE: Vimeo Use Only, will not work for third-party applications)**
     Exchange a saved access token granted to another application for a new token granted to the calling application.  This method will allow an application to re-use credentials from another Vimeo application.  Client credentials must be granted before using this method. 
     
     - parameter accessToken: access token granted to the other application
     - parameter completion:  handler for authentication success or failure
     */
    public func appTokenExchange(accessToken accessToken: String, completion: AuthenticationCompletion)
    {
        let request = AuthenticationRequest.appTokenExchangeRequest(accessToken: accessToken)
        
        self.authenticate(request: request, completion: completion)
    }
    
    
        /// **(PRIVATE: Vimeo Use Only)** Handles the initial information to present to the user for pin code auth
    public typealias PinCodeInfoHander = (pinCode: String, activateLink: String) -> Void
    
    /**
     **(PRIVATE: Vimeo Use Only, will not work for third-party applications)**
     Pin code authentication, for connected but keyboardless devices like Apple TV.  This is a long and highly asynchronous process where the user is initially presented a pin code, which they then enter into a special page on Vimeo.com on a different device.  Back on the original device, the app is polling the api to check whether the pin code has been authenticated.  The `infoHandler` will be called after an initial request to retrieve the pin code and activate link.  `AuthenticationController` will handle polling the api to check if the code has been activated, and it will ultimately call the completion handler when that happens.  If the pin code expires while we're waiting, completion will be called with an error
     
     - parameter infoHandler: handler for initial information presentation
     - parameter completion:  handler for authentication success or failure
     */
    public func pinCode(infoHandler infoHandler: PinCodeInfoHander, completion: AuthenticationCompletion)
    {
        let infoRequest = PinCodeRequest.getPinCodeRequest(scopes: self.configuration.scopes)
        
        self.authenticatorClient.request(infoRequest) { result in
            switch result
            {
            case .Success(let result):
                
                let info = result.model
                
                guard let userCode = info.userCode,
                    let deviceCode = info.deviceCode,
                    let activateLink = info.activateLink
                    where info.expiresIn > 0
                else
                {
                    let errorDescription = "Malformed pin code info returned"
                    
                    assertionFailure(errorDescription)
                    
                    let error = NSError(domain: self.dynamicType.ErrorDomain, code: LocalErrorCode.PinCodeInfo.rawValue, userInfo: [NSLocalizedDescriptionKey: errorDescription])
                    
                    completion(result: .Failure(error: error))
                    
                    return
                }
                
                infoHandler(pinCode: userCode, activateLink: activateLink)
                
                let expirationDate = NSDate(timeIntervalSinceNow: NSTimeInterval(info.expiresIn))
                
                self.continuePinCodeAuthorizationRefreshCycle = true
                self.doPinCodeAuthorization(userCode: userCode, deviceCode: deviceCode, expirationDate: expirationDate, completion: completion)
                
            case .Failure(let error):
                completion(result: .Failure(error: error))
            }
        }
    }
    
    private func doPinCodeAuthorization(userCode userCode: String, deviceCode: String, expirationDate: NSDate, completion: AuthenticationCompletion)
    {
        guard NSDate().compare(expirationDate) == .OrderedAscending
        else
        {
            let description = "Pin code expired"
            
            let error = NSError(domain: self.dynamicType.ErrorDomain, code: LocalErrorCode.PinCodeExpired.rawValue, userInfo: [NSLocalizedDescriptionKey: description])
            
            completion(result: .Failure(error: error))
            
            return
        }
        
        let authorizationRequest = AuthenticationRequest.authorizePinCodeRequest(userCode: userCode, deviceCode: deviceCode)
        
        self.authenticate(request: authorizationRequest) { [weak self] result in
            
            switch result
            {
            case .Success:
                completion(result: result)
                
            case .Failure(let error):
                if error.statusCode == HTTPStatusCode.BadRequest.rawValue // 400: Bad Request implies the code hasn't been activated yet, so try again.
                {
                    guard let strongSelf = self
                        else
                    {
                        return
                    }
                    
                    if strongSelf.continuePinCodeAuthorizationRefreshCycle
                    {
                        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(strongSelf.dynamicType.PinCodeRequestInterval * NSTimeInterval(NSEC_PER_SEC))), dispatch_get_main_queue()) { [weak self] in
                            
                            self?.doPinCodeAuthorization(userCode: userCode, deviceCode: deviceCode, expirationDate: expirationDate, completion: completion)
                        }
                    }
                }
                else // Any other error is an actual error, and should get reported back.
                {
                    completion(result: result)
                }
            }
        }
    }
    
    /**
     **(PRIVATE: Vimeo Use Only, will not work for third-party applications)**
     Cancels an ongoing pin code authentication process
     */
    public func cancelPinCode()
    {
        self.continuePinCodeAuthorizationRefreshCycle = false
    }
    
    // MARK: - Log out
    
    /**
     Log out the account of the client

     - parameter loadClientCredentials: if true, tries to load a client credentials account from the keychain after logging out
     
     - throws: an error if the account could not be deleted from the keychain
     */
    public func logOut(loadClientCredentials loadClientCredentials: Bool = true) throws
    {
        guard self.client.isAuthenticatedWithUser == true
        else
        {
            return
        }
        
        let deleteTokensRequest = Request<VIMNullResponse>.deleteTokensRequest()
        self.client.request(deleteTokensRequest) { (result) in
            switch result
            {
            case .Success:
                break
            case .Failure(let error):
                print("could not delete tokens: \(error)")
            }
        }
        
        if loadClientCredentials
        {
            let loadedClientCredentialsAccount = (try? self.accountStore.loadAccount(.ClientCredentials)) ?? nil
            try self.setClientAccount(with: loadedClientCredentialsAccount, shouldClearCache: true)
        }
        else
        {
            try self.setClientAccount(with: nil, shouldClearCache: true)
        }
        
        try self.accountStore.removeAccount(.User)
    }
    
    // MARK: - Private
    
    private func authenticate(request request: AuthenticationRequest, completion: AuthenticationCompletion)
    {
        self.authenticate(self.authenticatorClient, request: request, completion: completion)
    }
    
    private func authenticate(client: VimeoClient, request: AuthenticationRequest, completion: AuthenticationCompletion)
    {
        client.request(request) { result in
            
            let handledResult = self.handleAuthenticationResult(result)
            
            completion(result: handledResult)
        }
    }
    
    
    private func handleAuthenticationResult(result: Result<Response<VIMAccount>>) -> Result<VIMAccount>
    {
        guard case .Success(let accountResponse) = result
        else
        {
            let resultError: NSError
            if case .Failure(let error) = result
            {
                resultError = error
            }
            else
            {
                let errorDescription = "Authentication result malformed"
                
                assertionFailure(errorDescription)
                
                resultError = NSError(domain: self.dynamicType.ErrorDomain, code: LocalErrorCode.NoResponse.rawValue, userInfo: [NSLocalizedDescriptionKey: errorDescription])
            }
            
            return .Failure(error: resultError)
        }
        
        let account = accountResponse.model
        
        if let userJSON = accountResponse.json["user"] as? VimeoClient.ResponseDictionary
        {
            account.userJSON = userJSON
        }
        
        do
        {
            try self.setClientAccount(with: account, shouldClearCache: true)
            
            let accountType: AccountStore.AccountType = (account.user != nil) ? .User : .ClientCredentials
            
            try self.accountStore.saveAccount(account, type: accountType)
        }
        catch let error
        {
            return .Failure(error: error as NSError)
        }
        
        return .Success(result: account)
    }
    
    private func setClientAccount(with account: VIMAccount?, shouldClearCache: Bool = false) throws
    {
        // Account can be nil (to log out) but if it's non-nil, it needs an access token or it's malformed [RH]
        guard account == nil || account?.accessToken != nil
        else
        {
            let errorDescription = "AuthenticationController tried to set a client account with no access token"
            
            assertionFailure(errorDescription)
            
            let error = NSError(domain: self.dynamicType.ErrorDomain, code: LocalErrorCode.AuthToken.rawValue, userInfo: [NSLocalizedDescriptionKey: errorDescription])
            
            throw error
        }
        
        if shouldClearCache
        {
            self.client.removeAllCachedResponses()
        }
        
        self.client.currentAccount = account
    }
}
