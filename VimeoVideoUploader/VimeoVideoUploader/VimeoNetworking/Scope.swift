//
//  Scope.swift
//  VimeoNetworkingExample-iOS
//
//  Created by Huebner, Rob on 3/23/16.
//  Copyright © 2016 Vimeo. All rights reserved.
//

import Foundation

    /// `Scope` describes a permission that your application requests from the API
public enum Scope: String
{
        /// View public videos
    case Public = "public"
    
        /// View private videos
    case Private = "private"
    
        /// View Vimeo On Demand purchase history
    case Purchased = "purchased"
    
        /// Create new videos, groups, albums, etc.
    case Create = "create"
    
        /// Edit videos, groups, albums, etc.
    case Edit = "edit"
    
        /// Delete videos, groups, albums, etc.
    case Delete = "delete"
    
        /// Interact with a video on behalf of a user, such as liking a video or adding it to your watch later queue
    case Interact = "interact"
    
        /// Upload a video
    case Upload = "upload"
    
    /**
     Combines an array of scopes into a scope string as expected by the api
     
     - parameter scopes: an array of `Scope` values
     
     - returns: a string of space-separated scope strings
     */
    static func combine(scopes: [Scope]) -> String
    {
        return scopes.reduce("") { $0 + " " + $1.rawValue }
    }
}