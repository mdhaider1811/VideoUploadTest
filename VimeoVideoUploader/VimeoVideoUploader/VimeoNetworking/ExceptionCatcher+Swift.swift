//
//  ExceptionCatcher+Swift.swift
//  VimeoNetworking
//
//  Created by Huebner, Rob on 4/26/16.
//  Copyright © 2016 Vimeo. All rights reserved.
//

import Foundation

class ExceptionCatcher: ObjC_ExceptionCatcher
{
    /**
     Execute a block of code that could potentially throw Objective-C exceptions
     
     - parameter unsafeBlock: The unsafe block of code to execute
     
     - throws: an error containing any thrown exception information
     */
    @nonobjc public static func doUnsafe(unsafeBlock: (Void -> Void)) throws
    {
        if let error = self._doUnsafe(unsafeBlock)
        {
            throw error
        }
    }
}