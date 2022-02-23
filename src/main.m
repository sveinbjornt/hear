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

#import <getopt.h>

#import <Foundation/Foundation.h>

#import "Common.h"
#import "Listen.h"

static void PrintVersion(void);
static void PrintHelp(void);


static const char optstring[] = "li:f:dhv";

static struct option long_options[] = {

    {"list",                      required_argument,  0, 'l'}, // List available languages for STT
    {"input",                     required_argument,  0, 'i'}, // Input (file path or - for stdin)
    {"format",                    required_argument,  0, 'f'}, // Format (of input file or data)
    {"device",                    no_argument,        0, 'd'}, // Use on-device speech recognition
    //{"raw",                       required_argument,  0, 'r'}, // Raw output
    
    {"help",                      no_argument,        0, 'h'},
    {"version",                   no_argument,        0, 'v'},
    
    {0,                           0,                  0,  0 }
};


int main(int argc, const char * argv[]) { @autoreleasepool {
    
    NSString *inputFilename;
    NSString *inputFormat;
    BOOL useOnDeviceRecognition = FALSE;
    
    int optch;
    int long_index = 0;
    
    while ((optch = getopt_long(argc, (char *const *)argv, optstring, long_options, &long_index)) != -1) {
        switch (optch) {
            
            // Print list of supported languages
            case 'l':
                [Listen printSupportedLanguages];
                exit(EXIT_SUCCESS);
                break;
            
            // Input filename ("-" for stdin)
            case 'i':
                inputFilename = @(optarg);
                break;
            
            // Input audio format
            case 'f':
                inputFormat = @(optarg);
                break;
            
            // Use on-device speech recognition
            case 'd':
                useOnDeviceRecognition = YES;
                break;
            
            // Print version
            case 'v':
                PrintVersion();
                exit(EXIT_SUCCESS);
                break;
            
            // Print help text with list of options
            case 'h':
            default:
                PrintHelp();
                exit(EXIT_SUCCESS);
                break;
        }
    }

    Listen *listener = [[Listen alloc] initWithInput:inputFilename
                                              format:inputFormat
                                            onDevice:useOnDeviceRecognition];
    [[NSApplication sharedApplication] setDelegate:listener];
    [[NSApplication sharedApplication] run];

    return EXIT_SUCCESS;
}}

#pragma mark -

static void PrintVersion(void) {
    NSPrint(@"listen version %@", PROGRAM_VERSION);
}

static void PrintHelp(void) {
    PrintVersion();
    
    NSPrint(@"\n\
listen [-l] [-i file] [-f fmt]\n\
\n\
Options:\n\
\n\
    -l --list               Print list of supported languages\n\
\n\
    -i --input [file_path]  Specify audio file to process\n\
    -f --format [fmt]       Specify audio file format\n\
    -d --device             Only use on-device speech recognition\n\
\n\
    -h --help               Prints help\n\
    -v --version            Prints program name and version\n\
\n\
For further details, see 'man listen'.");
}

