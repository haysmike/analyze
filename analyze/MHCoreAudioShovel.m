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

@implementation MHCoreAudioShovel {
    AudioDeviceIOProcID _procId;
    AudioDeviceID _deviceId;
    MHRingBuffer *_ringBuffer;
    int _frameByteSize;
    int _numFrames;
    Float32 *_buffer;
    int _shift;;
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
        _shift = (_numFrames - 1) * _frameByteSize / sizeof(Float32);

        _buffer = malloc(size);

        _ringBuffer = [[MHRingBuffer alloc] initWithCapacity:_numFrames * 4 andItemSize:_frameByteSize];

        AudioDeviceCreateIOProcIDWithBlock(&_procId, _deviceId, NULL, ^(const AudioTimeStamp *inNow, const AudioBufferList *inInputData, const AudioTimeStamp *inInputTime, AudioBufferList *outOutputData, const AudioTimeStamp *inOutputTime) {
            @synchronized(_ringBuffer) {
                [_ringBuffer give:inInputData->mBuffers[0].mData];
            }
        });
    }
    return self;
}

- (void)dealloc
{
    free(_buffer);
}

- (void *)getBuffer
{
    static BOOL started = NO;
    if (!started)
        AudioDeviceStart(_deviceId, _procId);

    // take all ringbuffer frames -> internal buffer
    @synchronized(_ringBuffer) {
        if ([_ringBuffer state] == kMHRingBufferStateNormal || [_ringBuffer state] == kMHRingBufferStateOverflowImminent) {
            while ([_ringBuffer size]) {
//                // probably inefficient
                memmove(_buffer, _buffer + _frameByteSize, _shift);
                Float32 *ptr = [_ringBuffer take];
                memcpy(_buffer + _shift, ptr, _frameByteSize);
            }
        }
    }
    return _buffer;
}

@end
