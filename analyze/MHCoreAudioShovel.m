//
//  MHCoreAudioShovel.m
//  analyze
//
//  Created by Mike Hays on 11/8/13.
//  Copyright (c) 2013 Mike Hays. All rights reserved.
//

#import <Accelerate/Accelerate.h>
#import "MHCoreAudioShovel.h"


//UInt32 samplesPerFrame;
//DSPSplitComplex deinterleavedSamples;

@implementation MHCoreAudioShovel {
    AudioDeviceIOProcID _procId;
    AudioDeviceID _deviceId;
}

- (id)initWithIOBlock:(AudioDeviceIOBlock)block
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

        UInt32 frameSizeSize = sizeof(UInt32);
        AudioObjectPropertyAddress bufferFrameSizeAddress = {
            kAudioDevicePropertyBufferFrameSize,
            kAudioObjectPropertyScopeInput,
            kAudioObjectPropertyElementMaster
        };
        error = AudioObjectGetPropertyData(_deviceId, &bufferFrameSizeAddress, 0, NULL, &frameSizeSize, &_frameSize);
        if (error) printf("\n* wow error: %i *\n\n", error);

//        _bufferSize = samplesPerFrame;
//
//        // buffering tbd
//        _leftChannelBuffer = malloc(sizeof(Float32) * samplesPerFrame);
//        _rightChannelBuffer = malloc(sizeof(Float32) * samplesPerFrame);
//        deinterleavedSamples.realp = _leftChannelBuffer;
//        deinterleavedSamples.imagp = _rightChannelBuffer;

//        AudioDeviceCreateIOProcID(deviceId, &RenderAudio, nil, &procId);
        AudioDeviceCreateIOProcIDWithBlock(&_procId, _deviceId, NULL, block);
        AudioDeviceStart(_deviceId, _procId);
    }
    return self;
}

@end
