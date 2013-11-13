//
//  MHCoreAudioShovel.m
//  analyze
//
//  Created by Mike Hays on 11/8/13.
//  Copyright (c) 2013 Mike Hays. All rights reserved.
//

#import <CoreAudio/CoreAudio.h>
#import <Accelerate/Accelerate.h>

#import "MHCoreAudioShovel.h"

#import "MHRingBuffer.h"

//UInt32 samplesPerFrame;
//DSPSplitComplex deinterleavedSamples;

@implementation MHCoreAudioShovel {
    AudioDeviceIOProcID _procId;
    AudioDeviceID _deviceId;
    MHRingBuffer *_ringBuffer;
    int _frameByteSize;
    int _numFrames;
    Float32 *_buffer;
}

- (id)initWithBufferSize:(int)size
{
    self = [super init];
    if (self) {
        OSStatus error;

        UInt32 deviceIdSize = sizeof(AudioDeviceID);
        AudioObjectPropertyAddress inputDeviceAddress = {
            kAudioHardwarePropertyDefaultInputDevice,
            kAudioObjectPropertyScopeGlobal,
            kAudioObjectPropertyElementMaster
        };
        error = AudioObjectGetPropertyData(kAudioObjectSystemObject, &inputDeviceAddress, 0, NULL, &deviceIdSize, &_deviceId);
        if (error) printf("\n* wow error: %i *\n\n", error);

        AudioBufferList streamConfiguration;
        UInt32 streamConfigurationSize = sizeof(AudioBufferList);
        AudioObjectPropertyAddress streamConfigurationAddress = {
            kAudioDevicePropertyStreamConfiguration,
            kAudioObjectPropertyScopeInput,
            kAudioObjectPropertyElementMaster
        };
        error = AudioObjectGetPropertyData(_deviceId, &streamConfigurationAddress, 0, NULL, &streamConfigurationSize, &streamConfiguration);
        if (error) printf("\n* wow error: %i *\n\n", error);

        _numChannels = streamConfiguration.mBuffers[0].mNumberChannels;
        _frameByteSize = streamConfiguration.mBuffers[0].mDataByteSize;
        _numFrames = size / _frameByteSize;

        _buffer = malloc(size);

        _ringBuffer = [[MHRingBuffer alloc] initWithCapacity:_numFrames * 2 andItemSize:_frameByteSize];

        AudioDeviceCreateIOProcIDWithBlock(&_procId, _deviceId, NULL, ^(const AudioTimeStamp *inNow, const AudioBufferList *inInputData, const AudioTimeStamp *inInputTime, AudioBufferList *outOutputData, const AudioTimeStamp *inOutputTime) {
            [_ringBuffer give:inInputData->mBuffers[0].mData];
        });
    }
    return self;
}

- (void)dealloc
{
    free(_buffer);
}

- (void *)getBuffer // dig?
{
    static BOOL started = NO;
    if (!started)
        AudioDeviceStart(_deviceId, _procId);

    // take all ringbuffer frames -> internal buffer
    if ([_ringBuffer state] == kMHRingBufferStateNormal || [_ringBuffer state] == kMHRingBufferStateOverflowImminent) {
        int offset = (_numFrames - 1) * _frameByteSize;
        while ([_ringBuffer size]) {
            // probably inefficient
            memmove(_buffer, _buffer + _frameByteSize, offset);
            memcpy(_buffer + offset, [_ringBuffer take], _frameByteSize);
        }
    }
    return _buffer;
}

@end
