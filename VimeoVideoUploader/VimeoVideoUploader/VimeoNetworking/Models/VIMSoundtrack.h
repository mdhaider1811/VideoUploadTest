//
//  VIMSoundtrack.h
//  VimeoNetworking
//
//  Created by Westendorf, Michael on 4/26/16.
//  Copyright © 2016 Vimeo. All rights reserved.
//

#import "VIMModelObject.h"

@interface VIMSoundtrack : VIMModelObject

@property (nonatomic, copy, nullable) NSString *uri;
@property (nonatomic, copy, nullable) NSString *title;
@property (nonatomic, copy, nullable) NSString *artist;
@property (nonatomic, copy, nullable) NSString *pictureLink;
@property (nonatomic, copy, nullable) NSString *billboardImageUrl;
@property (nonatomic, copy, nullable) NSString *featureImageUrl;
@property (nonatomic, copy, nullable) NSString *link;
@property (nonatomic, copy, nullable) NSString *albumName;
@property (nonatomic, copy, nullable) NSString *genre;
@property (nonatomic, copy, nullable) NSString *vibe;
@property (nonatomic, copy, nullable) NSString *soundtrackDescription;
@property (nonatomic, copy, nullable) NSString *status;
@property (nonatomic, copy, nullable) NSString *statusFeatured;
@property (nonatomic, copy, nullable) NSString *statusBillboard;
@property (nonatomic, copy, nullable) NSString *itunesUrl;
@property (nonatomic, copy, nullable) NSString *coverColor;
@property (nonatomic, copy, nullable) NSString *streamUrl;
@property (nonatomic, copy, nullable) NSString *audioUrl;
@property (nonatomic, copy, nullable) NSString *resourceKey;
@property (nonatomic, copy, nullable) NSString *echonestId;

@property (nonatomic, strong, nullable) NSNumber *orderBillboard;
@property (nonatomic, strong, nullable) NSNumber *orderFeatured;
@property (nonatomic, strong, nullable) NSNumber *tempo;
@property (nonatomic, strong, nullable) NSNumber *tempoBucket;
@property (nonatomic, strong, nullable) NSNumber *valence;
@property (nonatomic, strong, nullable) NSNumber *valenceBucket;
@property (nonatomic, strong, nullable) NSNumber *energy;
@property (nonatomic, strong, nullable) NSNumber *energyBucket;

@end
