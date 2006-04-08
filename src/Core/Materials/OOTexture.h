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
	NSString				*name;
	GLuint					texName;
	GLuint					width, height;
	void					*data;
	uint8_t					mipmapped, loaded, setUp, invalidated;
}

+ (id)textureWithImageNamed:(NSString *)inName allowMipMap:(BOOL)inAllowMipMap;

- (void)bind;
- (void)destroy;

- (GLuint)textureName;
- (NSSize)size;

+ (void)update;

// This invalidates a texture’s connection to an OpenGL context. It will also need to be reloaded
// on systems not supporting GL_UNPACK_CLIENT_STORAGE_APPLE or equivalent. If asyncronous loading
// is DISABLED, this must be called with the new context active.
+ (void)invalidateAllTextureBindings;
- (void)invalidateBinding;

@end
