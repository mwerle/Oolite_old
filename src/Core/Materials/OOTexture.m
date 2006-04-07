//
//  OOTexture.m
//  Oolite
//
//  Created by Jens Ayton on 2005-12-31.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "OOTexture.h"
#import "MathsUtils.h"
#import "ResourceManager.h"
#import "TextureUtilities.h"

#ifndef GNUSTEP
#import <QuickTime/QuickTime.h>
#endif


#ifndef USE_ASYNCHRONOUS_LOADING
#define USE_ASYNCHRONOUS_LOADING		0
#endif


#if __BIG_ENDIAN__
	#define ARGB_IMAGE_TYPE GL_UNSIGNED_INT_8_8_8_8_REV
#else
	#define ARGB_IMAGE_TYPE GL_UNSIGNED_INT_8_8_8_8
#endif


static BOOL ClientStorageAvailable(void);
static BOOL EnableClientStorage(void);

static unsigned GetMaxTextureSize(void);


enum
{
	// Numerical messages between threads
	kMsgLoadTexture,
	kMsgExit
};


typedef struct
{
	OOTexture				*texture;
	NSString				*name;
} LoadTextureData;


#define kTextureLoadQueueRunLoopMode		NSDefaultRunLoopMode


static NSMutableDictionary	*sTextureCache = nil;

static unsigned				sMaxTextureSize = 0;

#if USE_ASYNCHRONOUS_LOADING
	static BOOL					sLoadThreadIsRunning = NO;
	static NSPort				*sLoadRequestPort = nil;
	
	static unsigned				sMessageRcv;
	static NSArray				*sComponentsRcv = nil;
	// A stack of textures where asynchronously loaded textures go, in order to be bound when +update is called.
	static OOTexture			*sLoadedTextures = nil;
	static NSLock				*sLoadedTexLock = nil;
#endif


@interface OOTexture(Private)

- (id)initWithImageNamed:(NSString *)inName allowMipMap:(BOOL)inAllowMipMap;
- (void)loadTextureNamed:(NSString *)inTexture;

+ (void)textureLoadThread:unused;
+ (void)handlePortMessage:(NSPortMessage *)inMessage;

@end


@implementation OOTexture

+ (id)textureWithImageNamed:(NSString *)inName allowMipMap:(BOOL)inAllowMipMap
{
	id						result;
	
	result = [sTextureCache objectForKey:inName];
	if (nil == result)
	{
		result = [[OOTexture alloc] initWithImageNamed:inName allowMipMap:inAllowMipMap];
		if (nil != result)
		{
			[result autorelease];
			if (nil == sTextureCache) sTextureCache = [[NSMutableDictionary alloc] init];
			[sTextureCache setObject:result forKey:inName];
		}
	}
	
	return result;
}


- (id)initWithImageNamed:(NSString *)inName allowMipMap:(BOOL)inAllowMipMap
{
	#if USE_ASYNCHRONOUS_LOADING
		NSPortMessage			*loadRequest;
		LoadTextureData			msgData;
		NSArray					*msgComponents;
	#endif
	
	if (0 == sMaxTextureSize)
	{
		// Set-up
		sMaxTextureSize = GetMaxTextureSize();
	}
	
	self = [super init];
	if (nil != self)
	{
		mipmapped = inAllowMipMap;
		glGenTextures(1, &texName);
		
		#if USE_ASYNCHRONOUS_LOADING
			// Set up texture-loading thread if necessary
			if (!sLoadThreadIsRunning)
			{
				sLoadRequestPort = [[NSPort port] retain];///[[NSMessagePort alloc] init];
				if (nil != sLoadRequestPort)
				{
					sLoadedTexLock = [[NSLock alloc] init];
					if (nil != sLoadedTexLock)
					{
						[NSThread detachNewThreadSelector:@selector(textureLoadThread:) toTarget:[self class] withObject:nil];
						sLoadThreadIsRunning = YES;
					}
					else
					{
						[sLoadRequestPort release];
						sLoadRequestPort = nil;
					}
				}
				else
				{
					NSLog(@"Failed to start texture-loading thread.");
				}
			}
			
			// Send load request to texture-loading thread
			msgData.texture = [self retain];
			msgData.name = [inName retain];
			msgComponents = [NSArray arrayWithObject:[NSData dataWithBytes:(const void *)&msgData length:sizeof msgData]];
			
			loadRequest = [[NSPortMessage alloc] initWithSendPort:sLoadRequestPort receivePort:nil
							components:msgComponents];
			[loadRequest setMsgid:kMsgLoadTexture];
			
			[loadRequest sendBeforeDate:[NSDate distantFuture]];
		#else
			[self loadTextureNamed:inName];
			[self bind];
		#endif
	}
	return self;
}


#if USE_ASYNCHRONOUS_LOADING

