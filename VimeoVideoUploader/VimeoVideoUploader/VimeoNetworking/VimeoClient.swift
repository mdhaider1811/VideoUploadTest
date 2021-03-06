//
//  VimeoClient.swift
//  VimeoNetworkingExample-iOS
//
//  Created by Huebner, Rob on 3/21/16.
//  Copyright © 2016 Vimeo. All rights reserved.
//

import Foundation

/// `VimeoClient` handles a rich assortment of functionality focused around interacting with the Vimeo API.  A client object tracks an authenticated account, handles the low-level execution of requests through a session manager with caching functionality, presents a high-level `Request` and `Response` interface, and notifies of globally relevant events and errors through `Notification`s
/// 
/// To start using a client, first instantiate an `AuthenticationController` to load a stored account or authenticate a new one.  Next, create `Request` instances and pass them into the `request` function, which returns `Response`s on success.

final public class VimeoClient
{
    // MARK: - 
    
    /// HTTP methods available for requests
    public enum Method: String
    {
        /// Retrieve a resource
        case GET
        
        /// Create a new resource
        case POST
        
        /// Set a resource
        case PUT
        
        /// Update a resource
        case PATCH
        
        /// Remove a resource
        case DELETE
    }
    
    /**
     *  `RequestToken` stores a reference to an in-flight request
     */
    public struct RequestToken
    {
        private let task: NSURLSessionDataTask?
        
        /**
         Cancel the request
         */
        public func cancel()
        {
            self.task?.cancel()
        }
    }
    
        /// Dictionary containing URL parameters for a request
    public typealias RequestParameters = [String: AnyObject]
    
        /// Dictionary containing a JSON response
    public typealias ResponseDictionary = [String: AnyObject]
    
        /// Domain for errors generated by `VimeoClient`
    static let ErrorDomain = "VimeoClientErrorDomain"
    
    // MARK: -
    
    private static let PagingKey = "paging"
    private static let TotalKey = "total"
    private static let PageKey = "page"
    private static let PerPageKey = "per_page"
    private static let NextKey = "next"
    private static let PreviousKey = "previous"
    private static let FirstKey = "first"
    private static let LastKey = "last"
    
    // MARK: -
    
        /// Session manager handles the http session data tasks and request/response serialization
    private let sessionManager: VimeoSessionManager
    
        /// response cache handles all memory and disk caching of response dictionaries
    private let responseCache = ResponseCache()
    
    /**
     Create a new client
     
     - parameter appConfiguration: Your application's configuration
     
     - returns: an initialized `VimeoClient`
     */
    convenience public init(appConfiguration: AppConfiguration)
    {
        self.init(appConfiguration: appConfiguration, sessionManager: VimeoSessionManager.defaultSessionManager(appConfiguration: appConfiguration))
    }
    
    public init(appConfiguration: AppConfiguration, sessionManager: VimeoSessionManager)
    {
        self.configuration = appConfiguration
        self.sessionManager = sessionManager
    }
    
    // MARK: - Configuration
    
        /// The client's configuration, as set on initialization
    public let configuration: AppConfiguration
    
    // MARK: - Authentication
    
        /// Stores the current account, if one exists
    public internal(set) var currentAccount: VIMAccount?
    {
        didSet
        {
            if let authenticatedAccount = self.currentAccount
            {
                self.sessionManager.clientDidAuthenticateWithAccount(authenticatedAccount)
            }
            else
            {
                self.sessionManager.clientDidClearAccount()
            }
            
            Notification.AuthenticatedAccountDidChange.post(object: self.currentAccount)
        }
    }
    
        /// Returns the current authenticated user, if one exists
    public var authenticatedUser: VIMUser?
    {
        return self.currentAccount?.user
    }
    
        /// Returns true if the current account exists and is authenticated
    public var isAuthenticated: Bool
    {
        return self.currentAccount?.isAuthenticated() ?? false
    }
    
        /// Returns true if the current account exists, is authenticated, and is of type User
    public var isAuthenticatedWithUser: Bool
    {
        return self.currentAccount?.isAuthenticatedWithUser() ?? false
    }
    
        /// Returns true if the current account exists, is authenticated, and is of type ClientCredentials
    public var isAuthenticatedWithClientCredentials: Bool
    {
        return self.currentAccount?.isAuthenticatedWithClientCredentials() ?? false
    }
    
    // MARK: - Request
    
