//
//  Request+Channel.swift
//  VimeoNetworking
//
//  Created by Huebner, Rob on 4/25/16.
//  Copyright © 2016 Vimeo. All rights reserved.
//

import Foundation

/// `Request` that returns a single `VIMChannel`
public typealias ChannelRequest = Request<VIMChannel>

/// `Request` that returns an array of `VIMChannel`
public typealias ChannelListRequest = Request<[VIMChannel]>

public extension Request
{
    private static var QueryKey: String { return "query" }
    
    private static var ChannelsPath: String { return "/channels" }
    
    /**
     Create a new request to get a specific channel
     
     - parameter channelURI: the channel's URI
     
     - returns: a new `Request`
     */
    public static func getChannelRequest(channelURI channelURI: String) -> Request
    {
        return Request(path: channelURI)
    }
    
    /**
     Create a request to search for a channel
     
     - parameter query:       the string query to use for the search
     - parameter refinements: optionally, any search refinement parameters to add to the query
     
     - returns: a new `Request`
     */
    public static func queryChannels(query query: String, refinements: VimeoClient.RequestParameters? = nil) -> Request
    {
        var parameters = refinements ?? [:]
        
        parameters[self.QueryKey] = query
        
        return Request(path: self.ChannelsPath, parameters: parameters)
    }
}