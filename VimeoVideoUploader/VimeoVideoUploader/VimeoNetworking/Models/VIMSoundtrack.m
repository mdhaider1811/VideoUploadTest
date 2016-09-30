//
//  VIMSoundtrack.m
//  VimeoNetworking
//
//  Created by Westendorf, Michael on 4/26/16.
//  Copyright © 2016 Vimeo. All rights reserved.
//

#import "VIMSoundtrack.h"

@implementation VIMSoundtrack

#pragma mark - VIMMappable

- (NSDictionary *)getObjectMapping
{
    return @{
             @"description" : @"soundtrackDescription"
            };
}

@end
