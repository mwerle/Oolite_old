//
//  OOMaterial.m
//  Oolite
//
//  Created by Jens Ayton on 2005-12-31.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "OOMaterial.h"
#import "OOTexture.h"
#import "MathsUtils.h"

NSString *kOOMaterialSpecularColor		= @"specular color";
NSString *kOOMaterialSpecularExponent	= @"specular exponent";
NSString *kOOMaterialAllowMipMap		= @"allow mip-mapping";


@implementation OOMaterial

- (id)init
{
	NSLog(@"%s: use -initWithMainTextureName: instead.");
	[self release];
	return nil;
}


- (id)initWithMainTextureName:(NSString *)inTextureName options:(NSDictionary *)inOptions
{
	BOOL				allowMipMap = YES;
	id					object;
	float				r, g, b;
	
	self = [super init];
	if (nil != self)
	{
		object = [inOptions objectForKey:kOOMaterialAllowMipMap];
		if (nil != object) allowMipMap = [object boolValue];
		
		mainTexture = [[OOTexture textureWithImageNamed:inTextureName allowMipMap:allowMipMap] retain];
		
		// Load options from dictionary, if present
		object = [inOptions objectForKey:kOOMaterialSpecularColor];
		if ([object isKindOfClass:[NSArray class]] && 3 <= [object count])
		{
			r = [[object objectAtIndex:0] floatValue];
			g = [[object objectAtIndex:1] floatValue];
			b = [[object objectAtIndex:2] floatValue];
			
			[self setSpecularColor3f:r:g:b];
		}
		specColor[4] = 1.0f;
		
		object = [inOptions objectForKey:kOOMaterialSpecularExponent];
		if (nil != object) [self setSpecularExponent:[object floatValue]];
	}
	return self;
}


- (void)dealloc
{
	[mainTexture release];
	
	[super dealloc];
}


- (void)activate
{
	[mainTexture bind];
	glMaterialfv(GL_FRONT_AND_BACK, GL_SPECULAR, specColor);
	glMaterialf(GL_FRONT_AND_BACK, GL_SHININESS, specExponent);
}


- (void)setSpecularColor3f:(GLclampf)r : (GLclampf)g : (GLclampf)b
{
	specColor[0] = Clamp_0_1(r);
	specColor[0] = Clamp_0_1(g);
	specColor[0] = Clamp_0_1(b);
}


- (void)setSpecularExponent:(GLfloat)inExp
{
	specExponent = Clamp_0_max(inExp, 128.0f);
}

@end
