//
//  Request.swift
//  VimeoNetworkingExample-iOS
//
//  Created by Huebner, Rob on 3/22/16.
//  Copyright © 2016 Vimeo. All rights reserved.
//

import Foundation
import AFNetworking

/// Describes how a request should query the cache
public enum CacheFetchPolicy
{
        /// Only request cached responses.  No network request is made.
    case CacheOnly
    
        /// Try to load from both cache and network, note that two results may be returned when using this method (cached, then network)
    case CacheThenNetwork
    
        /// Only try to load the request from network.  The cache is not queried
    case NetworkOnly
    
        /// First try the network request, then fallback to cache if it fails
    case TryNetworkThenCache
    
    /**
     Construct the default cache fetch policy for a given `Method`
     
     - parameter method: the request `Method`
     
     - returns: the default cache policy for the provided `Method`
     */
    static func defaultPolicyForMethod(method: VimeoClient.Method) -> CacheFetchPolicy
    {
        switch method
        {
        case .GET:
            return .CacheThenNetwork
        case .DELETE, .PATCH, .POST, .PUT:
            return .NetworkOnly
        }
    }
}

/// Describes how a request should handle retrying after failure
public enum RetryPolicy
{
        /// Only one attempt is made, no retry behavior
    case SingleAttempt
    
    /**
      Retry a request a specified number of times, starting with a specified delay
     
     - parameter attemptCount: maximum number of times this request should be retried
     - parameter initialDelay: the delay (in seconds) until first retry. The next delay is doubled with each retry to provide `back-off` behavior, which tends to lead to a greater probability of recovery
     */
    case MultipleAttempts(attemptCount: Int, initialDelay: NSTimeInterval)
    
    /**
     Construct the default retry policy for a given `Method`
     
     - parameter method: the request `Method`
     
     - returns: the default retry policy for the given `Method`
     */
    static func defaultPolicyForMethod(method: VimeoClient.Method) -> RetryPolicy
    {
        switch method
        {
        case .GET, .DELETE, .PATCH, .POST, .PUT:
            return .SingleAttempt
        }
    }
}

extension RetryPolicy
{
    /// Convenience `RetryPolicy` constructor that provides a standard multiple attempt policy
    static let TryThreeTimes: RetryPolicy = .MultipleAttempts(attemptCount: 3, initialDelay: 2.0)
}

/**
 *  Describes a single request.
 *
 *  `<ModelType>` is the type of the expected response model object
 */
public struct Request<ModelType: MappableResponse>
{
    // TODO: Make these static when Swift supports it [RH] (5/24/16)
    private let PageKey = "page"
    private let PerPageKey = "per_page"
    
    // MARK: -
    
        /// HTTP method (e.g. `.GET`, `.POST`)
    public let method: VimeoClient.Method
    
        /// request url path (e.g. `/me`, `/videos/123456`)
    public let path: String
    
        /// any parameters to include with the request, this is calculated from the raw parameters provided at request initialization plus any specified `page` or `itemsPerPage` values on the request itself
    public var parameters: VimeoClient.RequestParameters
    {
        var parameters = self.additionalParameters
        
        if let page = self.page
        {
            parameters[self.PageKey] = page
        }
        
        if let itemsPerPage = self.itemsPerPage
        {
            parameters[self.PerPageKey] = itemsPerPage
        }
        
        return parameters
    }
    
    private let additionalParameters: VimeoClient.RequestParameters
    
        /// for collection requests, the page number to request, nil will specify no page number and fetch the first page, defaults to nil
    public let page: Int?
    
        /// for collection requests, the number of items that should be returned per page, nil uses the api standard of 25, defaults to nil
    public let itemsPerPage: Int?
    
        /// query a nested JSON key path for the response model object to be returned
    public let modelKeyPath: String?
    
        /// describes how this request should query for cached responses
    public var cacheFetchPolicy: CacheFetchPolicy
    
        /// whether a successful response to this request should be stored in cache
    public let shouldCacheResponse: Bool
    
        /// describes how the request should handle retrying after failure
    public var retryPolicy: RetryPolicy
    
    // MARK: -
    
    /**
     Build a new request, where the generic type `ModelType` is that of the expected response model object
     
     - parameter method:              the HTTP method (e.g. `.GET`, `.POST`), defaults to `.GET`
     - parameter path:                url path for this request
     - parameter parameters:          any additional parameters for this request, defaults to `nil`
     - parameter page:                for collection requests, the page number to request, nil will specify no page number and fetch the first page, defaults to nil
     - parameter itemsPerPage:        for collection requests, the number of items that should be returned per page, nil uses the api standard of 25, defaults to nil
     - parameter modelKeyPath:        optionally query a nested JSON key path for the response model object to be returned, defaults to `nil`
     - parameter cacheFetchPolicy:    describes how this request should query for cached responses, defaults to `.CacheThenNetwork`
     - parameter shouldCacheResponse: whether the response should be stored in cache, defaults to `true`
     - parameter retryPolicy:         describes how the request should handle retrying after failure, defaults to `.SingleAttempt`
     
     - returns: an initialized `Request`
     */
    public init(method: VimeoClient.Method = .GET,
         path: String,
         parameters: VimeoClient.RequestParameters? = nil,
         page: Int? = nil,
         itemsPerPage: Int? = nil,
         modelKeyPath: String? = nil,
         cacheFetchPolicy: CacheFetchPolicy? = nil,
         shouldCacheResponse: Bool? = nil,
         retryPolicy: RetryPolicy? = nil)
    {
        self.method = method
        
        let (path, query) = path.splitLinkString()
        self.path = path
        
        if let query = query,
            let queryParameters = query.parametersFromQueryString()
        {
            var page = page
            if let pageValue = queryParameters[self.PageKey]
            {
                page = page ?? Int(pageValue)
            }
            self.page = page
            
            var itemsPerPage = itemsPerPage
            if let itemsPerPageValue = queryParameters[self.PerPageKey]
            {
                itemsPerPage = itemsPerPage ?? Int(itemsPerPageValue)
            }
            self.itemsPerPage = itemsPerPage
            
            var additionalParameters = parameters ?? [:]
            queryParameters.forEach { (key, object) in
                additionalParameters[key] = object
            }
            self.additionalParameters = additionalParameters
        }
        else
        {
            self.additionalParameters = parameters ?? [:]
            self.page = page
            self.itemsPerPage = itemsPerPage
        }
        
        self.modelKeyPath = modelKeyPath
        self.cacheFetchPolicy = cacheFetchPolicy ?? CacheFetchPolicy.defaultPolicyForMethod(method)
        self.shouldCacheResponse = shouldCacheResponse ?? (method == .GET)
        self.retryPolicy = retryPolicy ?? RetryPolicy.defaultPolicyForMethod(method)
    }
    
        /// Returns a fully-formed URI comprised of the path plus a query string of any parameters
    public var URI: String
    {
        var URI = self.path
        
        let queryString = AFQueryStringFromParameters(self.parameters)
        if queryString.characters.count > 0
        {
            URI += "?" + queryString
        }
        
        return URI
    }
    
    // MARK: Copying requests
    
    internal func associatedPageRequest(newPath newPath: String) -> Request<ModelType>
    {
        return Request(method: self.method,
                       path: newPath,
                       parameters: self.additionalParameters,
                       page: nil,
                       itemsPerPage: nil,
                       modelKeyPath: self.modelKeyPath,
                       cacheFetchPolicy: self.cacheFetchPolicy,
                       shouldCacheResponse: self.shouldCacheResponse,
                       retryPolicy: self.retryPolicy)
    }
}