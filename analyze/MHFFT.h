//
//  MHFFT.h
//  analyze
//
//  Created by Mike Hays on 11/12/13.
//  Copyright (c) 2013 Mike Hays. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MHFFT : NSObject

- (id)initWithLength:(UInt32)length;
- (Float32 *)forward:(Float32 *)interleavedSamples;

@end
