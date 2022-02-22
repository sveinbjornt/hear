/*
    Copyright (c) 2022, Sveinbjorn Thordarson <sveinbjorn@sveinbjorn.org>
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

#import <Speech/Speech.h>
#import "Listen.h"

@interface Listen() {
}

@property (nonatomic, retain) AVAudioEngine *engine;
@property (nonatomic, retain) SFSpeechRecognizer *recognizer;
@property (nonatomic, retain) SFSpeechAudioBufferRecognitionRequest *request;
@property (nonatomic, retain) SFSpeechRecognitionTask *task;
@property (nonatomic, retain) NSString *inputFile;

@end

@implementation Listen

+ (void)printSupportedLanguages {
    NSMutableArray *localeIdentifiers = [NSMutableArray new];
    for (NSLocale *locale in [SFSpeechRecognizer supportedLocales]) {
        [localeIdentifiers addObject:[locale localeIdentifier]];
    }
    [localeIdentifiers sortUsingSelector:@selector(compare:)];
    for (NSString *identifier in localeIdentifiers) {
        NSPrint(identifier);
    }
}

- (instancetype)initWithInput:(NSString *)input format:(NSString *)fmt {
    self = [super init];
    if (self) {
        self.inputFile = input;
    }
    return self;
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    [self requestSpeechRecognitionPermission];
}

- (void)requestSpeechRecognitionPermission {
    
    [SFSpeechRecognizer requestAuthorization:^(SFSpeechRecognizerAuthorizationStatus authStatus) {
        switch (authStatus) {
            
            case SFSpeechRecognizerAuthorizationStatusAuthorized:
                //User gave access to speech recognition
                DLog(@"Authorized");
                [self startListening];
                break;
                
            case SFSpeechRecognizerAuthorizationStatusDenied:
                // User denied access to speech recognition
                NSPrintErr(@"Speech recognition authorization denied");
                break;
                
            case SFSpeechRecognizerAuthorizationStatusRestricted:
                // Speech recognition restricted on this device
                NSPrintErr(@"Speech recognition authorization restricted on this device");
                break;
                
            case SFSpeechRecognizerAuthorizationStatusNotDetermined:
                // Speech recognition not yet authorized
                NSPrintErr(@"Speech recognition authorization not yet authorized");
                break;
                
            default:
                break;
        }
    }];
}

- (void)speechRecognitionTask:(SFSpeechRecognitionTask *)task didFinishRecognition:(SFSpeechRecognitionResult *)recognitionResult {
    NSString *recognizedText = recognitionResult.bestTranscription.formattedString;
    NSLog(@"%@", recognizedText);
}

- (void)startListening {

    self.request = [[SFSpeechAudioBufferRecognitionRequest alloc] init];
    if (self.request == nil) {
        NSLog(@"Unable to initialize speech recognition request");
        return;
    }

    
    NSLocale *locale = [NSLocale localeWithLocaleIdentifier:@"en-US"];
    self.recognizer = [[SFSpeechRecognizer alloc] initWithLocale:locale];
//    self.recognizer.delegate = self;
    if (self.recognizer == nil) {
        NSLog(@"Unable to initialize speech recognizer");
        return;
    }
    if (self.recognizer.isAvailable == NO) {
        NSLog(@"Speech recognizer not available");
        return;
    }
    if (self.recognizer.supportsOnDeviceRecognition) {
        NSLog(@"Speech recognizer supports on-device recognition");
        self.request.requiresOnDeviceRecognition = YES;
    }
    
    
    
    self.request.shouldReportPartialResults = YES;
//    self.request.requiresOnDeviceRecognition = YES;
    
//    self.task = [self.recognizer recognitionTaskWithRequest:self.request delegate:self];
    self.task = [self.recognizer recognitionTaskWithRequest:self.request
                                              resultHandler:^(SFSpeechRecognitionResult * _Nullable result, NSError * _Nullable error) {
        BOOL isFinal = result.isFinal;
        if (isFinal) {
            NSLog(@"Final result");
        }
        if (error != nil) {
            NSLog(@"Error: %@", error.localizedDescription);
            return;
        }
        NSString *s = result.bestTranscription.formattedString;
        NSPrint(s);
    }];
    
    if (self.task == nil) {
        NSLog(@"Unable to initialize speech recognition task");
        return;
    }
    
    NSLog(@"Creating engine");
    self.engine = [[AVAudioEngine alloc] init];
    AVAudioInputNode *inputNode = self.engine.inputNode;
    
    id recFmt = [inputNode outputFormatForBus:0];
        
    [inputNode installTapOnBus:0 bufferSize:1024 format:recFmt block:^(AVAudioPCMBuffer * _Nonnull buffer, AVAudioTime * _Nonnull when) {
        [self.request appendAudioPCMBuffer:buffer];
//        NSLog(@"Got audio input data: %@", buffer.description);
    }];
    
    NSError *err;
    NSLog(@"Starting engine");
    [self.engine prepare];
    [self.engine startAndReturnError:&err];
    if (err != nil) {
        NSLog(@"%@", [err localizedDescription]);
        exit(EXIT_FAILURE);
    }
}

@end
