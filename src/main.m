/*
    hear - Command line speech recognition for macOS

    Copyright (c) 2022-2024 Sveinbjorn Thordarson <sveinbjorn@sveinbjorn.org>
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

#import <getopt.h>
#import <Foundation/Foundation.h>

#import "Common.h"
#import "Hear.h"


// Prototypes
static inline BOOL IsRightOSVersion(void);
static inline void PrintVersion(void);
static inline void PrintHelp(void);

// Command line options
static const char optstring[] = "sl:i:dpmx:t:Thv";

static struct option long_options[] = {
    // List supported locales for speech to text
    {"supported",                 no_argument,        0, 's'},
    // Specify locale for STT
    {"locale",                    required_argument,  0, 'l'},
    // Input (file path)
    {"input",                     required_argument,  0, 'i'},
    // Use on-device speech recognition
    {"device",                    no_argument,        0, 'd'},
    // Whether to add punctuation to speech recognition results
    {"punctuation",               no_argument,        0, 'p'},
    // Whether to add timestamps when reading from a file
    {"timestamp",                 no_argument,        0, 'T'},
    // Enable single-line output mode (for mic)
    {"mode",                      no_argument,        0, 'm'},
    // Exit word
    {"exit-word",                 required_argument,  0, 'x'},
    // Timeout (in seconds)
    {"timeout",                   required_argument,  0, 'x'},
    // Print help
    {"help",                      no_argument,        0, 'h'},
    // Print version
    {"version",                   no_argument,        0, 'v'},
    {0,                           0,                  0,  0 },
};


int main(int argc, const char * argv[]) { @autoreleasepool {
    
    // Make sure we're running on a macOS version that supports speech recognition
    if (IsRightOSVersion() == NO) {
        NSPrintErr(@"This program requires macOS Catalina 10.15 or later.");
        exit(EXIT_FAILURE);
    }
    
    NSString *locale = DEFAULT_LOCALE;
    NSString *inputFilename;
    NSString *exitWord;
    BOOL useOnDeviceRecognition = NO;
    BOOL singleLineMode = NO;
    BOOL addsPunctuation = NO;
    BOOL addsTimestamps = NO;
    CGFloat timeout = 0.0f;
    
    // Parse arguments
    int optch;
    int long_index = 0;
    
    while ((optch = getopt_long(argc, (char *const *)argv, optstring, long_options, &long_index)) != -1) {
        switch (optch) {
            
            // Print list of supported locales
            case 's':
                [Hear printSupportedLocales];
                exit(EXIT_SUCCESS);
                break;
            
            // Set locale for speech recognition
            case 'l':
                locale = @(optarg);
                break;
            
            // Input filename (path)
            case 'i':
                inputFilename = @(optarg);
                break;
            
            // Use on-device speech recognition
            case 'd':
                useOnDeviceRecognition = YES;
                break;
            
            // Use single line mode when showing transcription of mic input
            case 'm':
                singleLineMode = YES;
                break;
            
            // Whether to add punctuation to speech recognition results
            // This option is ignored on macOS versions prior to Ventura
            case 'p':
                addsPunctuation = YES;
                break;

            // Whether to add timestamps to speech recognition results
            // This option is ignored on macOS versions prior to Ventura
            case 'T':
                addsTimestamps = YES;
                break;
            
            // Set exit word (causes app to exit when word detected in speech)
            case 'x':
                exitWord = @(optarg);
                break;
            
            case 't':
                timeout = [@(optarg) floatValue];
                break;
            
            // Print version
            case 'v':
                PrintVersion();
                exit(EXIT_SUCCESS);
                break;
            
            // Print help text with list of option flags
            case 'h':
            default:
                PrintHelp();
                exit(EXIT_SUCCESS);
                break;
        }
    }
    
    // Instantiate app delegate object with core program functionality
    Hear *hear = [[Hear alloc] initWithLocale:locale
                                        input:inputFilename
                                     onDevice:useOnDeviceRecognition
                               singleLineMode:singleLineMode
                               addPunctuation:addsPunctuation
                                addTimestamps:addsTimestamps
                                     exitWord:exitWord
                                      timeout:timeout];
    [[NSApplication sharedApplication] setDelegate:hear];
    [NSApp run];
    
    return EXIT_SUCCESS;
}}

#pragma mark -

static inline BOOL IsRightOSVersion(void) {
    // The Speech Recognition API wasn't introduced until macOS 10.15
    NSOperatingSystemVersion osVersion = {0};
    osVersion.majorVersion = 10;
    osVersion.minorVersion = 15;
    return [[NSProcessInfo processInfo] isOperatingSystemAtLeastVersion:osVersion];
}

static inline void PrintVersion(void) {
    NSPrint(@"%@ version %@ by %@ <%@>", PROGRAM_NAME, PROGRAM_VERSION,
            PROGRAM_AUTHOR, PROGRAM_AUTHOR_EMAIL);
}

static inline void PrintHelp(void) {
    PrintVersion();
    NSPrint(@"\n\
%@ [-vhmsdp] [-l lang] [-i file] [-x word] [-t seconds]\n\
\n\
Options:\n\
\n\
    -s --supported          Print list of supported locales\n\
\n\
    -l --locale             Specify speech recognition locale\n\
    -i --input [file_path]  Specify audio file to process\n\
    -d --device             Only use on-device speech recognition\n\
    -m --mode               Enable single-line output mode (mic only)\n\
    -p --punctuation        Add punctuation to speech recognition results (macOS 13+)\n\
    -x --exit-word          Set exit word that causes program to quit\n\
    -t --timeout            Set silence timeout (in seconds)\n\
    -T --timestamps         Write timestamps as transcription occurs\n\
\n\
    -h --help               Prints help\n\
    -v --version            Prints program name and version\n\
\n\
For further details, see 'man %@'.", PROGRAM_NAME, PROGRAM_NAME);
}

