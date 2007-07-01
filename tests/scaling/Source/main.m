//
//  main.m
//  scaling
//
//  Created by Jens Ayton on 2007-04-20.
//  Copyright Jens Ayton 2007. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "OOCPUInfo.h"
#import "OOLogging.h"
#import <OpenGL/gl.h>
#import "OOPListParsing.h"
#import "OOTextureLoader.h"


// Set to greater than 1 for stability testing or profiling.
#define ITERATIONS		1

#define DUMP_DATA		1
#define USE_POOL		1
#define USE_MIP_MAPPING	0


@interface ResourceManager: NSObject
+ (NSArray *)rootPaths;
@end


id gSharedUniverse = nil;


static NSString *sOutDirectory = nil;


static OOTextureLoader *GetTexture(NSString *name);
static void DumpTexture(OOTextureLoader *loader, NSString *name);


int main(int argc, char *argv[])
{
	[[NSAutoreleasePool alloc] init];
	
	OOLoggingInit();
	
	sOutDirectory = [NSSearchPathForDirectoriesInDomains(NSDesktopDirectory, NSUserDomainMask, YES) objectAtIndex:0];
	sOutDirectory = [sOutDirectory stringByAppendingPathComponent:@"Texture-dump"];
	[[NSFileManager defaultManager] createDirectoryAtPath:sOutDirectory attributes:NULL];
	
	#define TEST_TEXTURE(name)		do { id loader = GetTexture(name); if (loader != nil) DumpTexture(loader, name); } while (0)
	
	unsigned iter = ITERATIONS;
	while (iter--)
	{
#if USE_POOL
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
#endif
#if ITERATIONS > 1
		OOLog(@"scaleTest.iteration", @"Iteration %d", ITERATIONS - iter);
#endif
		// Problem texture from BlackMonks.oxp
		TEST_TEXTURE(@"beatletex");
		
		TEST_TEXTURE(@"grey200x200");
		TEST_TEXTURE(@"grey200x256");
		TEST_TEXTURE(@"grey256x200");
		TEST_TEXTURE(@"grey256x300");
		TEST_TEXTURE(@"grey300x200");
		TEST_TEXTURE(@"grey300x256");
		TEST_TEXTURE(@"rgb200x200");
		TEST_TEXTURE(@"rgb200x256");
		TEST_TEXTURE(@"rgb256x200");
		TEST_TEXTURE(@"rgb256x300");
		TEST_TEXTURE(@"rgb300x256");
		TEST_TEXTURE(@"rgb300x300");
		
#if USE_POOL
		[pool release];
#endif
	}
	return 0;
}


static OOTextureLoader *GetTexture(NSString *name)
{
	NSString *path = [[NSBundle mainBundle] pathForResource:name ofType:@"png"];
	if (path == nil)
	{
		OOLog(@"getTexture.fileNotFound", @"Could not find file %@.png", name);
		return nil;
	}
	
	uint32_t options = kOOTextureMagFilterLinear;
#if USE_MIP_MAPPING
	options |= kOOTextureMinFilterMipMap;
#endif
	OOTextureLoader *result = [OOTextureLoader loaderWithPath:path options:options];
	if (result == nil)
	{
		OOLog(@"getTexture.noLoader", @"Could not create loader for %@.png", name);
	}
	return result;
}


static void DumpTexture(OOTextureLoader *loader, NSString *name)
{
	void					*data = NULL;
	OOTextureDataFormat		format;
	uint32_t				width, height;
	uint8_t					planes;
	
	if (![loader getResult:&data format:&format width:&width height:&height])
	{
		OOLog(@"dumpTexture.noData", @"Could not get data for %@.png", name);
		return;
	}
	
	if (data == NULL)
	{
		OOLog(@"dumpTexture.noData", @"***** Loader returned OK for %@.png, but data is NULL!", name);
		return;
	}
	
	planes = OOTexturePlanesForFormat(format);
	if (planes == 0)
	{
		OOLog(@"dumpTexture.noData", @"***** Loader returned OK for %@.png, but format is invalid (%u)!", name, format);
		return;
	}
	
#if DUMP_DATA
	NSString				*dumpName = nil;
	NSString				*dumpPath = nil;
	NSData					*dumpData = nil;
	
	dumpName = [NSString stringWithFormat:@"%@ %ux%u@%u.raw", name, width, height, planes];
	dumpPath = [sOutDirectory stringByAppendingPathComponent:dumpName];
	dumpData = [NSData dataWithBytesNoCopy:data length:width * planes * height freeWhenDone:YES];
	[dumpData writeToFile:dumpPath atomically:NO];
	
	OOLog(@"dumpTexture.dump", @"Dumped %@.png to %@", name, dumpName);
#endif
}


/****** Shims *******
Everything beyond this point is stuff that's needed to link, but whose full
behaviour is not needed.
*/
unsigned OOCPUCount(void)
{
	return 1;
}


// Only used for GL_MAX_TEXTURE_SIZE
void glGetIntegerv(GLenum pname, GLint *params)
{
	if (pname == GL_MAX_TEXTURE_SIZE)
	{
		if (params != NULL)  *params = 4096;
	}
	else
	{
		OOLog(@"shim.glGetIntegerv", @"glGetIntegerv() called with unexpected pname=%u", pname);
	}
}


NSDictionary *OODictionaryFromFile(NSString *path)
{
	return [NSDictionary dictionaryWithContentsOfFile:path];
}

@implementation ResourceManager
+ (NSArray *)rootPaths
{
	return [NSArray arrayWithObject:[[NSBundle mainBundle] resourcePath]];
}
@end


float randf(void) { return 0; }
