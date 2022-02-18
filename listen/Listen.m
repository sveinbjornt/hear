//
//  Listen.m
//  listen
//
//  Created by Sveinbjorn Thordarson on 18.2.2022.
//

#import <Speech/Speech.h>
#import "Listen.h"
//#import "Common.h"

@interface Listen() {
}

@property (nonatomic, retain) AVAudioEngine *engine;
@property (nonatomic, retain) SFSpeechRecognizer *recognizer;
@property (nonatomic, retain) SFSpeechAudioBufferRecognitionRequest *request;
@property (nonatomic, retain) SFSpeechRecognitionTask *task;

@end

@implementation Listen

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    [self requestSpeechRecognitionPermission];
}

- (void)requestSpeechRecognitionPermission {
    
    [SFSpeechRecognizer requestAuthorization:^(SFSpeechRecognizerAuthorizationStatus authStatus) {
        switch (authStatus) {
            case SFSpeechRecognizerAuthorizationStatusAuthorized:
                //User gave access to speech recognition
                NSLog(@"Authorized");
                [self startListening];
                break;

            case SFSpeechRecognizerAuthorizationStatusDenied:
                // User denied access to speech recognition
                NSLog(@"SFSpeechRecognizerAuthorizationStatusDenied");
                break;

            case SFSpeechRecognizerAuthorizationStatusRestricted:
                // Speech recognition restricted on this device
                NSLog(@"SFSpeechRecognizerAuthorizationStatusRestricted");
                break;
                
            case SFSpeechRecognizerAuthorizationStatusNotDetermined:
                // Speech recognition not yet authorized
                break;
            
            default:
                break;
        }
    }];
}

- (void)exit {
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        [[NSApplication sharedApplication] terminate:self];
    }];
}

- (void)print:(NSString *)s {
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        printf("\r%s", [s cStringUsingEncoding:NSUTF8StringEncoding]);
        fflush(stdout);
    }];
}

- (void)speechRecognitionTask:(SFSpeechRecognitionTask *)task didFinishRecognition:(SFSpeechRecognitionResult *)recognitionResult {
    NSString *recognizedText = recognitionResult.bestTranscription.formattedString;
    NSLog(@"%@", recognizedText);
}

- (void)startListening {
    
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
        self.recognizer
    }
    
    
    self.request = [[SFSpeechAudioBufferRecognitionRequest alloc] init];
    if (self.request == nil) {
        NSLog(@"Unable to initialize speech recognition request");
        return;
    }
    
    self.request.shouldReportPartialResults = YES;
//    self.request.requiresOnDeviceRecognition = YES;
    
//    self.task = [self.recognizer recognitionTaskWithRequest:self.request delegate:self];
    self.task = [self.recognizer recognitionTaskWithRequest:self.request
                                              resultHandler:^(SFSpeechRecognitionResult * _Nullable result, NSError * _Nullable error) {
//        BOOL isFinal = result.isFinal;
        if (error != nil) {
            NSLog(@"Error: %@", error.localizedDescription);
            return;
        }
        NSString *s = result.bestTranscription.formattedString;
//        NSLog(@"Result: %@", s);
        [self print:s];
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
        [self exit];
    }
    

}

@end
