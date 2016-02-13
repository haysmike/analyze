//
//  MHCoreAudioShovel.h
//  analyze
//
//  Created by Mike Hays on 11/8/13.
//  Copyright (c) 2013 Mike Hays. All rights reserved.
//

@interface MHCoreAudioShovel : NSObject

- (id)initWithBufferSize:(int)size;
- (void)getBuffer:(void *)buffer;

@property (readonly) UInt32 numChannels;

@end
