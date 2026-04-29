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

@import AVFoundation;
#import <math.h>

@implementation Util

+ (BOOL)isFileSupportedByAVFoundation:(NSString *)filePath hasAudioTrack:(BOOL *)audioPresent {
    if (audioPresent != NULL) {
        *audioPresent = NO;
    }
    
    NSURL *fileURL = [NSURL fileURLWithPath:filePath];
    if (fileURL == nil) {
        return NO;
    }
    
    // Using AVURLAssetPreferPreciseDurationAndTimingKey can sometimes
    // trigger more thorough format checks during initialization.
    NSDictionary *options = @{ AVURLAssetPreferPreciseDurationAndTimingKey : @(YES) };
    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:fileURL options:options];
    if (asset == nil || ![asset isReadable]) {
        return NO;
    }
    
    if (audioPresent != NULL) {
        *audioPresent = ([[asset tracksWithMediaType:AVMediaTypeAudio] count] > 0);
    }
    return YES;
}

// Formats a time interval as an SRT-style HH:MM:SS,mmm timestamp.
// Rounds to the nearest millisecond and decomposes from total ms so any
// rounding carry propagates correctly into the seconds field. Negative
// inputs are clamped to zero, since SRT has no negative-timestamp form.
+ (NSString *)stringFromTimeInterval:(NSTimeInterval)timeInterval {
    if (timeInterval < 0 || isnan(timeInterval)) {
        timeInterval = 0;
    }
    long long total_ms = llround(timeInterval * 1000.0);
    long ms      = (long)(total_ms % 1000);
    long long s  = total_ms / 1000;
    long seconds = (long)(s % 60);
    long minutes = (long)((s / 60) % 60);
    long hours   = (long)(s / 3600);
    return [NSString stringWithFormat:@"%02ld:%02ld:%02ld,%03ld",
            hours, minutes, seconds, ms];
}

@end
