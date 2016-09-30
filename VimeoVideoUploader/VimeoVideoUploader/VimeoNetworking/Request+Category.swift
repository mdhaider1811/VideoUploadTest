//
//  Request+Category.swift
//  VimeoNetworking
//
//  Created by Huebner, Rob on 4/25/16.
//  Copyright © 2016 Vimeo. All rights reserved.
//

import Foundation

/// `Request` that returns a single `VIMCategory`
public typealias CategoryRequest = Request<VIMCategory>

/// `Request` that returns an array of `VIMCategory`
public typealias CategoryListRequest = Request<[VIMCategory]>

public extension Request
{
    private static var CategoriesPath: String { return "/categories" }
    
    /**
     Create a request that gets a specific category
     
     - parameter categoryURI: the category URI
     
     - returns: a new `Request`
     */
    public static func getCategoryRequest(categoryURI categoryURI: String) -> Request
    {
        return Request(path: categoryURI)
    }
    
    /**
     Create a request that returns a list of all categories
     
     - returns: a new `Request`
     */
    public static func getCategoriesRequest() -> Request
    {
        return Request(path: self.CategoriesPath)
    }
}
