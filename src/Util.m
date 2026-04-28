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

#import "Util.h"

#import <Speech/Speech.h>

@implementation Util

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
+ (NSString *)stringFromTimeInterval:(NSTimeInterval)timeInterval {
    NSInteger interval = timeInterval;
    NSInteger ms = (fmod(timeInterval, 1) * 1000);
    long seconds = interval % 60;
    long minutes = (interval / 60) % 60;
    long hours = (interval / 3600);
    return [NSString stringWithFormat:@"%0.2ld:%0.2ld:%0.2ld,%0.3ld",
            hours, minutes, seconds, (long)ms];
}

@end
