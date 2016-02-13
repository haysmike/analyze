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

#define BUFFER_SIZE_MULTIPLIER 4

@implementation MHCoreAudioShovel {
    AudioDeviceIOProcID _procId;
    AudioDeviceID _deviceId;
    MHRingBuffer *_ringBuffer;
    int _frameSize;
    int _frameByteSize;
    int _numFrames;
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
        error = AudioObjectGetPropertyData(kAudioObjectSystemObject,
                                           &inputDeviceAddress,
                                           0,
                                           NULL,
                                           &deviceIdSize,
                                           &_deviceId);
        if (error) printf("Error getting default audio device ID: %i *\n", error);

        AudioBufferList streamConfiguration;
        UInt32 streamConfigurationSize = sizeof(AudioBufferList);
        AudioObjectPropertyAddress streamConfigurationAddress = {
            kAudioDevicePropertyStreamConfiguration,
            kAudioObjectPropertyScopeInput,
            kAudioObjectPropertyElementMaster
        };
        error = AudioObjectGetPropertyData(_deviceId,
                                           &streamConfigurationAddress,
                                           0,
                                           NULL,
                                           &streamConfigurationSize,
                                           &streamConfiguration);
        if (error) printf("Error getting stream configuration: %i *\n", error);

        _numChannels = streamConfiguration.mBuffers[0].mNumberChannels;
        _frameByteSize = streamConfiguration.mBuffers[0].mDataByteSize;
        _numFrames = size / _frameByteSize;
        _frameSize = _frameByteSize / sizeof(Float32);
        _shift = (_numFrames - 1) * _frameSize;
        NSLog(@"Configuration:");
        NSLog(@"- Channels: %i", _numChannels);
        NSLog(@"- Frame Size: %i bytes", _frameByteSize);
        NSLog(@"- Frames per buffer: %i", _numFrames);
        NSLog(@"- Samples per frame: %i", _frameSize);

        _ringBuffer = [[MHRingBuffer alloc] initWithCapacity:_numFrames * BUFFER_SIZE_MULTIPLIER
                                                 andItemSize:_frameByteSize];

        AudioDeviceIOBlock block = ^(const AudioTimeStamp *inNow,
                                     const AudioBufferList *inInputData,
                                     const AudioTimeStamp *inInputTime,
                                     AudioBufferList *outOutputData,
                                     const AudioTimeStamp *inOutputTime) {
            @synchronized(_ringBuffer) {
                [_ringBuffer give:inInputData->mBuffers[0].mData];
            }
        };
        AudioDeviceCreateIOProcIDWithBlock(&_procId,
                                           _deviceId,
                                           NULL,
                                           block);

        AudioDeviceStart(_deviceId, _procId);
    }
    return self;
}

- (void)getBuffer:(void *)buffer
{
    @synchronized(_ringBuffer) {
        MHRingBufferState state = [_ringBuffer state];
        // todo: handle other states
        if (state == kMHRingBufferStateNormal ||
            state == kMHRingBufferStateOverflowImminent) {

            void *ptr = NULL;
            while ([_ringBuffer size]) {
                ptr = [_ringBuffer take];
            }
            if (ptr) {
                memcpy(buffer, ptr, _frameByteSize);
            }
        }
    }
}

@end
