//
//  OOTextureGenerator.m
//  textureGeneratorTestRig
//
//  Created by Jens Ayton on 2009-12-15.
//  Copyright 2009 Jens Ayton. All rights reserved.
//

#import "OOTextureGenerator.h"


@implementation OOTextureGenerator

- (BOOL) isReady
{
	return _ready;
}


- (BOOL) enqueue
{
	return NO;
}

- (BOOL) getResult:(void **)outData
			format:(OOTextureDataFormat *)outFormat
			 width:(uint32_t *)outWidth
			height:(uint32_t *)outHeight
{
	*outData = data;
	*outFormat = format;
	*outWidth = width;
	*outHeight = height;
	
	return YES;
}


- (void) loadTexture
{
	
}


- (void) render
{
	[self loadTexture];
	_ready = YES;
}

@end
