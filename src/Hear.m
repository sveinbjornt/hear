/*
    hear - Command line speech recognition for macOS

    Copyright (c) 2022-2023 Sveinbjorn Thordarson <sveinbjorn@sveinbjorn.org>
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

@interface Hear()

@property (nonatomic, retain) SFSpeechRecognizer *recognizer;
@property (nonatomic, retain) SFSpeechRecognitionRequest *request;
@property (nonatomic, retain) SFSpeechRecognitionTask *task;

@property (nonatomic, retain) AVAudioEngine *engine;

@property (nonatomic, retain) NSString *language;
@property (nonatomic, retain) NSString *inputFile;
@property (nonatomic) BOOL useDeviceInput;
@property (nonatomic) BOOL useOnDeviceRecognition;
@property (nonatomic) BOOL singleLineMode;
@property (nonatomic, retain) NSString *exitWord;

@end

@implementation Hear

- (instancetype)initWithLanguage:(NSString *)language
                           input:(NSString *)input
                        onDevice:(BOOL)onDevice
                  singleLineMode:(BOOL)singleLine
                        exitWord:(NSString *)exitWord {
    self = [super init];
    if (self) {
        
        if ([[Hear supportedLanguages] containsObject:language] == NO) {
            NSPrintErr(@"Locale '%@' not supported. Run with -s flag to see list of supported locales", language);
            exit(EXIT_FAILURE);
        }
        
        self.language = language;
        self.inputFile = input;
        self.useOnDeviceRecognition = onDevice;
        self.singleLineMode = singleLine;
        self.useDeviceInput = (input == nil);
        self.exitWord = exitWord;
    }
    return self;
}

#pragma mark - NSApplicationDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    [self requestSpeechRecognitionPermission];
}

#pragma mark -

- (void)die:(NSString *)errMsg {
    NSString *msg = [NSString stringWithFormat:@"Error: %@", errMsg];
    NSPrintErr(msg);
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

- (void)initRecognizer {
    // Initialize speech recognizer
    NSLocale *locale = [NSLocale localeWithLocaleIdentifier:self.language];
    self.recognizer = [[SFSpeechRecognizer alloc] initWithLocale:locale];
    if (self.recognizer == nil) {
        [self die:@"Unable to initialize speech recognizer"];
    }
    self.recognizer.delegate = self;
    
    // Make sure recognition is available
    if (self.recognizer.isAvailable == NO) {
        [self die:@"Speech recognizer not available. Try enabling Siri in System Preferences/Settings."];
    }
    
    if (self.useOnDeviceRecognition && !self.recognizer.supportsOnDeviceRecognition) {
        [self die:[NSString stringWithFormat:@"On-device recognition is not supported for locale '%@'", self.language]];
    }
}

- (void)runTask {
    if (self.useDeviceInput) {
        [self startListening];
    } else {
        [self processFile];
    }
}

- (void)processFile {
    
    NSString *filePath = self.inputFile;
    if ([[NSFileManager defaultManager] fileExistsAtPath:filePath] == NO) {
        [self die:[NSString stringWithFormat:@"No file at path %@", filePath]];
    }
    
    // OK, the file exists, let's try to run speech recognition on it
    [self initRecognizer];
    
    // Create speech recognition request with file URL
    NSURL *fileURL = [NSURL fileURLWithPath:filePath];
    self.request = [[SFSpeechURLRecognitionRequest alloc] initWithURL:fileURL];
    if (self.request == nil) {
        [self die:@"Unable to initialize speech recognition request"];
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
        
        if (result == nil) {
            return;
        }
        
        // Make sure there's a space between the incoming resulting strings
        NSString *s = result.bestTranscription.formattedString;
        if ([s hasSuffix:@" "] == FALSE && !result.isFinal) {
            s = [NSString stringWithFormat:@"%@ ", s];
        }
        
        // Print w/o newline to stdout and flush
        NSDump(s);
        
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

- (void)startListening {
    
    [self initRecognizer];
    
    // Create speech recognition request
    self.request = [[SFSpeechAudioBufferRecognitionRequest alloc] init];
    if (self.request == nil) {
        [self die:@"Unable to initialize speech recognition request"];
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
        NSString *transcript = result.bestTranscription.formattedString;
        if (self.singleLineMode) {
            // Erase current line and move cursor to the start of the line before printing
            NSString *s = [NSString stringWithFormat:@"\33[2K\r%@", transcript];
            NSDump(s);
        } else {
            NSPrint(transcript);
        }
        
        NSString *exitWord = [self.exitWord lowercaseString];
        NSString *exitSuffix = [[NSString stringWithFormat:@" %@", exitWord] lowercaseString];
        NSString *tsLower = [transcript lowercaseString];
        if (self.exitWord != nil && ([tsLower hasSuffix:exitSuffix] || [tsLower isEqualToString:exitWord])) {
            // Exit word identified, we're done
            exit(EXIT_SUCCESS);
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
        [self die:[NSString stringWithFormat:@"Failed to start audio engine: %@", [err localizedDescription]]];
    }
}

#pragma mark - Class methods

+ (NSArray<NSString *> *)supportedLanguages {
    NSMutableArray *localeIdentifiers = [NSMutableArray new];
    for (NSLocale *locale in [SFSpeechRecognizer supportedLocales]) {
        [localeIdentifiers addObject:[locale localeIdentifier]];
    }
    [localeIdentifiers sortUsingSelector:@selector(compare:)];
    return localeIdentifiers;
}

+ (void)printSupportedLanguages {
    NSArray<NSString *> *localeIdentifiers = [Hear supportedLanguages];
    NSPrint([localeIdentifiers componentsJoinedByString:@"\n"]);
}

@end
