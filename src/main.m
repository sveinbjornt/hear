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

#import <getopt.h>
#import <Foundation/Foundation.h>

#import "Common.h"
#import "Hear.h"


static BOOL IsRightOSVersion(void);
static void PrintVersion(void);
static void PrintHelp(void);


static const char optstring[] = "sl:i:f:dmhv";

static struct option long_options[] = {
    
    // List supported languages (locales for STT
    {"supported",                 no_argument,        0, 's'},
    // Specify language (locale) for STT
    {"language",                  required_argument,  0, 'l'},
    // Input (file path or "-" for stdin)
    {"input",                     required_argument,  0, 'i'},
    // Format (of input file or data)
    {"format",                    required_argument,  0, 'f'},
    // Use on-device speech recognition
    {"device",                    no_argument,        0, 'd'},
    // Enable single-line output mode (for mic)
    {"mode",                      no_argument,        0, 'm'},
    
    {"help",                      no_argument,        0, 'h'},
    {"version",                   no_argument,        0, 'v'},
    
    {0,                           0,                  0,  0 }
};


int main(int argc, const char * argv[]) { @autoreleasepool {
    
    // Make sure we're running on a macOS version that supports speech recognition
    if (IsRightOSVersion() == NO) {
        NSPrintErr(@"This program requires macOS 10.15 or later.");
        exit(EXIT_FAILURE);
    }
    
    NSString *language = DEFAULT_LOCALE;
    NSString *inputFilename;
    NSString *inputFormat;
    BOOL useOnDeviceRecognition = NO;
    BOOL singleLineMode = NO;
    
    // Parse arguments
    int optch;
    int long_index = 0;
    
    while ((optch = getopt_long(argc, (char *const *)argv, optstring, long_options, &long_index)) != -1) {
        switch (optch) {
            
            // Print list of supported languages
            case 's':
                [Hear printSupportedLanguages];
                exit(EXIT_SUCCESS);
                break;
            
            // Set language (i.e. locale) for speech recognition
            case 'l':
                language = @(optarg);
                break;
            
            // Input filename ("-" for stdin)
            case 'i':
                inputFilename = @(optarg);
                break;
            
            // Input audio format (only required if getting data via stdin)
            case 'f':
                inputFormat = @(optarg);
                break;
            
            // Use on-device speech recognition
            case 'd':
                useOnDeviceRecognition = YES;
                break;
            
            // Use single line mode when showing transcription of mic input
            case 'm':
                singleLineMode = YES;
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
    Hear *hear = [[Hear alloc] initWithLanguage:language
                                          input:inputFilename
                                         format:inputFormat
                                       onDevice:useOnDeviceRecognition
                                 singleLineMode:singleLineMode];
    [[NSApplication sharedApplication] setDelegate:hear];
    [[NSApplication sharedApplication] run];
    
    return EXIT_SUCCESS;
}}

#pragma mark -

static BOOL IsRightOSVersion() {
    // The Speech Recognition API wasn't introduced until macOS 10.15
    NSOperatingSystemVersion osVersion = {0};
    osVersion.majorVersion = 10;
    osVersion.minorVersion = 15;
    return [[NSProcessInfo processInfo] isOperatingSystemAtLeastVersion:osVersion];
}

static void PrintVersion(void) {
    NSPrint(@"%@ version %@ by %@", PROGRAM_NAME, PROGRAM_VERSION, PROGRAM_AUTHOR);
}

static void PrintHelp(void) {
    PrintVersion();
    NSPrint(@"\n\
%@ [-s] [-l lang] [-i file] [-f fmt] [-d]\n\
\n\
Options:\n\
\n\
    -s --supported          Print list of supported languages\n\
\n\
    -l --language           Specify speech recognition language\n\
    -i --input [file_path]  Specify audio file to process\n\
    -f --format [fmt]       Specify audio file format (for stdin)\n\
    -d --device             Only use on-device speech recognition\n\
    -m --mode               Enable single-line output mode (mic only)\n\
\n\
    -h --help               Prints help\n\
    -v --version            Prints program name and version\n\
\n\
For further details, see 'man %@'.", PROGRAM_NAME, PROGRAM_NAME);
}

