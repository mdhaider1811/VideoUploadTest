//
//  Request+Toggle.swift
//  VimeoNetworking
//
//  Created by Huebner, Rob on 4/26/16.
//  Copyright © 2016 Vimeo. All rights reserved.
//

import Foundation

/// `Request` that returns no object on success
public typealias ToggleRequest = Request<VIMNullResponse>

public extension Request
{
    /**
     Create a request to toggle a given uri (like, watchlater, follow, etc.)
     
     - parameter URI:      the toggleable URI
     - parameter newValue: new value to set the toggle to
     
     - returns: a new `Request`
     */
    public static func toggle(uri uri: String, newValue: Bool) -> Request
    {
        return Request(method: newValue ? .PUT : .DELETE, path: uri)
    }
}