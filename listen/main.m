//
//  main.m
//  listen
//
//  Created by Sveinbjorn Thordarson on 18.2.2022.
//

#import <Foundation/Foundation.h>
#import "Listen.h"

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        Listen *listener = [Listen new];
        [[NSApplication sharedApplication] setDelegate:listener];
        [[NSApplication sharedApplication] run];
    }
    return 0;
}
