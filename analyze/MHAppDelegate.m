//
//  MHAppDelegate.m
//  analyze
//
//  Created by Mike Hays on 10/19/13.
//  Copyright (c) 2013 Mike Hays. All rights reserved.
//

#import <CoreAudio/CoreAudio.h>
#import "MHAppDelegate.h"

@implementation MHAppDelegate

static AudioDeviceIOProcID procId = NULL;
static AudioDeviceID deviceId = 0;
static AudioStreamBasicDescription description;

OSStatus renderAudio(AudioObjectID          inDevice,
                     const AudioTimeStamp*  inNow,
                     const AudioBufferList* inInputData,
                     const AudioTimeStamp*  inInputTime,
                     AudioBufferList*       outOutputData,
                     const AudioTimeStamp*  inOutputTime,
                     void*                  inClientData)
{
//    printf("we haz audio! bufferlist: %p\n", inInputData);
    UInt32 numberBuffers = inInputData->mNumberBuffers;
    printf("we have %u buffers\n", numberBuffers);
    for (int buffer = 0; buffer < numberBuffers; buffer++) {
        int numberChannels = inInputData->mBuffers[buffer].mNumberChannels;
        int bufferSize = inInputData->mBuffers[buffer].mDataByteSize;
        printf("one of them is at %p\n", &inInputData->mBuffers[buffer]);
        printf("- it has %u channels\n", numberChannels);
        printf("- it has %u data bytes\n", bufferSize);

        // de-interleave
        Float32 *data = inInputData->mBuffers[buffer].mData;
        for (int frame = 0; frame < bufferSize / description.mBytesPerFrame; frame++) {
            Float32 sample = data[frame];
            printf("%f ", sample);
        }
    }

    printf("\n");

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
    printf("device id: %u\n", deviceId);

    UInt32 descriptionSize = sizeof(AudioStreamBasicDescription);
    AudioObjectPropertyAddress descriptionAddress = {
        kAudioStreamPropertyVirtualFormat,
        kAudioObjectPropertyScopeInput,
        kAudioObjectPropertyElementMaster
    };
    AudioObjectGetPropertyData(deviceId, &descriptionAddress, 0, NULL, &descriptionSize, &description);



    AudioDeviceCreateIOProcID(deviceId, &renderAudio, nil, &procId);
    AudioDeviceStart(deviceId, procId);

//    AudioStreamID blah;
}

@end
