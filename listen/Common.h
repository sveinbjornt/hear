//
//  Common.h
//  listen
//
//  Created by Sveinbjorn Thordarson on 18.2.2022.
//

#import <Foundation/Foundation.h>


// Logging in debug mode only
#ifdef DEBUG
    #define DLog(...) NSLog(__VA_ARGS__)
#else
    #define DLog(...)
#endif


static void NSPrint(NSString *format, ...);
static void NSPrintErr(NSString *format, ...);

