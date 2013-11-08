//
//  MHAppDelegate.m
//  analyze
//
//  Created by Mike Hays on 10/19/13.
//  Copyright (c) 2013 Mike Hays. All rights reserved.
//

#import <Accelerate/Accelerate.h>
#import <CoreAudio/CoreAudio.h>
#import "MHAppDelegate.h"

@implementation MHAppDelegate

static AudioDeviceIOProcID procId;
static AudioDeviceID deviceId;
static UInt32 frameSize;
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
    UInt32 numberBuffers = inInputData->mNumberBuffers;
    for (int buffer = 0; buffer < numberBuffers; buffer++) {
        Float32 *data = inInputData->mBuffers[buffer].mData;

        // de-interleave
        vDSP_ctoz((const DSPComplex *)data, NUM_CHANNELS, &deinterleavedSamples, 1, frameSize);
        // doStuff(deinterleavedSamples)
    }

//    AudioDeviceStop(deviceId, procId);

    return 0;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    OSStatus error;

    UInt32 deviceIdSize = sizeof(AudioDeviceID);
    AudioObjectPropertyAddress inputDeviceAddress = {
        kAudioHardwarePropertyDefaultInputDevice,
        kAudioObjectPropertyScopeGlobal,
        kAudioObjectPropertyElementMaster
    };
    error = AudioObjectGetPropertyData(kAudioObjectSystemObject, &inputDeviceAddress, 0, NULL, &deviceIdSize, &deviceId);
    if (error) printf("\n* it's an error: %i *\n\n", error);

    UInt32 frameSizeSize = sizeof(UInt32);
    AudioObjectPropertyAddress bufferFrameSizeAddress = {
        kAudioDevicePropertyBufferFrameSize,
        kAudioObjectPropertyScopeInput,
        kAudioObjectPropertyElementMaster
    };
    error = AudioObjectGetPropertyData(deviceId, &bufferFrameSizeAddress, 0, NULL, &frameSizeSize, &frameSize);
    if (error) printf("\n* it's an error: %i *\n\n", error);

    deinterleavedSamples.realp = malloc(sizeof(Float32) * frameSize);
    deinterleavedSamples.imagp = malloc(sizeof(Float32) * frameSize);

    AudioDeviceCreateIOProcID(deviceId, &RenderAudio, nil, &procId);
    AudioDeviceStart(deviceId, procId);
}

@end
