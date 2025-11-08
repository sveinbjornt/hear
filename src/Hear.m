/*
    hear - Command line speech recognition for macOS

    Copyright (c) 2022-2025 Sveinbjorn Thordarson <sveinbjorn@sveinbjorn.org>
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

#import "Hear.h"
#import "Common.h"
#import <CoreAudio/CoreAudio.h>

@interface Hear()

@property (nonatomic, retain) SFSpeechRecognizer *recognizer;
@property (nonatomic, retain) SFSpeechRecognitionRequest *request;
@property (nonatomic, retain) SFSpeechRecognitionTask *task;

@property (nonatomic, retain) AVAudioEngine *engine;

@property (nonatomic, retain) NSTimer *timeoutTimer;

@property (nonatomic, retain) NSString *locale;
@property (nonatomic, retain) NSString *inputFile;
@property (nonatomic) BOOL useDeviceInput;
@property (nonatomic) BOOL useOnDeviceRecognition;
@property (nonatomic) BOOL singleLineMode;
@property (nonatomic) BOOL addPunctuation;
@property (nonatomic) BOOL addTimestamps;
@property (nonatomic) BOOL subtitleMode;
@property (nonatomic, retain) NSString *exitWord;
@property (nonatomic) CGFloat timeout;
@property (nonatomic, retain) NSString *inputDeviceID;

@end

@implementation Hear

- (instancetype)initWithLocale:(NSString *)loc
                         input:(NSString *)input
                      onDevice:(BOOL)onDevice
                singleLineMode:(BOOL)singleLine
                addPunctuation:(BOOL)punctuation
                 addTimestamps:(BOOL)timestamps
                  subtitleMode:(BOOL)subtitle
                      exitWord:(NSString *)exitWord
                       timeout:(CGFloat)timeout
                 inputDeviceID:(NSString *)inputDeviceID
{
    if ((self = [super init])) {
        
        if ([[Hear supportedLocales] containsObject:loc] == NO) {
            [self die:@"Locale '%@' not supported. Run with -s flag to see list of supported locales", loc];
        }
        
        self.locale = loc;
        self.inputFile = input;
        self.useOnDeviceRecognition = onDevice;
        self.singleLineMode = singleLine;
        self.useDeviceInput = (input == nil);
        self.addPunctuation = punctuation;
        self.addTimestamps = timestamps;
        self.subtitleMode = subtitle;
        self.exitWord = exitWord;
        self.timeout = timeout;
        self.inputDeviceID = inputDeviceID;
    }
    return self;
}

#pragma mark - NSApplicationDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    [self requestSpeechRecognitionPermission];
}

#pragma mark -

// Dump message to stdout and exit
- (void)die:(NSString *)format, ... {
    va_list args;
    va_start(args, format);
    NSString *string  = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);
    fprintf(stderr, "%s\n", [string UTF8String]);
    exit(EXIT_FAILURE);
}

- (void)requestSpeechRecognitionPermission {
    [SFSpeechRecognizer requestAuthorization:^(SFSpeechRecognizerAuthorizationStatus authStatus) {
        switch (authStatus) {
            
            case SFSpeechRecognizerAuthorizationStatusAuthorized:
                // User allowed access to speech recognition
                [self runTask];
                break;
            
            case SFSpeechRecognizerAuthorizationStatusDenied:
                [self die:@"Speech recognition authorization denied"];
                break;
            
            case SFSpeechRecognizerAuthorizationStatusRestricted:
                [self die:@"Speech recognition authorization restricted on this device"];
                break;
            
            case SFSpeechRecognizerAuthorizationStatusNotDetermined:
                [self die:@"Speech recognition authorization not determined"];
                break;
            
            default:
                break;
            
        }
    }];
}

// Initialize speech recognizer
- (void)initRecognizer {
    NSLocale *locale = [NSLocale localeWithLocaleIdentifier:self.locale];
    self.recognizer = [[SFSpeechRecognizer alloc] initWithLocale:locale];
    if (self.recognizer == nil) {
        [self die:@"Unable to initialize speech recognizer"];
    }
    self.recognizer.delegate = self;
    
    // Make sure recognition is available
    if (self.recognizer.isAvailable == NO) {
        [self die:@"Speech recognizer not available. Try enabling Siri in System Settings."];
    }
    
    if (self.useOnDeviceRecognition && !self.recognizer.supportsOnDeviceRecognition) {
        [self die:@"On-device recognition is not supported for locale '%@'", self.locale];
    }
}

- (void)runTask {
    if (self.useDeviceInput) {
        [self startListening];
    } else {
        if (self.subtitleMode) {
            [self processFileSubtitle];
        } else {
            [self processFile];
        }
    }
}

- (void)verifyFile:(NSString *)filePath {
    // Make sure it exists
    if ([[NSFileManager defaultManager] fileExistsAtPath:filePath] == NO) {
        [self die:@"No file at path '%@'", filePath];
    }
    // Make sure it is a supported format
    if ([Hear isFileSupportedByAVFoundation:filePath] == NO) {
        [self die:@"File format not supported."];
    }
}

- (void)processFile {
    [self verifyFile:self.inputFile];
    [self initRecognizer];
    
    // Create speech recognition request with file URL
    NSURL *fileURL = [NSURL fileURLWithPath:self.inputFile];
    self.request = [[SFSpeechURLRecognitionRequest alloc] initWithURL:fileURL];
    if (self.request == nil) {
        [self die:@"Unable to initialize speech recognition request"];
    }
    
    self.request.shouldReportPartialResults = NO;
    self.request.requiresOnDeviceRecognition = self.useOnDeviceRecognition;
    self.request.addsPunctuation = self.addPunctuation;
    
    // Create speech recognition task
    self.task = [self.recognizer recognitionTaskWithRequest:self.request
                                              resultHandler:
    ^(SFSpeechRecognitionResult * _Nullable result, NSError * _Nullable error) {
        
        if (error != nil) {
            [self die:[error description]];
        }
        
        if (result == nil) {
            return;
        }
        
        if (self.addTimestamps) {
            SFSpeechRecognitionMetadata *meta = result.speechRecognitionMetadata;
            NSTimeInterval start = meta.speechStartTimestamp;
            NSTimeInterval end = start + meta.speechDuration;
            NSDump([NSString stringWithFormat:@"%.2f --> %.2f\n", start, end]);
        }
        
        // Make sure there's a space between the incoming result strings
        NSString *s = result.bestTranscription.formattedString;
        if ([s hasSuffix:@" "] == FALSE && !result.isFinal) {
            s = [NSString stringWithFormat:@"%@ ", s];
        }
        
        // Print to stdout without newline and flush
        NSDump(s);
        
        if (self.addTimestamps) {
            NSDump(@"\n");
        }
        
        // Close with a newline once we're done
        if (result.isFinal) {
            // We're all done
            NSDump(@"\n");
            exit(EXIT_SUCCESS);
        }
        
    }];
    
    if (self.task == nil) {
        [self die:@"Unable to initialize speech recognition task"];
    }
}

// Produces output in the format of a valid .srt file
- (void)processFileSubtitle {
    [self verifyFile:self.inputFile];
    [self initRecognizer];
    
    // Create speech recognition request with file URL
    NSURL *fileURL = [NSURL fileURLWithPath:self.inputFile];
    self.request = [[SFSpeechURLRecognitionRequest alloc] initWithURL:fileURL];
    if (self.request == nil) {
        [self die:@"Error: Unable to initialize speech recognition request"];
    }
    self.request.shouldReportPartialResults = NO;
    self.request.requiresOnDeviceRecognition = self.useOnDeviceRecognition;
    self.request.addsPunctuation = self.addPunctuation;
    
    // Create speech recognition task
    self.task = [self.recognizer recognitionTaskWithRequest:self.request
                                              resultHandler:
    ^(SFSpeechRecognitionResult * _Nullable result, NSError * _Nullable error) {
        if (error != nil) {
            [self die:[error description]];
        }
        
        NSUInteger srt_index = 1;
        NSUInteger segment_count = result.bestTranscription.segments.count;
        const int CHUNK_SIZE = 8;
        
        for (NSUInteger i = 0; i < segment_count; i++) {
            NSUInteger start = i;
            NSUInteger end = MIN(i + CHUNK_SIZE, segment_count - 1);
            i = end;
            
            printf("%lu\n", srt_index); // sequential subtitle number
            srt_index++;
            
            NSTimeInterval start_time = result.bestTranscription.segments[start].timestamp;
            NSTimeInterval end_time = result.bestTranscription.segments[end].timestamp + result.bestTranscription.segments[end].duration;
            printf("%s --> %s\n", [[self stringFromTimeInterval:start_time] UTF8String], [[self stringFromTimeInterval:end_time] UTF8String]);
            
            for (NSUInteger k = start; k <= end; k++) {
                printf("%s", [result.bestTranscription.segments[k].substring UTF8String]);
                if (k < end) {
                    printf(" ");
                }
            }
            printf("\n\n");
        }
        
        if (result.isFinal) {
            // We're all done
            NSDump(@"\n");
            exit(EXIT_SUCCESS);
        }
    }];
    
    if (self.task == nil) {
        [self die:@"Error: Unable to initialize speech recognition task"];
    }
}


- (void)startListening {
    [self initRecognizer];
    
    // Set the input device, if specified
    if (self.inputDeviceID) {
        AudioObjectPropertyAddress addr = {
            kAudioHardwarePropertyDefaultInputDevice,
            kAudioObjectPropertyScopeGlobal,
            kAudioObjectPropertyElementMain
        };
        
        AudioDeviceID deviceID = kAudioObjectUnknown;
        
        NSArray *devices = [Hear availableAudioInputDevices];
        for (NSDictionary *device in devices) {
            if ([device[@"id"] isEqualToString:self.inputDeviceID]) {
                
                CFStringRef deviceUID = (__bridge CFStringRef)device[@"id"];
                
                AudioValueTranslation value;
                value.mInputData = &deviceUID;
                value.mInputDataSize = sizeof(CFStringRef);
                value.mOutputData = &deviceID;
                value.mOutputDataSize = sizeof(AudioDeviceID);
                
                UInt32 size = sizeof(AudioValueTranslation);
                
                AudioObjectPropertyAddress addr = {
                    kAudioHardwarePropertyDeviceForUID,
                    kAudioObjectPropertyScopeGlobal,
                    kAudioObjectPropertyElementMain
                };
                
                OSStatus status = AudioObjectGetPropertyData(kAudioObjectSystemObject, &addr, 0, NULL, &size, &value);
                if (status != noErr) {
                    [self die:@"Unable to get device ID for UID '%@'", self.inputDeviceID];
                }
                break;
            }
        }
        
        if (deviceID == kAudioObjectUnknown) {
            [self die:@"Audio input device with ID '%@' not found", self.inputDeviceID];
        }
        
        OSStatus status = AudioObjectSetPropertyData(kAudioObjectSystemObject, &addr, 0, NULL, sizeof(AudioDeviceID), &deviceID);
        if (status != noErr) {
            [self die:@"Error setting audio input device: %d", status];
        }
    }
    
    // Create speech recognition request
    self.request = [[SFSpeechAudioBufferRecognitionRequest alloc] init];
    if (self.request == nil) {
        [self die:@"Unable to initialize speech recognition request"];
    }
    self.request.shouldReportPartialResults = YES;
    self.request.requiresOnDeviceRecognition = self.useOnDeviceRecognition;
    // Add punctuation setting only available in Ventura and later
    self.request.addsPunctuation = self.addPunctuation;
    
    // Create spech recognition task
    self.task = [self.recognizer recognitionTaskWithRequest:self.request
                                              resultHandler:
    ^(SFSpeechRecognitionResult * _Nullable result, NSError * _Nullable error) {
        if (error != nil) {
            NSPrintErr(@"Error: %@", error.localizedDescription);
            return;
        }
        
        if (self.timeout > 0) {
            [self startTimer:self];
        }
        
        // Print to stdout
        NSString *transcript = result.bestTranscription.formattedString;
        if (self.singleLineMode) {
            // Erase current line and move cursor to the start of the line before printing
            NSString *s = [NSString stringWithFormat:@"\33[2K\r%@", transcript];
            NSDump(s);
        } else {
            NSPrint(transcript);
        }
        
        // If an exit word has been set, check if result ends with it
        if (self.exitWord != nil) {
            NSString *exitWord = [self.exitWord lowercaseString];
            NSString *exitSuffix = [[NSString stringWithFormat:@" %@", exitWord] lowercaseString];
            NSString *tsLower = [transcript lowercaseString];
            if ([tsLower hasSuffix:exitSuffix] || [tsLower isEqualToString:exitWord]) {
                // Exit word identified, we're done
                exit(EXIT_SUCCESS);
            }
        }
        
        if (result.isFinal) {
            // We're done
            exit(EXIT_SUCCESS);
        }
    }];
    
    if (self.task == nil) {
        [self die:@"Unable to initialize speech recognition task"];
    }
    
    // Create audio engine
    self.engine = [[AVAudioEngine alloc] init];
    AVAudioInputNode *inputNode = self.engine.inputNode;
    
    // Feed microphone audio data into recognition request
    [inputNode installTapOnBus:0
                    bufferSize:3200
                        format:[inputNode outputFormatForBus:0]
                         block:
     ^(AVAudioPCMBuffer * _Nonnull buffer, AVAudioTime * _Nonnull when) {
        [(SFSpeechAudioBufferRecognitionRequest *)self.request appendAudioPCMBuffer:buffer];
    }];
        
    // Start engine
    NSError *err;
    [self.engine startAndReturnError:&err];
    if (err != nil) {
        [self die:@"Failed to start audio engine: %@", [err localizedDescription]];
    }
    
    if (self.timeout > 0) {
        [self startTimer:self];
    }
}

- (void)startTimer:(id)sender {
    [self performSelectorOnMainThread:@selector(_startTimer:)
                           withObject:self
                        waitUntilDone:NO];
}

- (void)_startTimer:(id)sender {
    if (self.timeoutTimer != nil) {
        [self.timeoutTimer invalidate];
    }
    self.timeoutTimer = [NSTimer timerWithTimeInterval:self.timeout
                                                target:self
                                              selector:@selector(timedOut:)
                                              userInfo:self
                                               repeats:NO];
    [[NSRunLoop currentRunLoop] addTimer:self.timeoutTimer
                                 forMode:NSDefaultRunLoopMode];
}

- (void)timedOut:(id)sender {
    exit(EXIT_SUCCESS);
}

#pragma mark - Locales

+ (NSArray<NSString *> *)supportedLocales {
    NSMutableArray *localeIdentifiers = [NSMutableArray new];
    for (NSLocale *locale in [SFSpeechRecognizer supportedLocales]) {
        [localeIdentifiers addObject:[locale localeIdentifier]];
    }
    [localeIdentifiers sortUsingSelector:@selector(compare:)];
    return localeIdentifiers;
}

+ (void)printSupportedLocales {
    NSPrint([[Hear supportedLocales] componentsJoinedByString:@"\n"]);
}

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
    return [[Hear availableAudioInputDevices] count] != 0;
}

+ (BOOL)isAvailableAudioInputDevice:(NSString *)deviceID {
    NSArray *devices = [Hear availableAudioInputDevices];
    for (NSDictionary *device in devices) {
        if ([device[@"id"] isEqualToString:deviceID]) {
            return YES;
        }
    }
    return NO;
}

+ (void)printAvailableAudioInputDevices {
    NSArray *devices = [Hear availableAudioInputDevices];
    
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

#pragma mark - Util

+ (BOOL)isFileSupportedByAVFoundation:(NSString *)filePath {
    // Create NSURL from file path
    NSURL *fileURL = [NSURL fileURLWithPath:filePath];
    if (!fileURL) {
        return NO;
    }
    
    // Using AVURLAssetPreferPreciseDurationAndTimingKey can sometimes
    // trigger more thorough format checks during initialization.
    // Setting it to NO might be slightly faster.
    NSDictionary *options = @{ AVURLAssetPreferPreciseDurationAndTimingKey : @(YES) };
    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:fileURL options:options];
    
    return (asset != nil && [asset isReadable]);
}

// https://stackoverflow.com/a/32884209/11639533
- (NSString *)stringFromTimeInterval:(NSTimeInterval)timeInterval {
    NSInteger interval = timeInterval;
    NSInteger ms = (fmod(timeInterval, 1) * 1000);
    long seconds = interval % 60;
    long minutes = (interval / 60) % 60;
    long hours = (interval / 3600);
    return [NSString stringWithFormat:@"%0.2ld:%0.2ld:%0.2ld,%0.3ld",
            hours, minutes, seconds, (long)ms];
}

@end
