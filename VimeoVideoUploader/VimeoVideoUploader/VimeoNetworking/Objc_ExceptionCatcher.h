//
//  ObjC_ExceptionCatcher.h
//  VimeoNetworking
//
//  Created by Huebner, Rob on 4/26/16.
//  Copyright © 2016 Vimeo. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ObjC_ExceptionCatcher : NSObject

/**
 *  This class helps us use exception-throwing code in Swift, which can't handle catching said exceptions.
 *
 *  @param unsafeBlock A block running any potentially exception-laden logic.
 *
 *  @return Nil if the block executed without issue; an error if an exception was thrown, error.domain = exception.name and error.localizedDescription = exception.description
 */
+ (nullable NSError *)_doUnsafe:(nonnull void(^)(void))unsafeBlock;

@end