+ (void)textureLoadThread:unused
{
	NSAutoreleasePool		*rootPool, *pool;
	NSRunLoop				*loop;
	BOOL					exit = NO;
	LoadTextureData			*loadTex;
	
	assert(nil != sLoadRequestPort);
	
	rootPool = [[NSAutoreleasePool alloc] init];
	NSLog(@"Texture-loading thread started.");
	loop = [NSRunLoop currentRunLoop];
	
	[sLoadRequestPort setDelegate:self];
	[loop addPort:sLoadRequestPort forMode:kTextureLoadQueueRunLoopMode];
	
	do
	{
		pool = [[NSAutoreleasePool alloc] init];
		[loop acceptInputForMode:kTextureLoadQueueRunLoopMode beforeDate:[NSDate distantFuture]];
		
		switch (sMessageRcv)
		{
			case kMsgLoadTexture:
				loadTex = (LoadTextureData *)[[sComponentsRcv objectAtIndex:0] bytes];
				NSLog(@"Texture loading thread got load message for %@", loadTex->name);
				[loadTex->texture loadTextureNamed:loadTex->name];
				[loadTex->name release];
				
				// Put loaded texture on stack for +update.
				[sLoadedTexLock lock];
				loadTex->texture->link = sLoadedTextures;
				sLoadedTextures = loadTex->texture;
				[sLoadedTexLock unlock];
				break;
			
			case kMsgExit:
				exit = YES;
				break;
		}
		
		[sComponentsRcv release];
		sComponentsRcv = nil;
		[pool release];
	}
	while (!exit);
	
	NSLog(@"Texture-loading thread exiting.");
	
	[loop removePort:sLoadRequestPort forMode:kTextureLoadQueueRunLoopMode];
	[rootPool release];
	[sLoadRequestPort release];
}


+ (void)handlePortMessage:(NSPortMessage *)inMessage
{
	sMessageRcv = [inMessage msgid];
	sComponentsRcv = [[inMessage components] retain];
}

#endif // USE_ASYNCHRONOUS_LOADING


+ (void)update
{
	#if USE_ASYNCHRONOUS_LOADING
		OOTexture			*tex;
		
		if (nil != sLoadedTextures)
		{
			[sLoadedTexLock lock];
			while (sLoadedTextures)
			{
				tex = sLoadedTextures;
				sLoadedTextures = tex->link;
				
				[tex bind];
				
				[tex release];	// Balances retain in initWithImageNamed:…
			}
			[sLoadedTexLock unlock];
		}
	#endif
}


#ifndef GNUSTEP

- (void)loadTextureNamed:(NSString *)inName
{
	OSStatus				err = noErr;
	FSSpec					fsSpec;
	ComponentInstance		importer = NULL;
	Rect					bounds;
	unsigned				w, h;
	CGImageRef				image = NULL;
	char					*ptr;
	size_t					dataSize;
	CGContextRef			context = NULL;
	CGColorSpaceRef			colorSpace = NULL;
	
	data = NULL;
	
	// Find and load image
	err = [ResourceManager getFSSpec:&fsSpec forFileNamed:inName inFolder:@"Textures"];
	if (!err) err = GetGraphicsImporterForFile(&fsSpec, &importer);
	
	// Determine dimensions
	if (!err) err = GraphicsImportGetNaturalBounds(importer, &bounds);
	if (!err)
	{
		if (bounds.left < bounds.right) width = bounds.right - bounds.left;
		else width = bounds.left - bounds.right;
		if (bounds.top < bounds.bottom) height = bounds.bottom - bounds.top;
		else height = bounds.top - bounds.bottom;
		
		w = RoundUpToPowerOf2(width * 3 / 4);
		h = RoundUpToPowerOf2(height * 3 / 4);
		
		if (sMaxTextureSize < w) w = sMaxTextureSize;
		if (sMaxTextureSize < h) h = sMaxTextureSize;
		
		if (w != width || h != height)
		{
			NSLog(@"WARNING: The texture %@ has non-power-of two dimensions (%u x %u); it is being scaled to %u x %u.", inName, width, height, w, h);
			width = w;
			height = h;
		}
	}
	
	// Load image
	if (!err) err = GraphicsImportCreateCGImage(importer, &image, kGraphicsImportCreateCGImageUsingCurrentSettings);
	if (NULL != importer) CloseComponent(importer);
	
	// Set up buffer
	if (!err)
	{
		dataSize = w * h * 4;
		if (mipmapped) dataSize = dataSize * 4 / 3;
		data = malloc(dataSize);
		
		if (NULL == data && mipmapped)
		{
			mipmapped = NO;
			dataSize = w * h * 4;
			data = malloc(dataSize);
		}
		
		if (NULL == data)
		{
			err = memFullErr;
		}
		ptr = data;
	}
	
	// Draw image at each mip level
	if (!err)
	{
		colorSpace = CGColorSpaceCreateDeviceRGB();
		do
		{
			context = CGBitmapContextCreate(ptr, w, h, 8, w * 4, colorSpace, kCGImageAlphaPremultipliedFirst);
			if (NULL == context)
			{
				err = coreFoundationUnknownErr;
				break;
			}
			
			CGContextSetInterpolationQuality(context, kCGInterpolationHigh);
			CGContextDrawImage(context, CGRectMake(0, 0, w, h), image);
			
			CFRelease(context);
			
			ptr += w * h * 4;
			
			w /= 2;
			h /= 2;
		} while (1 < w && 1 < h && mipmapped);
		
		if (NULL != colorSpace) CFRelease(colorSpace);
	}
	
	if (NULL != image) CGImageRelease(image);
	
	if (err)
	{
		if (data)
		{
			free(data);
			data = NULL;
		}
		NSLog(@"Loading of texture %@ failed (error %i).", inName, err);
	}
	else loaded = YES;
}

