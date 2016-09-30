//
//  VIMBadge.swift
//  Pods
//
//  Created by Huebner, Rob on 9/16/16.
//
//

import Foundation

/// VIMBadge contains the text and/or icons used to display a badge on a video item
public class VIMBadge: VIMModelObject
{
    dynamic public var type: String?
    dynamic public var festival: String?
    dynamic public var link: String?
    dynamic public var text: String?
    dynamic public var pictures: VIMPictureCollection?
    
    public override func getClassForObjectKey(key: String) -> AnyClass?
    {
        if key == "pictures"
        {
            return VIMPictureCollection.self
        }
        
        return nil
    }
}