//
//  MHRingBuffer.h
//  analyze
//
//  Created by Mike Hays on 11/12/13.
//  Copyright (c) 2013 Mike Hays. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MHRingBuffer : NSObject

typedef enum {
    kMHRingBufferStateUnderflow = -2,
    kMHRingBufferStateUnderflowImminent,
    kMHRingBufferStateNormal,
    kMHRingBufferStateOverflowImminent,
    kMHRingBufferStateOverflow
} MHRingBufferState;

@property (readonly) int numItems;
@property (readonly) int itemSize;

@property (readonly) MHRingBufferState state;

- (id)initWithCapacity:(int)numItems andItemSize:(int)itemSize;
- (void)give:(void *)item;

- (int)size;
- (void *)take;

@end
