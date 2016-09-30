//
//  Request+Soundtrack.swift
//  VimeoNetworkingExample-iOS
//
//  Created by Westendorf, Michael on 4/21/16.
//  Copyright © 2016 Vimeo. All rights reserved.
//

import Foundation

/// Request that returns an array of `VIMSoundtrack` objects
public typealias SoundtrackListRequest = Request<[VIMSoundtrack]>

public extension Request
{
    private static var SoundtracksURI: String { return "/songs" }
    
    /**
     GET request to retrieve the root list of soundtracks
     
     - returns: a constructed `Request`
     */
    public static func getSoundtrackListRequest() -> Request
    {
        return self.getSoundtrackListRequest(soundtracksURI: self.SoundtracksURI)
    }
    
    /**
     GET request to request a list of soundtracks
     
     - parameter soundtracksURI: the URI of the soundtracks list
     
     - returns: a constructed `Request`
     */
    public static func getSoundtrackListRequest(soundtracksURI soundtracksURI: String) -> Request
    {
        return Request(path: soundtracksURI)
    }
}
