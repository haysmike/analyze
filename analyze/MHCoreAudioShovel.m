//
//  MHCoreAudioShovel.m
//  analyze
//
//  Created by Mike Hays on 11/8/13.
//  Copyright (c) 2013 Mike Hays. All rights reserved.
//

#import <Accelerate/Accelerate.h>
#import <CoreAudio/CoreAudio.h>
#import "MHCoreAudioShovel.h"

static AudioDeviceIOProcID procId;
static AudioDeviceID deviceId;
static UInt32 samplesPerFrame;
static DSPSplitComplex deinterleavedSamples;
const static int NUM_CHANNELS = 2;

OSStatus RenderAudio(AudioObjectID          inDevice,
                     const AudioTimeStamp*  inNow,
                     const AudioBufferList* inInputData,
                     const AudioTimeStamp*  inInputTime,
                     AudioBufferList*       outOutputData,
                     const AudioTimeStamp*  inOutputTime,
                     void*                  inClientData)
{
    for (int buffer = 0; buffer < inInputData->mNumberBuffers; buffer++) {
        Float32 *data = inInputData->mBuffers[buffer].mData;

        // de-interleave into buffers
        vDSP_ctoz((const DSPComplex *)data, NUM_CHANNELS, &deinterleavedSamples, 1, samplesPerFrame);

        // ...

    }

    static int i = 0;
    if (!i) {
        static uint64_t t = 0;
        double dt = (double) (mach_absolute_time() - t) / (double) 1000000000;
        if (t > 0) {
            NSLog(@"consumed 1024 buffers in %lf seconds, %f buffers filled per second", dt, 1024.0 / (float)dt);
        }
        t = mach_absolute_time();
    }
    i++;
    i = i % 2048;

    return 0;
}

@implementation MHCoreAudioShovel

- (id)init
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
        error = AudioObjectGetPropertyData(kAudioObjectSystemObject, &inputDeviceAddress, 0, NULL, &deviceIdSize, &deviceId);
        if (error) printf("\n* wow error: %i *\n\n", error);

        UInt32 frameSizeSize = sizeof(UInt32);
        AudioObjectPropertyAddress bufferFrameSizeAddress = {
            kAudioDevicePropertyBufferFrameSize,
            kAudioObjectPropertyScopeInput,
            kAudioObjectPropertyElementMaster
        };
        error = AudioObjectGetPropertyData(deviceId, &bufferFrameSizeAddress, 0, NULL, &frameSizeSize, &samplesPerFrame);
        if (error) printf("\n* wow error: %i *\n\n", error);

        // buffering tbd
        _leftChannelBuffer = malloc(sizeof(Float32) * samplesPerFrame);
        _rightChannelBuffer = malloc(sizeof(Float32) * samplesPerFrame);
        deinterleavedSamples.realp = _leftChannelBuffer;
        deinterleavedSamples.imagp = _rightChannelBuffer;

        AudioDeviceCreateIOProcID(deviceId, &RenderAudio, nil, &procId);
        AudioDeviceStart(deviceId, procId);
    }
    return self;
}

@end