    /**
     Executes a `Request`
    
     - parameter request:         `Request` object containing all the required URL and policy information
     - parameter completionQueue: dispatch queue on which to execute the completion closure
     - parameter completion:      a closure executed one or more times, containing a `Result`
     
     - returns: a `RequestToken` for the in-flight request
     */
    public func request<ModelType: MappableResponse>(request: Request<ModelType>, completionQueue: dispatch_queue_t = dispatch_get_main_queue(), completion: ResultCompletion<Response<ModelType>>.T) -> RequestToken
    {
        var networkRequestCompleted = false
        
        switch request.cacheFetchPolicy
        {
        case .CacheOnly, .CacheThenNetwork:
            
            self.responseCache.responseForRequest(request) { result in
                
                if networkRequestCompleted
                {
                    // If the network request somehow completes before the cache, abort any cache action [RH] (4/21/16)
                    
                    return
                }
                
                switch result
                {
                case .Success(let responseDictionary):
                    
                    if let responseDictionary = responseDictionary
                    {
                        self.handleTaskSuccess(request: request, task: nil, responseObject: responseDictionary, isCachedResponse: true, isFinalResponse: request.cacheFetchPolicy == .CacheOnly, completionQueue: completionQueue, completion: completion)
                    }
                    else if request.cacheFetchPolicy == .CacheOnly
                    {
                        let description = "Cached response not found"
                        let error = NSError(domain: self.dynamicType.ErrorDomain, code: LocalErrorCode.CachedResponseNotFound.rawValue, userInfo: [NSLocalizedDescriptionKey: description])
                        
                        self.handleError(error, request: request)
                        
                        dispatch_async(completionQueue)
                        {
                            completion(result: .Failure(error: error))
                        }
                    }
                    else
                    {
                        // no action required for a cache miss with a network request pending [RH]
                    }
                    
                case .Failure(let error):
                    
                    print("cache failure: \(error)")
                    
                    self.handleError(error, request: request)
                    
                    if request.cacheFetchPolicy == .CacheOnly
                    {
                        dispatch_async(completionQueue)
                        {
                            completion(result: .Failure(error: error))
                        }
                    }
                    else
                    {
                        // no action required for a cache error with a network request pending [RH]
                    }
                }
            }
            
            if request.cacheFetchPolicy == .CacheOnly
            {
                return RequestToken(task: nil)
            }
            
        case .NetworkOnly, .TryNetworkThenCache:
            break
        }
        
        let urlString = request.path
        let parameters = request.parameters
        
        let success: (NSURLSessionDataTask, AnyObject?) -> Void = { (task, responseObject) in
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)) {
                networkRequestCompleted = true
                self.handleTaskSuccess(request: request, task: task, responseObject: responseObject, completionQueue: completionQueue, completion: completion)
            }
        }
        
        let failure: (NSURLSessionDataTask?, NSError) -> Void = { (task, error) in
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)) {
                networkRequestCompleted = true
                self.handleTaskFailure(request: request, task: task, error: error, completionQueue: completionQueue, completion: completion)
            }
        }
        
        let task: NSURLSessionDataTask?
        
        switch request.method
        {
        case .GET:
            task = self.sessionManager.GET(urlString, parameters: parameters, success: success, failure: failure)
        case .POST:
            task = self.sessionManager.POST(urlString, parameters: parameters, success: success, failure: failure)
        case .PUT:
            task = self.sessionManager.PUT(urlString, parameters: parameters, success: success, failure: failure)
        case .PATCH:
            task = self.sessionManager.PATCH(urlString, parameters: parameters, success: success, failure: failure)
        case .DELETE:
            task = self.sessionManager.DELETE(urlString, parameters: parameters, success: success, failure: failure)
        }
        
        guard let requestTask = task
        else
        {
            let description = "Session manager did not return a task"
            
            assertionFailure(description)
            
            let error = NSError(domain: self.dynamicType.ErrorDomain, code: LocalErrorCode.RequestMalformed.rawValue, userInfo: [NSLocalizedDescriptionKey: description])
            
            networkRequestCompleted = true
            
            self.handleTaskFailure(request: request, task: task, error: error, completionQueue: completionQueue, completion: completion)
            
            return RequestToken(task: nil)
        }
        
        return RequestToken(task: requestTask)
    }
    
    /**
     Removes any cached responses for a given `Request`
     
     - parameter request: the `Request` for which to remove all cached responses
     */
    public func removeCachedResponse<ModelType: MappableResponse>(for request: Request<ModelType>)
    {
        self.responseCache.removeResponseForRequest(request)
    }
    
    /**
     Clears a client's cache of all stored responses
     */
    public func removeAllCachedResponses()
    {
        self.responseCache.clear()
    }
    
    // MARK: - Private task completion handlers
    
    private func handleTaskSuccess<ModelType: MappableResponse>(request request: Request<ModelType>, task: NSURLSessionDataTask?, responseObject: AnyObject?, isCachedResponse: Bool = false, isFinalResponse: Bool = true, completionQueue: dispatch_queue_t, completion: ResultCompletion<Response<ModelType>>.T)
    {
        guard let responseDictionary = responseObject as? ResponseDictionary
        else
        {
            if ModelType.self == VIMNullResponse.self
            {
                let nullResponseObject = VIMNullResponse()
                
                // Swift complains that this cast always fails, but it doesn't seem to ever actually fail, and it's required to call completion with this response [RH] (4/12/2016)
                // It's also worth noting that (as of writing) there's no way to direct the compiler to ignore specific instances of warnings in Swift :S [RH] (4/13/16)
                let response = Response(model: nullResponseObject, json: [:]) as! Response<ModelType>

                dispatch_async(completionQueue)
                {
                    completion(result: .Success(result: response as Response<ModelType>))
                }
            }
            else
            {
                let description = "VimeoClient requestSuccess returned invalid/absent dictionary"
                
                assertionFailure(description)
                
                let error = NSError(domain: self.dynamicType.ErrorDomain, code: LocalErrorCode.InvalidResponseDictionary.rawValue, userInfo: [NSLocalizedDescriptionKey: description])
                
                self.handleTaskFailure(request: request, task: task, error: error, completionQueue: completionQueue, completion: completion)
            }
            
            return
        }
        
        do
        {
            let modelObject: ModelType = try VIMObjectMapper.mapObject(responseDictionary, modelKeyPath: request.modelKeyPath)
            
            var response: Response<ModelType>
            
            if let pagingDictionary = responseDictionary[self.dynamicType.PagingKey] as? ResponseDictionary
            {
                let totalCount = responseDictionary[self.dynamicType.TotalKey]?.longValue
                let currentPage = responseDictionary[self.dynamicType.PageKey]?.longValue
                let itemsPerPage = responseDictionary[self.dynamicType.PerPageKey]?.longValue
                
                var nextPageRequest: Request<ModelType>? = nil
                var previousPageRequest: Request<ModelType>? = nil
                var firstPageRequest: Request<ModelType>? = nil
                var lastPageRequest: Request<ModelType>? = nil
                
                if let nextPageLink = pagingDictionary[self.dynamicType.NextKey] as? String
                {
                    nextPageRequest = request.associatedPageRequest(newPath: nextPageLink)
                }
                
                if let previousPageLink = pagingDictionary[self.dynamicType.PreviousKey] as? String
                {
                    previousPageRequest = request.associatedPageRequest(newPath: previousPageLink)
                }
                
                if let firstPageLink = pagingDictionary[self.dynamicType.FirstKey] as? String
                {
                    firstPageRequest = request.associatedPageRequest(newPath: firstPageLink)
                }
                
                if let lastPageLink = pagingDictionary[self.dynamicType.LastKey] as? String
                {
                    lastPageRequest = request.associatedPageRequest(newPath: lastPageLink)
                }
                
                response = Response<ModelType>(model: modelObject,
                                               json: responseDictionary,
                                               isCachedResponse: isCachedResponse,
                                               isFinalResponse: isFinalResponse,
                                               totalCount: totalCount,
                                               page: currentPage,
                                               itemsPerPage: itemsPerPage,
                                               nextPageRequest: nextPageRequest,
                                               previousPageRequest: previousPageRequest,
                                               firstPageRequest: firstPageRequest,
                                               lastPageRequest: lastPageRequest)
            }
            else
            {
                response = Response<ModelType>(model: modelObject, json: responseDictionary, isCachedResponse: isCachedResponse, isFinalResponse: isFinalResponse)
            }
            
            // To avoid a poisoned cache, explicitly wait until model object parsing is successful to store responseDictionary [RH]
            if request.shouldCacheResponse
            {
                self.responseCache.setResponse(responseDictionary, forRequest: request)
            }
            
            dispatch_async(completionQueue)
            {
                completion(result: .Success(result: response))
            }
        }
        catch let error
        {
            self.responseCache.removeResponseForRequest(request)
            
            self.handleTaskFailure(request: request, task: task, error: error as? NSError, completionQueue: completionQueue, completion: completion)
        }
    }
    
    private func handleTaskFailure<ModelType: MappableResponse>(request request: Request<ModelType>, task: NSURLSessionDataTask?, error: NSError?, completionQueue: dispatch_queue_t, completion: ResultCompletion<Response<ModelType>>.T)
    {
        let error = error ?? NSError(domain: self.dynamicType.ErrorDomain, code: LocalErrorCode.Undefined.rawValue, userInfo: [NSLocalizedDescriptionKey: "Undefined error"])
        
        if error.code == NSURLErrorCancelled
        {
            return
        }
        
        self.handleError(error, request: request)
        
        if case .MultipleAttempts(let attemptCount, let initialDelay) = request.retryPolicy
            where attemptCount > 1
        {
            var retryRequest = request
            retryRequest.retryPolicy = .MultipleAttempts(attemptCount: attemptCount - 1, initialDelay: initialDelay * 2)
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(initialDelay * Double(NSEC_PER_SEC))), dispatch_get_main_queue())
            {
                self.request(retryRequest, completionQueue: completionQueue, completion: completion)
            }
        }
        
        else if request.cacheFetchPolicy == .TryNetworkThenCache
        {
            var cacheRequest = request
            cacheRequest.cacheFetchPolicy = .CacheOnly
            
            self.request(cacheRequest, completionQueue: completionQueue, completion: completion)
            
            return
        }
        
        dispatch_async(completionQueue)
        {
            completion(result: .Failure(error: error))
        }
    }
    
    // MARK: - Private error handling
    
    private func handleError<ModelType: MappableResponse>(error: NSError, request: Request<ModelType>)
    {
        if error.isServiceUnavailableError
        {
            Notification.ClientDidReceiveServiceUnavailableError.post(object: nil)
        }
        else if error.isInvalidTokenError
        {
            Notification.ClientDidReceiveInvalidTokenError.post(object: nil)
        }
    }
}

