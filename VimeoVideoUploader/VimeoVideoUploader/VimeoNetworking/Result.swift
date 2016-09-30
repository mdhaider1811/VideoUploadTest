//
//  Result.swift
//  VimeoNetworkingExample-iOS
//
//  Created by Huebner, Rob on 3/23/16.
//  Copyright © 2016 Vimeo. All rights reserved.
//

import Foundation

/**
 `Result` describes a general final output of a process that can be either successful or unsuccessful
 
 - Success: action successful, returns a result of type `ResultType`
 - Failure: action failed, returns an `NSError`
 */
public enum Result<ResultType>
{
        /// action successful, returns a result of type `ResultType`
    case Success(result: ResultType)
    
        /// action failed, returns an `NSError`
    case Failure(error: NSError)
}

/// `ResultCompletion` creates a generic typealias to generally define completion blocks that return a `Result` 
public enum ResultCompletion<ResultType>
{
    public typealias T = (result: Result<ResultType>) -> Void
}
