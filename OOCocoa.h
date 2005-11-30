// Import OpenStep main headers and define some Macisms and other compatibility stuff.

#if defined(GNUSTEP) && !defined(OOLITE_SDL_MAC)

#define Boolean unsigned char
#define Byte unsigned char
#define true 1
#define false 0

#define kCGDisplayWidth (@"Width")
#define kCGDisplayHeight (@"Height")
#define kCGDisplayRefreshRate (@"RefreshRate")

#define IBOutlet /**/
#define IBAction void

typedef int32_t CGMouseDelta;

#endif

#import <math.h>
#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
