//
//  String+Utilities.swift
//  VimeoNetworkingExample-iOS
//
//  Created by Huebner, Rob on 3/29/16.
//  Copyright © 2016 Vimeo. All rights reserved.
//

import Foundation

public extension String
{
    /**
     Construct a dictionary of parameters from the current string
     
     - returns: a dictionary of parameters if parsing succeeded
     */
    func parametersFromQueryString() -> [String: String]?
    {
        var parameters: [String: String] = [:]
        
        let scanner = NSScanner(string: self)
        while !scanner.atEnd
        {
            var name: NSString?
            let equals = "="
            scanner.scanUpToString(equals, intoString: &name)
            scanner.scanString(equals, intoString: nil)
            
            var value: NSString?
            let ampersand = "&"
            scanner.scanUpToString(ampersand, intoString: &value)
            scanner.scanString(ampersand, intoString: nil)
            
            if let name = name?.stringByReplacingPercentEscapesUsingEncoding(NSUTF8StringEncoding),
                let value = value?.stringByReplacingPercentEscapesUsingEncoding(NSUTF8StringEncoding)
            {
                parameters[name] = value
            }
        }
        
        return parameters.count > 0 ? parameters : nil
    }
    
    /**
     Splits a link string into a path and a query
     
     - returns: a tuple containing: the path with any query string removed, and the query string if found
     */
    func splitLinkString() -> (path: String, query: String?)
    {
        let components = self.componentsSeparatedByString("?")
        
        if components.count == 2
        {
            return (path: components[0], query: components[1])
        }
        else
        {
            return (path: self, query: nil)
        }
    }
}