//
//  OOMaterial.h
//  Oolite
//
//  Created by Jens Ayton on 2005-12-31.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "OOCocoa.h"
#import "OOOpenGL.h"

@class OOTexture;

// Material options dictionary keys
extern NSString *kOOMaterialSpecularColor;		// Array of floats, 0..1. Default: 0, 0, 0
extern NSString *kOOMaterialSpecularExponent;	// Float, 0..128. Default: 0
extern NSString *kOOMaterialAllowMipMap;		// Default: YES


@interface OOMaterial: NSObject
{
	OOTexture				*mainTexture;
	GLuint					mainTexName;
	GLclampf				specColor[4];
	GLfloat					specExponent;
}

- (id)initWithMainTextureName:(NSString *)inTextureName options:(NSDictionary *)inOptions;

- (void)activate;

- (void)setSpecularColor3f:(GLclampf)r : (GLclampf)g : (GLclampf)b;
- (void)setSpecularExponent:(GLfloat)inExp;

@end
