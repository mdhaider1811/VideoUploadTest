//
//  Request+Cache.swift
//  VimeoNetworkingExample-iOS
//
//  Created by Huebner, Rob on 4/14/16.
//  Copyright © 2016 Vimeo. All rights reserved.
//

import Foundation

public extension Request
{
        /// Generates a unique cache key for a request, taking into account endpoint and parameters
    var cacheKey: String
    {
        var cacheKey = "cached" + self.path
        
        for (key, value) in self.parameters
        {
            if key == "fields"
            {
                // avoiding the field filtering key due to excessive length
                continue
            }
            
            cacheKey += key
            cacheKey += value.description
        }
        
        cacheKey = cacheKey.stringByReplacingOccurrencesOfString("/", withString: ".")
        
        return cacheKey
    }
}