//
//  MHCoreAudioShovel.h
//  analyze
//
//  Created by Mike Hays on 11/8/13.
//  Copyright (c) 2013 Mike Hays. All rights reserved.
//

@interface MHCoreAudioShovel : NSObject

@property (readonly, assign) Float32 *leftChannelBuffer;
@property (readonly, assign) Float32 *rightChannelBuffer;

@end
