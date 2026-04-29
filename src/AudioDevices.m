/*
    hear - Command line speech recognition for macOS

    Copyright (c) 2022-2026 Sveinbjorn Thordarson <sveinbjorn@sveinbjorn.org>
    All rights reserved.

    Redistribution and use in source and binary forms, with or without modification,
    are permitted provided that the following conditions are met:

    1. Redistributions of source code must retain the above copyright notice, this
    list of conditions and the following disclaimer.

    2. Redistributions in binary form must reproduce the above copyright notice, this
    list of conditions and the following disclaimer in the documentation and/or other
    materials provided with the distribution.

    3. Neither the name of the copyright holder nor the names of its contributors may
    be used to endorse or promote products derived from this software without specific
    prior written permission.

    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
    ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
    WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
    IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
    INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
    NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
    PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
    WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
    ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
    POSSIBILITY OF SUCH DAMAGE.
*/

#import "AudioDevices.h"
#import "Common.h"

@import CoreAudio;

@implementation AudioDevices

#pragma mark - Audio Input Devices

+ (NSArray *)availableAudioInputDevices {
    AudioObjectPropertyAddress addr = {
        kAudioHardwarePropertyDevices,
        kAudioObjectPropertyScopeGlobal,
        kAudioObjectPropertyElementMain
    };
    
    UInt32 size;
    OSStatus status = AudioObjectGetPropertyDataSize(kAudioObjectSystemObject, &addr, 0, NULL, &size);
    if (status != noErr) {
        return @[];
    }
    
    int count = size / sizeof(AudioDeviceID);
    AudioDeviceID *deviceIDs = (AudioDeviceID *)malloc(size);
    if (deviceIDs == NULL) {
        return @[];
    }
    
    status = AudioObjectGetPropertyData(kAudioObjectSystemObject, &addr, 0, NULL, &size, deviceIDs);
    if (status != noErr) {
        free(deviceIDs);
        return @[];
    }
    
    NSMutableArray *devices = [NSMutableArray array];
    
    for (int i = 0; i < count; i++) {
        AudioDeviceID deviceID = deviceIDs[i];
        
        addr.mScope = kAudioDevicePropertyScopeInput;
        addr.mSelector = kAudioDevicePropertyStreamConfiguration;
        status = AudioObjectGetPropertyDataSize(deviceID, &addr, 0, NULL, &size);
        if (status != noErr) {
            continue;
        }
        
        AudioBufferList *bufferList = (AudioBufferList *)malloc(size);
        if (bufferList == NULL) {
            continue;
        }
        status = AudioObjectGetPropertyData(deviceID, &addr, 0, NULL, &size, bufferList);
        if (status != noErr) {
            free(bufferList);
            continue;
        }
        
        UInt32 channelCount = 0;
        for (int j = 0; j < bufferList->mNumberBuffers; j++) {
            channelCount += bufferList->mBuffers[j].mNumberChannels;
        }
        free(bufferList);
        
        if (channelCount == 0) {
            continue;
        }
        
        CFStringRef deviceName;
        size = sizeof(deviceName);
        addr.mSelector = kAudioDevicePropertyDeviceNameCFString;
        status = AudioObjectGetPropertyData(deviceID, &addr, 0, NULL, &size, &deviceName);
        if (status != noErr) {
            continue;
        }
        
        CFStringRef deviceUID;
        size = sizeof(deviceUID);
        addr.mSelector = kAudioDevicePropertyDeviceUID;
        status = AudioObjectGetPropertyData(deviceID, &addr, 0, NULL, &size, &deviceUID);
        if (status != noErr) {
            CFRelease(deviceName);
            continue;
        }
        
        [devices addObject:@{
            @"name": (__bridge NSString *)deviceName,
            @"id": (__bridge NSString *)deviceUID
        }];
        
        CFRelease(deviceName);
        CFRelease(deviceUID);
    }
    
    free(deviceIDs);
    
    return devices;
}

+ (BOOL)hasAvailableAudioInputDevice {
    return [[self availableAudioInputDevices] count] != 0;
}

+ (BOOL)isAvailableAudioInputDevice:(NSString *)deviceID {
    NSArray *devices = [self availableAudioInputDevices];
    for (NSDictionary *device in devices) {
        if ([device[@"id"] isEqualToString:deviceID]) {
            return YES;
        }
    }
    return NO;
}

+ (void)printAvailableAudioInputDevices {
    NSArray *devices = [self availableAudioInputDevices];
    
    if ([devices count] == 0) {
        NSPrint(@"No audio input devices available");
        return;
    }
    
    NSPrint(@"Available Audio Input Devices:");
    NSUInteger num = 0;
    for (NSDictionary *device in devices) {
        num += 1;
        NSPrint(@"%lu. %@ (ID: %@)", num, device[@"name"], device[@"id"]);
    }
}

+ (AudioDeviceID)deviceIDForUID:(NSString *)uid {
    AudioDeviceID deviceID = kAudioObjectUnknown;
    CFStringRef cfUID = (__bridge CFStringRef)uid;
    
    AudioValueTranslation value = {
        .mInputData = &cfUID,
        .mInputDataSize = sizeof(CFStringRef),
        .mOutputData = &deviceID,
        .mOutputDataSize = sizeof(AudioDeviceID)
    };
    UInt32 size = sizeof(AudioValueTranslation);
    
    AudioObjectPropertyAddress addr = {
        kAudioHardwarePropertyDeviceForUID,
        kAudioObjectPropertyScopeGlobal,
        kAudioObjectPropertyElementMain
    };
    
    OSStatus status = AudioObjectGetPropertyData(kAudioObjectSystemObject, &addr, 0, NULL, &size, &value);
    if (status != noErr) {
        return kAudioObjectUnknown;
    }
    return deviceID;
}

@end
