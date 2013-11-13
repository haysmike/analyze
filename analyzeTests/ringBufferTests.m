//
//  ringBufferTests.m
//  analyzeTests
//
//  Created by Mike Hays on 10/19/13.
//  Copyright (c) 2013 Mike Hays. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "MHRingBuffer.h"

#define CAPACITY 4

@interface ringBufferTests : XCTestCase

@end

@implementation ringBufferTests {
    void *_testValues;
    MHRingBuffer *_ringBuffer;
}

- (void)setUp
{
    [super setUp];

    _testValues = malloc(2 * CAPACITY * sizeof(int));
    int *values = _testValues;
    for (int i = 0; i < 2 * CAPACITY; i++) {
        values[i] = i;
    }

    _ringBuffer = [[MHRingBuffer alloc] initWithCapacity:CAPACITY andItemSize:sizeof(int)];
}

- (void)tearDown
{
    free(_testValues);
    _ringBuffer = nil;

    [super tearDown];
}

- (void)testBasics
{
    XCTAssert([_ringBuffer size] == 0);
    XCTAssertEqual([_ringBuffer state], kMHRingBufferStateNormal);
}

- (void)testGiveAndTake
{
    [_ringBuffer give:_testValues];
    int value = *(int *)[_ringBuffer take];
    XCTAssertEqual(value, *(int *)_testValues);

    [_ringBuffer give:_testValues + 1 * sizeof(int)];
    value = *(int *)[_ringBuffer take];
    XCTAssertEqual(value, *(int *)(_testValues + sizeof(int)));
}

- (void)testOverFlow
{
    for (int i = 0; i < CAPACITY; i++) {
        [_ringBuffer give:_testValues];
    }
    XCTAssertEqual([_ringBuffer state], kMHRingBufferStateOverflowImminent);
    [_ringBuffer give:_testValues];
    XCTAssertEqual([_ringBuffer state], kMHRingBufferStateOverflow);
}

- (void)testWrapping
{
    int value;
    for (int i = 0; i < CAPACITY + 1; i++) {
        [_ringBuffer give:_testValues + i * sizeof(int)];
        value = *(int *)[_ringBuffer take];
    }
    XCTAssertEqual(value, *(int *)(_testValues + CAPACITY * sizeof(int)));
    XCTAssertEqual([_ringBuffer state], kMHRingBufferStateUnderflowImminent);
}

@end
