/*
    hear - Command line speech recognition for macOS

    Copyright (c) 2022 Sveinbjorn Thordarson <sveinbjorn@sveinbjorn.org>
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
#import "Hear.h"

@interface Hear()

@property (nonatomic, retain) SFSpeechRecognizer *recognizer;
@property (nonatomic, retain) SFSpeechRecognitionRequest *request;
@property (nonatomic, retain) SFSpeechRecognitionTask *task;

@property (nonatomic, retain) AVAudioEngine *engine;

@property (nonatomic, retain) NSString *language;
@property (nonatomic, retain) NSString *inputFile;
@property (nonatomic, retain) NSString *inputFormat;
//@property (nonatomic, retain) NSString *tempFile;
@property (nonatomic) BOOL useMic;
@property (nonatomic) BOOL useOnDeviceRecognition;
@property (nonatomic) BOOL singleLineMode;

@end

@implementation Hear

- (instancetype)initWithLanguage:(NSString *)language
                           input:(NSString *)input
                          format:(NSString *)fmt
                        onDevice:(BOOL)onDevice
                  singleLineMode:(BOOL)singleLine {
    if ((self = [super init])) {
        
        if ([[Hear supportedLanguages] containsObject:language] == NO) {
            NSPrintErr(@"Locale '%@' not supported. Run with -s flag to see list of supported locales", language);
            exit(EXIT_FAILURE);
        }
        
        self.language = language;
        self.inputFile = input;
        self.inputFormat = fmt;
        self.useOnDeviceRecognition = onDevice;
        self.singleLineMode = singleLine;
        self.useMic = (input == nil);
    }
    return self;
}

#pragma mark - NSApplicationDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    [self requestSpeechRecognitionPermission];
}

#pragma mark -

- (void)die:(NSString *)errmsg {
    NSPrintErr(errmsg);
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
                [self die:@"Speech recognition authorization not yet authorized"];
                break;
                
            default:
                break;
        }
    }];
}

- (void)initRecognizer {
    // Initialize speech recognizer
    NSLocale *locale = [NSLocale localeWithLocaleIdentifier:self.language];
    self.recognizer = [[SFSpeechRecognizer alloc] initWithLocale:locale];
    self.recognizer.delegate = self;
    if (self.recognizer == nil) {
        [self die:@"Error: Unable to initialize speech recognizer"];
    }
    
    // Make sure recognition is available
    if (self.recognizer.isAvailable == NO) {
        [self die:@"Error: Speech recognizer not available. Try enabling Siri in System Preferences."];
    }
    
    if (self.useOnDeviceRecognition && !self.recognizer.supportsOnDeviceRecognition) {
        [self die:[NSString stringWithFormat:@"On-device recognition is not supported for %@", self.language]];
    }
}

- (void)runTask {
    if (self.useMic) {
        [self startListening];
    } else {
        [self processFile];
    }
}

- (void)processFile {
    
    NSString *filePath = self.inputFile;
    if ([filePath isEqualToString:@"-"]) {
        // TODO: Read from stdin and save to temp dir/feed to audio buffer processing?
        [self die:@"Reading from standard input remains unimplemented"];
    } else if ([[NSFileManager defaultManager] fileExistsAtPath:filePath] == NO) {
        [self die:[NSString stringWithFormat:@"No file at path %@", filePath]];
    }
    
    // OK, the file exists, let's try to run speech recognition on it
    [self initRecognizer];
    
    // Create speech recognition request with file URL
    NSURL *fileURL = [NSURL fileURLWithPath:filePath];
    self.request = [[SFSpeechURLRecognitionRequest alloc] initWithURL:fileURL];
    if (self.request == nil) {
        [self die:@"Error: Unable to initialize speech recognition request"];
    }
    self.request.shouldReportPartialResults = NO;
    self.request.requiresOnDeviceRecognition = self.useOnDeviceRecognition;

    // Create speech recognition task
    self.task = [self.recognizer recognitionTaskWithRequest:self.request
                                              resultHandler:
    ^(SFSpeechRecognitionResult * _Nullable result, NSError * _Nullable error) {
        if (error != nil) {
            [self die:[error localizedDescription]];
        }
        NSString *s = result.bestTranscription.formattedString;
        if ([s hasSuffix:@" "] == FALSE && !result.isFinal) {
            s = [NSString stringWithFormat:@"%@ ", s];
        }
        NSDump(s);
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
    
    // Create speech recognition request
    self.request = [[SFSpeechAudioBufferRecognitionRequest alloc] init];
    if (self.request == nil) {
        [self die:@"Error: Unable to initialize speech recognition request"];
    }
    self.request.shouldReportPartialResults = YES;
    self.request.requiresOnDeviceRecognition = self.useOnDeviceRecognition;
    
    // Create spech recognition task
    self.task = [self.recognizer recognitionTaskWithRequest:self.request
                                              resultHandler:
    ^(SFSpeechRecognitionResult * _Nullable result, NSError * _Nullable error) {
        if (error != nil) {
            NSPrintErr(@"Error: %@", error.localizedDescription);
            return;
        }
        
        // Print to stdout
        if (self.singleLineMode) {
            NSString *s = [NSString stringWithFormat:@"\33[2K\r%@",
                           result.bestTranscription.formattedString];
            NSDump(s);
        } else {
            NSPrint(result.bestTranscription.formattedString);
        }
        
        if (result.isFinal) {
            exit(EXIT_SUCCESS);
        }
    }];
    
    if (self.task == nil) {
        [self die:@"Error: Unable to initialize speech recognition task"];
    }
    
//    DLog(@"Creating engine");
    self.engine = [[AVAudioEngine alloc] init];
    AVAudioInputNode *inputNode = self.engine.inputNode;
    
    id recFmt = [inputNode outputFormatForBus:0];
        
    [inputNode installTapOnBus:0
                    bufferSize:1024
                        format:recFmt
                         block:
     ^(AVAudioPCMBuffer * _Nonnull buffer, AVAudioTime * _Nonnull when) {
        [(SFSpeechAudioBufferRecognitionRequest *)self.request appendAudioPCMBuffer:buffer];
    }];
    
//    DLog(@"Starting engine");
    NSError *err;
    [self.engine startAndReturnError:&err];
    if (err != nil) {
        [self die:[NSString stringWithFormat:@"Error starting audio engine: %@", [err localizedDescription]]];
    }
}

#pragma mark - Class methods

+ (NSArray<NSString *> *)supportedLanguages {
    NSMutableArray *localeIdentifiers = [NSMutableArray new];
    for (NSLocale *locale in [SFSpeechRecognizer supportedLocales]) {
        [localeIdentifiers addObject:[locale localeIdentifier]];
    }
    [localeIdentifiers sortUsingSelector:@selector(compare:)];
    return [localeIdentifiers copy];
}

+ (void)printSupportedLanguages {
    NSArray *localeIdentifiers = [Hear supportedLanguages];
    for (NSString *identifier in localeIdentifiers) {
        NSPrint(identifier);
    }
}

@end
