#ifndef OOLITE_LINUX
#define OOLITE_LINUX
/* 
 *
 * oolite-linux.h: Includes, definitions and pathnames for Linux
 * systems.
 *
 * Dylan Smith, 2005-04-19
 *
 */

#include <math.h>

#ifndef OOLITE_SDL_MAC

#include "SDL.h"
#include "SDL_opengl.h"
#include "SDL_mixer.h"
#include "SDL_syswm.h"

// Macintosh compatibility defines
#define kCGDisplayWidth (@"Width")
#define kCGDisplayHeight (@"Height")
#define kCGDisplayRefreshRate (@"RefreshRate")

#define IBOutlet /**/
#define IBAction void

typedef int32_t CGMouseDelta;

#endif

#define MAX_CHANNELS 16

#endif /* OOLITE_LINUX */
