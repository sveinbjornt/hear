//
//  Common.h
//  listen
//
//  Created by Sveinbjorn Thordarson on 18.2.2022.
//

#import <Foundation/Foundation.h>


#define PROGRAM_VERSION 0.1

// Logging in debug mode only
#ifdef DEBUG
    #define DLog(...) NSLog(__VA_ARGS__)
#else
    #define DLog(...)
#endif


void NSPrint(NSString *format, ...);
void NSPrintErr(NSString *format, ...);

