//
//  OOTexture.h
//  Oolite
//
//  Created by Jens Ayton on 2005-12-31.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "OOCocoa.h"
#import "OOOpenGL.h"


@interface OOTexture: NSObject
{
	OOTexture				*link;
	GLuint					texName;
	GLuint					width, height;
	void					*data;
	uint8_t					mipmapped, loaded, setUp;
}

+ (id)textureWithImageNamed:(NSString *)inName allowMipMap:(BOOL)inAllowMipMap;

- (void)bind;
- (void)destroy;

- (GLuint)textureName;
- (NSSize)size;

+ (void)update;

@end
