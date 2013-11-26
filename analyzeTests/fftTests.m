//
//  fftTests.m
//  analyzeTests
//
//  Created by Mike Hays on 10/19/13.
//  Copyright (c) 2013 Mike Hays. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "MHFFT.h"

#define FFT_SIZE 1024

@interface fftTests : XCTestCase

@end

@implementation fftTests {
    float *_inputValues;
    float *_outputValues;
    MHFFT *_fft;
}

- (void)setUp
{
    [super setUp];

    _inputValues = malloc(FFT_SIZE * 2 * sizeof(Float32));
    for (int i = 0; i < FFT_SIZE * 2; i++) {
        _inputValues[i] = 1.0f;
    }

    _outputValues = malloc(FFT_SIZE / 2 * sizeof(Float32));

    _fft = [[MHFFT alloc] initWithLength:FFT_SIZE];
}

- (void)tearDown
{
    free(_inputValues);
    _fft = nil;

    [super tearDown];
}

- (void)testForwardFft
{
    _outputValues = [_fft forward:_inputValues];
    XCTAssert(_outputValues[0] == (float)FFT_SIZE * 2.0f);
    for (int i = 1; i < FFT_SIZE / 2; i++) {
        XCTAssert(_outputValues[i] == 0.0);
    }
}

@end
