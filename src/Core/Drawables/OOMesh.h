/*

OOMesh.h

Standard OODrawable for static meshes from DAT files. OOMeshes are immutable
(and can therefore be shared). Avoid the temptation to add externally-visible
mutator methods as it will break such sharing. (Sharing will be implemented
when ship types are turned into objects instead of dictionaries; this is
currently slated for post-1.70. -- Ahruman)

Hmm. On further consideration, sharing will be problematic because of material
bindings. Two possible solutions: separate mesh data into shared object with
each mesh instance having its own set of materials but shared data, or
retarget bindings each frame. -- Ahruman


Oolite
Copyright (C) 2004-2009 Giles C Williams and contributors

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
MA 02110-1301, USA.

*/

#import "OODrawable.h"
#import "OOOpenGL.h"
#import "OOWeakReference.h"
#import "OOModelLoadingController.h"
#import "OOMeshData.h"

@class OOMaterial, Octree, OOMeshLoader;


@interface OOMesh: OODrawable <NSCopying>
{
@private
	NSString				*_baseFile;
	
	OOMeshData				_meshData;
	
	GLuint					_displayList0;
	
	GLfloat					_collisionRadius;
	GLfloat					_maxDrawDistance;
	BoundingBox				_boundingBox;
	
	Octree					*_octree;
	
	NSMutableArray			*_retainedObjects;
	
	uint8_t					_brokenInRender: 1,
							_listsReady: 1;
}

- (id) initWithLoadingController:(id<OOModelLoadingController>)controller
						fileName:(NSString *)fileName;
- (id) initWithLoadingController:(id<OOModelLoadingController>)controller
						  loader:(OOMeshLoader *)loader;

+ (OOMaterial *) placeholderMaterial;

- (NSString *) modelName;

- (OOUInteger) vertexCount;
- (OOUInteger) faceCount;

- (Octree *) octree;

// This needs a better name.
- (BoundingBox) findBoundingBoxRelativeToPosition:(Vector)opv
											basis:(Vector)ri :(Vector)rj :(Vector)rk
									 selfPosition:(Vector)position
										selfBasis:(Vector)si :(Vector)sj :(Vector)sk;
- (BoundingBox) findSubentityBoundingBoxWithPosition:(Vector)position rotMatrix:(OOMatrix)rotMatrix;

- (OOMesh *) meshRescaledBy:(GLfloat)scaleFactor;
- (OOMesh *) meshRescaledByX:(GLfloat)scaleX y:(GLfloat)scaleY z:(GLfloat)scaleZ;

@end


#import "OOCacheManager.h"

@interface OOCacheManager (Octree)

+ (Octree *) octreeForModel:(NSString *)inKey;
+ (void) setOctree:(Octree *)inOctree forModel:(NSString *)inKey;

@end