#else

#error Missing GNUStep/SDL implementation of -[OOTexture loadTextureNamed:]

#endif


- (void)dealloc
{
	if (NULL != data) free(data);
	
	if (0 != texName)
	{
		NSLog(@"Warning: texture %@ released without -destroy being called.", self);
	}
	
	[super dealloc];
}


- (void)destroy
{
	if (0 != texName)
	{
		glDeleteTextures(1, &texName);
		texName = 0;
	}
	
	if (NULL != data)
	{
		free(data);
		data = NULL;
	}
}


- (void)bind
{
	GLuint						w, h;
	const uint8_t				*mipmapPtr;
	GLuint						level;
	BOOL						clientStorage;
	
	glBindTexture(GL_TEXTURE_2D, texName);
	
	if (loaded && !setUp)
	{
		// Set up texture
		clientStorage = ClientStorageAvailable();
		if (clientStorage) clientStorage = EnableClientStorage();
		
		#ifdef GL_TEXTURE_MAX_ANISOTROPY_EXT
		if (mipmapped) glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAX_ANISOTROPY_EXT, 4.0);
		#endif
		
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, mipmapped ? GL_LINEAR_MIPMAP_LINEAR : GL_LINEAR);
		
		// Register the mip levels
		mipmapPtr = data;
		w = width;
		h = height;
		level = 0;
		do
		{
			glTexImage2D(GL_TEXTURE_2D, level++, GL_RGBA, w, h, 0, GL_BGRA, GL_UNSIGNED_INT_8_8_8_8_REV, mipmapPtr);
			
			mipmapPtr += w * h * 4;
			
			w /= 2;
			h /= 2;
		} while (1 < w && 1 < h && mipmapped);
		
		if (mipmapped)
		{
			glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAX_LEVEL, level - 1);
		}
		
		if (!clientStorage)
		{
			free(data);
			data = NULL;
		}
		
		setUp = YES;
	}
}


- (GLuint)textureName
{
	return texName;
}


- (NSSize)size
{
	return NSMakeSize(width, height);
}


- (NSString *)description
{
	return [NSString stringWithFormat:@"<%s %p>{%u, %u x %u pixels%s}", object_getClassName(self), self, texName, width, height, mipmapped ? ", mipmapped" : ""];
}

@end


static BOOL ClientStorageAvailable(void)
{
	#ifdef GL_UNPACK_CLIENT_STORAGE_APPLE
		static BOOL				tested = NO, available;
		const GLubyte			*extensions;
		
		if (!tested)
		{
			extensions = glGetString(GL_EXTENSIONS);
			if (NULL != strstr((const char *)extensions, "GL_APPLE_client_storage"))
			{
				NSLog(@"GL_APPLE_client_storage available.");
				available = YES;
			}
			else
			{
				NSLog(@"GL_APPLE_client_storage not found in %s", extensions);
				available = NO;
			}
			
			tested = YES;
		}
		
		return available;
	#else
		// Generic implementation - add other equivalent extensions as #elif cases
		return NO;
	#endif
}


static BOOL EnableClientStorage(void)
{
	#ifdef GL_UNPACK_CLIENT_STORAGE_APPLE
		glPixelStorei(GL_UNPACK_CLIENT_STORAGE_APPLE, 1);
		return YES;
	#else
		// Generic implementation - add other equivalent extensions as #elif cases
		return NO;
	#endif
}


static unsigned GetMaxTextureSize(void)
{
	GLint				result;
	NSNumber			*override;
	GLint				value;
	
	glGetIntegerv(GL_MAX_TEXTURE_SIZE, &result);
	
	override = [[NSUserDefaults standardUserDefaults] objectForKey:@"texture maximum size"];
	if (nil != override)
	{
		value = [override intValue];
		if (value < result) result = value;
	}
	
	return result;
}
