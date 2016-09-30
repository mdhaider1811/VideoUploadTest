//
//  Request+Me.swift
//  VimeoNetworkingExample-iOS
//
//  Created by Huebner, Rob on 3/22/16.
//  Copyright © 2016 Vimeo. All rights reserved.
//

import Foundation

/// `Request` that returns a single `VIMUser`
public typealias UserRequest = Request<VIMUser>

/// `Request` that returns an array of `VIMUser`
public typealias UserListRequest = Request<[VIMUser]>

public extension Request
{
    private static var MeUserURI: String { return "/me" }
    private static var FollowingPathFormat: String { return "%@/following" }
    private static var FollowersPathFormat: String { return "%@/followers" }
    private static var UsersPath: String { return "/users" }
    
    private static var NameKey: String { return "name" }
    private static var LocationKey: String { return "location" }
    private static var BioKey: String { return "bio" }
    private static var QueryKey: String { return "query" }
    
    /**
     Create a request to get the current user
     
     - returns: a new `Request`
     */
    public static func getMeRequest() -> Request
    {
        return self.getUserRequest(userURI: self.MeUserURI)
    }
    
    /**
     Create a request to get the current user's following list
     
     - returns: a new `Request`
     */
    public static func getMeFollowingRequest() -> Request
    {
        return self.getUserFollowingRequest(userURI: self.MeUserURI)
    }
    
    /**
     Create a request to get the current user's followers list
     
     - returns: a new `Request`
     */
    public static func getMeFollowersRequest() -> Request
    {
        return self.getUserFollowersRequest(userURI: self.MeUserURI)
    }
    
    /**
     Create a request to get a specific user
     
     - parameter userURI: the specific user's URI
     
     - returns: a new `Request`
     */
    public static func getUserRequest(userURI userURI: String) -> Request
    {
        return Request(path: userURI)
    }
    
    /**
     Create a request to get a specific user's following list
     
     - parameter userURI: the specific user's URI
     
     - returns: a new `Request`
     */
    public static func getUserFollowingRequest(userURI userURI: String) -> Request
    {
        return Request(path: String(format: self.FollowingPathFormat, userURI))
    }
    
    /**
     Create a request to get a specific user's followers list
     
     - parameter userURI: the specific user's URI
     
     - returns: a new `Request`
     */
    public static func getUserFollowersRequest(userURI userURI: String) -> Request
    {
        return Request(path: String(format: self.FollowersPathFormat, userURI))
    }
    
    // MARK: - Search
    
    /**
     Create a request to search for users
     
     - parameter query:       the string query to use for the search
     - parameter refinements: optionally, search refinement parameters to add to the query
     
     - returns: a new `Request`
     */
    public static func queryUsers(query query: String, refinements: VimeoClient.RequestParameters? = nil) -> Request
    {
        var parameters = refinements ?? [:]
        
        parameters[self.QueryKey] = query
        
        return Request(path: self.UsersPath, parameters: parameters)
    }
    
    // MARK: - Edit User
    
    /**
     Create a request to edit a user's metadata
     
     - parameter userURI:     the URI of the user to edit
     - parameter newName:     a new name, unchanged if nil
     - parameter newLocation: a new location, unchanged if nil
     - parameter newBio:      a new bio, unchanged if nil
     
     - returns: the new `Request`
     */
    public static func patchUser(userURI userURI: String, newName: String?, newLocation: String?, newBio: String?) -> Request
    {
        var parameters = VimeoClient.RequestParameters()
        
        if let newName = newName
        {
            parameters[self.NameKey] = newName
        }
        
        if let newLocation = newLocation
        {
            parameters[self.LocationKey] = newLocation
        }
        
        if let newBio = newBio
        {
            parameters[self.BioKey] = newBio
        }
        
        return Request(method: .PATCH, path: userURI, parameters: parameters)
    }
}