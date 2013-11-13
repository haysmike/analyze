//
//  MHRingBuffer.m
//  analyze
//
//  Created by Mike Hays on 11/12/13.
//  Copyright (c) 2013 Mike Hays. All rights reserved.
//

#import "MHRingBuffer.h"

@implementation MHRingBuffer {
    void *_buffer;
    int _writeOffset;
    int _readOffset;
}

- (id)initWithCapacity:(int)numItems andItemSize:(int)itemSize
{
    self = [super init];
    if (self) {
        _numItems = numItems;
        _itemSize = itemSize;
        _buffer = malloc(_numItems * _itemSize);
        memset(_buffer, 0, _numItems * _itemSize);
    }
    return self;
}

- (void)dealloc
{
    free(_buffer);
}

- (void)give:(void *)item
{
    @synchronized(self) {
        if (_state == kMHRingBufferStateOverflowImminent) {
            _state = kMHRingBufferStateOverflow;
            NSLog(@"*** RING BUFFER OVERFLOW ***");
        } else if (_state == kMHRingBufferStateUnderflowImminent) {
            _state = kMHRingBufferStateNormal;
        }

        memcpy(_buffer + _writeOffset * _itemSize, item, _itemSize);    // TODO: not sure memcpy should be here
        _writeOffset = (_writeOffset + 1) % _numItems;
        if (_writeOffset == _readOffset) {
            _state = kMHRingBufferStateOverflowImminent;
        }
    }
}

- (int)size
{
    @synchronized(self) {
        return _itemSize * ((_numItems + _writeOffset - _readOffset) % _numItems);
    }
}

- (void *)take
{
    @synchronized(self) {
        if (_state == kMHRingBufferStateUnderflowImminent) {
            _state = kMHRingBufferStateUnderflow;
            NSLog(@"*** RING BUFFER UNDERFLOW ***");
        } else if (_state == kMHRingBufferStateOverflowImminent) {
            _state = kMHRingBufferStateNormal;
        }

        void *elem = _buffer + _readOffset * _itemSize;
        _readOffset = (_readOffset + 1) % _numItems;
        if (_readOffset == _writeOffset) {
            _state = kMHRingBufferStateUnderflowImminent;
        }
        return elem;
    }
}

@end
