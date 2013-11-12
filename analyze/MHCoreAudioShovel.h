//
//  MHCoreAudioShovel.h
//  analyze
//
//  Created by Mike Hays on 11/8/13.
//  Copyright (c) 2013 Mike Hays. All rights reserved.
//

#import <CoreAudio/CoreAudio.h>

@interface MHCoreAudioShovel : NSObject

- (id)initWithIOBlock:(AudioDeviceIOBlock)block;

@property (readonly, assign) UInt32 frameSize;

//@property (readonly, assign) Float32 *buffer;
//@property (readonly, assign) Float32 *leftChannelBuffer;
//@property (readonly, assign) Float32 *rightChannelBuffer;

@end
