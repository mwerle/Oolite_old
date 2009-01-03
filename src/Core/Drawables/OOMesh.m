/*

OOMesh.m

A note on memory management:
The dynamically-sized buffers used by OOMesh (_vertex etc) are the byte arrays
of NSDatas, which are tracked using the _retainedObjects dictionary. This
simplifies the implementation of -dealloc, but more importantly, it means
bytes are refcounted. This means bytes read from the cache don't need to be
copied, we just need to retain the relevant NSData object (by sticking it in
_retainedObjects). As this mechanism is in place, it's convenient to also use
it for other objects, such as _meshData.materialKeys and the entries in
_meshData.materials.


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

#import "OOMesh.h"
#import "Universe.h"
#import "Geometry.h"
#import "ResourceManager.h"
#import "Entity.h"		// for NO_DRAW_DISTANCE_FACTOR.
#import "Octree.h"
#import "OOMaterial.h"
#import "OOBasicMaterial.h"
#import "OOCollectionExtractors.h"
#import "OOOpenGLExtensionManager.h"
#import "OOGraphicsResetManager.h"
#import "OODebugGLDrawing.h"
#import "OOShaderMaterial.h"
#import "OOMacroOpenGL.h"

#import "OOConcreteMeshBuilder.h"
#import "OODATMeshLoader.h"


NSString * const kOOPlaceholderMaterialName = @"_oo_placeholder_material\n";


// If set, collision octree depth varies depending on the size of the mesh. This seems to cause collision handling glitches at present.
#define ADAPTIVE_OCTREE_DEPTH		0


enum
{
	kBaseOctreeDepth				= 5,	// 32x32x32
	kMaxOctreeDepth					= 7,	// 128x128x128
	kSmallOctreeDepth				= 4,	// 16x16x16
	kVerySmallOctreeDepth			= 3,	// 8x8x8
	kOctreeSizeThreshold			= 900,	// Size at which we start increasing octree depth
	kOctreeSmallSizeThreshold		= 60,
	kOctreeVerySmallSizeThreshold	= 15
};


static NSString * const kOOLogMeshDataNotFound				= @"mesh.load.failed.fileNotFound";
static NSString * const kOOLogMeshTooManyVertices			= @"mesh.load.failed.tooManyVertices";
static NSString * const kOOLogMeshTooManyFaces				= @"mesh.load.failed.tooManyFaces";
static NSString * const kOOLogMeshTooManyMaterials			= @"mesh.load.failed.tooManyMaterials";


// Cache entry keys
#define kModelDataKeyElementCount		@"element count"
#define kModelDataKeyIndexCount			@"index count"
#define kModelDataKeyMaterialCount		@"material count"
#define kModelDataKeyIndexType			@"index type"
#define kModelDataKeyIndices			@"indices"
#define kModelDataKeyVertices			@"vertices"
#define kModelDataKeyNormals			@"normals"
#define kModelDataKeyTangents			@"tangents"
#define kModelDataKeyTextureCoordinates	@"texture coordinates"
#define kModelDataKeyMaterialOffsets	@"material offsets"
#define kModelDataKeyMaterialCounts		@"material counts"
#define kModelDataKeyMaterialKeys		@"material keys"


@interface OOMesh (Private) <NSMutableCopying, OOGraphicsResetClient>

// Designated initializer
- (id) initWithLoadingController:(id<OOModelLoadingController>)controller
			cachedRepresentation:(NSDictionary *)cachedRepresentation
						  loader:(OOMeshLoader *)loader;

- (NSDictionary*) modelData;
- (BOOL) setModelFromModelData:(NSDictionary *)dict
			 loadingController:(id<OOModelLoadingController>)controller;

- (void) calculateBoundingVolumes;

- (void)rescaleByX:(GLfloat)scaleX y:(GLfloat)scaleY z:(GLfloat)scaleZ;

#ifndef NDEBUG
- (void)debugDrawNormals;
#endif

// Manage set of objects we need to hang on to, particularly NSDatas owning buffers.
- (void) addRetainedObject:(id)object;
- (void *) allocateBytesWithSize:(size_t)size count:(OOUInteger)count;

- (void) clearGLCaches;

@end


@interface OOCacheManager (OOMesh)

+ (NSDictionary *) meshDataForName:(NSString *)inShipName;
+ (void) setMeshData:(NSDictionary *)inData forName:(NSString *)inShipName;

@end


@implementation OOMesh

- (id) initWithLoadingController:(id<OOModelLoadingController>)controller
						fileName:(NSString *)fileName
{
	Class				loaderClass = Nil;
	NSString			*extension = nil;
	OOMeshLoader		*loader = nil;
	NSString			*path = nil;
	NSDictionary		*cachedRepresentation = nil;
	
	if ([controller permitCacheRead])
	{
		cachedRepresentation = [OOCacheManager meshDataForName:fileName];
	}
	
	// Select loader class
	extension = [[fileName pathExtension] lowercaseString];
	if ([extension isEqualToString:@"dat"])  loaderClass = [OODATMeshLoader class];
	
	if (loaderClass == Nil)
	{
		[controller reportProblemWithKey:@"mesh.unknownType"
								   fatal:YES
								  format:@"The mesh file \"%@\" is of an unknown type."];
		[self release];
		return nil;
	}
	
	// Instantiate loader
	path = [controller pathForMeshNamed:fileName];
	loader = [[loaderClass alloc] initWithController:controller path:path];
	//[loader autorelease];
	if (loader == nil)
	{
		[self release];
		return nil;
	}
	
	id result = [self initWithLoadingController:controller
					  cachedRepresentation:cachedRepresentation
									loader:loader];
	[loader release];
	return result;
}


- (id) initWithLoadingController:(id<OOModelLoadingController>)controller
						  loader:(OOMeshLoader *)loader
{
	return [self initWithLoadingController:controller cachedRepresentation:nil loader:loader];
}


+ (OOMaterial *)placeholderMaterial
{
	static OOBasicMaterial	*placeholderMaterial = nil;
	
	if (placeholderMaterial == nil)
	{
		NSDictionary			*materialDefaults = nil;
		
		materialDefaults = [ResourceManager dictionaryFromFilesNamed:@"material-defaults.plist" inFolder:@"Config" andMerge:YES];
		placeholderMaterial = [[OOBasicMaterial alloc] initWithName:@"/placeholder/" configuration:[materialDefaults dictionaryForKey:@"no-textures-material"]];
	}
	
	return placeholderMaterial;
}


- (id)init
{
	self = [super init];
	if (self == nil)  return nil;
	
	_baseFile = @"No Model";
	
	return self;
}


- (void) dealloc
{
	[_baseFile release];
	[_octree autorelease];
	
	[self resetGraphicsState];
	
	[[OOGraphicsResetManager sharedManager] unregisterClient:self];
	
	[_retainedObjects release];
	
	[super dealloc];
}


- (NSString *) descriptionComponents
{
	return [NSString stringWithFormat:@"\"%@\", %u vertices, %u faces, radius: %g m", [self class], self, [self modelName], [self vertexCount], [self faceCount], [self collisionRadius]];
}


- (id)copyWithZone:(NSZone *)zone
{
	if (zone == [self zone])  return [self retain];	// OK because we're immutable seen from the outside
	else  return [self mutableCopyWithZone:zone];
}


- (NSString *) modelName
{
	return _baseFile;
}


- (OOUInteger) vertexCount
{
	return _meshData.indexCount;
}


- (OOUInteger) faceCount
{
	return _meshData.elementCount;
}


- (void)renderOpaqueParts
{
	if (EXPECT_NOT(_baseFile == nil))
	{
		OOLog(kOOLogFileNotLoaded, @"***** ERROR no _baseFile for entity %@", self);
		return;
	}
	
	OO_ENTER_OPENGL();
	
	glPushAttrib(GL_ENABLE_BIT);
	
	glShadeModel(GL_SMOOTH);
	
	glEnableClientState(GL_VERTEX_ARRAY);
	glEnableClientState(GL_NORMAL_ARRAY);
	glEnableClientState(GL_TEXTURE_COORD_ARRAY);
	
	glVertexPointer(3, GL_FLOAT, 0, _meshData.vertexArray);
	glNormalPointer(GL_FLOAT, 0, _meshData.normalArray);
	glTexCoordPointer(2, GL_FLOAT, 0, _meshData.textureUVArray);
	if ([[OOOpenGLExtensionManager sharedManager] shadersSupported])
	{
		glEnableVertexAttribArrayARB(kTangentAttributeIndex);
		glVertexAttribPointerARB(kTangentAttributeIndex, 3, GL_FLOAT, GL_FALSE, 0, _meshData.tangentArray);
	}
	
	glDisable(GL_BLEND);
	glEnable(GL_TEXTURE_2D);
	
	NS_DURING
	{
		OOUInteger i;
		
		if (!_listsReady)
		{
			_displayList0 = glGenLists(_meshData.materialCount);
			
			// Ensure all textures are loaded
			for (i = 0; i < _meshData.materialCount; i++)
			{
				[_meshData.materials[i] ensureFinishedLoading];
			}
		}
		
		size_t size = 0;
		switch (_meshData.indexType)
		{
			case GL_UNSIGNED_BYTE:
				size = sizeof (GLubyte);
				break;
			case GL_UNSIGNED_SHORT:
				size = sizeof (GLushort);
				break;
			case GL_UNSIGNED_INT:
				size = sizeof (GLuint);
				break;
				
			default:
				if (!_brokenInRender)
				{
					OOLog(@"mesh.meshData.badFormat", @"Data for %@ has invalid indexType (%u).", self, _meshData.indexType);
					_brokenInRender = YES;
				}
		}
		if (!_brokenInRender)
		{
			for (i = 0; i < _meshData.materialCount; i++)
			{
				char *start = _meshData.indexArray;
				start += size * _meshData.materialIndexOffsets[i];
				OOUInteger count = _meshData.materialIndexCounts[i];
				[_meshData.materials[i] apply];
				
				glDrawElements(GL_TRIANGLES, count, _meshData.indexType, start);
			}
		}
		
		_listsReady = YES;
		_brokenInRender = NO;
	}
	NS_HANDLER
		if (!_brokenInRender)
		{
			OOLog(kOOLogException, @"***** %s for %@ encountered exception: %@ : %@ *****", __FUNCTION__, self, [localException name], [localException reason]);
			_brokenInRender = YES;
		}
		if ([[localException name] hasPrefix:@"Oolite"])  [UNIVERSE handleOoliteException:localException];	// handle these ourself
		else  [localException raise];	// pass these on
	NS_ENDHANDLER
	
#ifndef NDEBUG
	if (gDebugFlags & DEBUG_DRAW_NORMALS)  [self debugDrawNormals];
#endif
	
	[OOMaterial applyNone];
	
#ifndef NDEBUG
	if (gDebugFlags & DEBUG_OCTREE_DRAW)  [[self octree] drawOctree];
#endif
	
	glPopAttrib();
}


- (BOOL) hasOpaqueParts
{
	return YES;
}

- (GLfloat) collisionRadius
{
	return _collisionRadius;
}


- (GLfloat) maxDrawDistance
{
	return _maxDrawDistance;
}


- (Geometry *) geometry
{
	OOUInteger		i, j, faceCount = _meshData.indexCount / 3;
	
	Geometry *result = [[Geometry alloc] initWithCapacity:faceCount];
	
	for (i = 0; i < faceCount; i++)
	{
		Triangle tri;
		for (j = 0; j < 3; ++j)
		{
			OOMeshDataGetVertex(&_meshData, i * 3 + j, &tri.v[j]);
		}
		[result addTriangle:tri];
	}
	return [result autorelease];
}


#if ADAPTIVE_OCTREE_DEPTH
- (unsigned) octreeDepth
{
	float				threshold = kOctreeSizeThreshold;
	unsigned			result = kBaseOctreeDepth;
	GLfloat				xs, ys, zs, t, size;
	
	bounding_box_get_dimensions(_boundingBox, &xs, &ys, &zs);
	// Shuffle dimensions around so zs is smallest
	if (xs < zs)  { t = zs; zs = xs; xs = t; }
	if (ys < zs)  { t = zs; zs = ys; ys = t; }
	size = (xs + ys) / 2.0f;	// Use average of two largest
	
	if (size < kOctreeVerySmallSizeThreshold)  result = kVerySmallOctreeDepth;
	else if (size < kOctreeSmallSizeThreshold)  result = kSmallOctreeDepth;
	else while (result < kMaxOctreeDepth)
	{
		if (size < threshold) break;
		threshold *= 2.0f;
		result++;
	}
	
	OOLog(@"mesh.load.octree.size", @"Selected octree depth %u for size %g for %@", result, size, _baseFile);
	return result;
}
#else
- (unsigned) octreeDepth
{
	return kBaseOctreeDepth;
}
#endif


- (Octree *) octree
{
	if (_octree == nil)
	{
		_octree = [OOCacheManager octreeForModel:_baseFile];
		if (_octree == nil)
		{
			_octree = [[self geometry] findOctreeToDepth:[self octreeDepth]];
			[OOCacheManager setOctree:_octree forModel:_baseFile];
		}
		[_octree retain];
	}
	
	return _octree;
}



static void TransformOneVector(OOMeshData *data, GLuint index, Vector rpos, Vector si, Vector sj, Vector sk, Vector ri, Vector rj, Vector rk, Vector *outRV)
{
	assert(data != NULL && outRV != NULL && index < data->indexCount);
	
	Vector pos = kZeroVector, pv;
	OOMeshDataGetVertex(data, index, &pos);
	
	// FIXME: rewrite with matrices.
	pv.x = rpos.x + si.x * pos.x + sj.x * pos.y + sk.x * pos.z;
	pv.y = rpos.y + si.y * pos.x + sj.y * pos.y + sk.y * pos.z;
	pv.z = rpos.z + si.x * pos.x + sj.z * pos.y + sk.z * pos.z;
	
	outRV->x = dot_product(ri, pv);
	outRV->y = dot_product(rj, pv);
	outRV->z = dot_product(rk, pv);
}


- (BoundingBox) findBoundingBoxRelativeToPosition:(Vector)opv
											basis:(Vector)ri :(Vector)rj :(Vector)rk
									 selfPosition:(Vector)position
										selfBasis:(Vector)si :(Vector)sj :(Vector)sk
{
	BoundingBox				result;
	Vector					rpos, rv;
	GLuint					i;
	
	rpos = vector_subtract(position, opv);	// Model origin relative to opv
	
	rv.x = dot_product(ri, rpos);
	rv.y = dot_product(ri, rpos);
	rv.z = dot_product(ri, rpos);	// model origin relative to opv in ijk
	
	if (EXPECT_NOT(_meshData.indexCount == 0))
	{
		bounding_box_reset_to_vector(&result, rv);
	}
	else
	{
		TransformOneVector(&_meshData, 0, rpos, si, sj, sk, ri, rj, rk, &rv);
		bounding_box_reset_to_vector(&result, rv);
		for (i = 1; i < _meshData.indexCount; i++)
		{
			TransformOneVector(&_meshData, 0, rpos, si, sj, sk, ri, rj, rk, &rv);
			bounding_box_add_vector(&result, rv);
		}
	}
	
	return result;
}


- (BoundingBox)findSubentityBoundingBoxWithPosition:(Vector)position rotMatrix:(OOMatrix)rotMatrix
{
	// HACK! Should work out what the various bounding box things do and make it neat and consistent.
	BoundingBox				result;
	Vector					v;
	GLuint					i;
	
	OOMeshDataGetVertex(&_meshData, 0, &v);
	v = vector_add(position, OOVectorMultiplyMatrix(v, rotMatrix));
	bounding_box_reset_to_vector(&result,v);
	
	for (i = 1; i < _meshData.indexCount; i++)
	{
		OOMeshDataGetVertex(&_meshData, i, &v);
		v = vector_add(position, OOVectorMultiplyMatrix(v, rotMatrix));
		bounding_box_add_vector(&result,v);
	}
	
	return result;
}


#if 0
- (BoundingBox) findBoundingBoxRelativeToPosition:(Vector)opv
											basis:(Vector)ri :(Vector)rj :(Vector)rk
									 selfPosition:(Vector)position
										selfBasis:(Vector)si :(Vector)sj :(Vector)sk
{
	BoundingBox	result;
	Vector		pv, rv;
	Vector		rpos = position;
	int			i;
	
	// FIXME: rewrite with matrices
	rpos = vector_subtract(position, opv);	// model origin relative to opv
	
	rv.x = dot_product(ri,rpos);
	rv.y = dot_product(rj,rpos);
	rv.z = dot_product(rk,rpos);	// model origin rel to opv in ijk
	
	if (EXPECT_NOT(_vertexCount < 1))
	{
		bounding_box_reset_to_vector(&result, rv);
	}
	else
	{
		pv.x = rpos.x + si.x * _vertices[0].x + sj.x * _vertices[0].y + sk.x * _vertices[0].z;
		pv.y = rpos.y + si.y * _vertices[0].x + sj.y * _vertices[0].y + sk.y * _vertices[0].z;
		pv.z = rpos.z + si.z * _vertices[0].x + sj.z * _vertices[0].y + sk.z * _vertices[0].z;	// _vertices[0] position rel to opv
		rv.x = dot_product(ri, pv);
		rv.y = dot_product(rj, pv);
		rv.z = dot_product(rk, pv);	// _vertices[0] position rel to opv in ijk
		bounding_box_reset_to_vector(&result, rv);
	}
	for (i = 1; i < vertexCount; i++)
	{
		pv.x = rpos.x + si.x * _vertices[i].x + sj.x * _vertices[i].y + sk.x * _vertices[i].z;
		pv.y = rpos.y + si.y * _vertices[i].x + sj.y * _vertices[i].y + sk.y * _vertices[i].z;
		pv.z = rpos.z + si.z * _vertices[i].x + sj.z * _vertices[i].y + sk.z * _vertices[i].z;
		rv.x = dot_product(ri, pv);
		rv.y = dot_product(rj, pv);
		rv.z = dot_product(rk, pv);
		bounding_box_add_vector(&result, rv);
	}

	return result;
}


- (BoundingBox)findSubentityBoundingBoxWithPosition:(Vector)position rotMatrix:(OOMatrix)rotMatrix
{
	// HACK! Should work out what the various bounding box things do and make it neat and consistent.
	BoundingBox		result;
	Vector			v;
	int				i;
	
	v = vector_add(position, OOVectorMultiplyMatrix(_vertices[0], rotMatrix));
	bounding_box_reset_to_vector(&result,v);
	
	for (i = 1; i < vertexCount; i++)
	{
		v = vector_add(position, OOVectorMultiplyMatrix(_vertices[i], rotMatrix));
		bounding_box_add_vector(&result,v);
	}
	
	return result;
}
#endif


- (OOMesh *)meshRescaledBy:(GLfloat)scaleFactor
{
	return [self meshRescaledByX:scaleFactor y:scaleFactor z:scaleFactor];
}


- (OOMesh *)meshRescaledByX:(GLfloat)scaleX y:(GLfloat)scaleY z:(GLfloat)scaleZ
{
	id					result = nil;
		
	result = [self mutableCopy];
	[result rescaleByX:scaleX y:scaleY z:scaleZ];
	return [result autorelease];
}


- (void)setBindingTarget:(id<OOWeakReferenceSupport>)target
{
	unsigned				i;
	
	for (i = 0; i != _meshData.materialCount; ++i)
	{
		[_meshData.materials[i] setBindingTarget:target];
	}
}


#ifndef NDEBUG
- (void)dumpSelfState
{
	NSMutableArray		*flags = nil;
	NSString			*flagsString = nil;
	
	[super dumpSelfState];
	
	if (_baseFile != nil)  OOLog(@"dumpState.mesh", @"Model file: %@", _baseFile);
	OOLog(@"dumpState.mesh", @"Vertex count: %u, face count: %u", [self vertexCount], [self faceCount]);
	
	flags = [NSMutableArray array];
	#define ADD_FLAG_IF_SET(x)		if (x) { [flags addObject:@#x]; }
	flagsString = [flags count] ? [flags componentsJoinedByString:@", "] : (NSString *)@"none";
	OOLog(@"dumpState.mesh", @"Flags: %@", flagsString);
}
#endif

#if STATIC_ANALYSIS
- (BoundingBox) boundingBox
{
	// Placate clang static analyzer. (_boundingBox is otherwise only used in categories.)
	return _boundingBox;
}
#endif

@end


@implementation OOMesh (Private)

- (id) initWithLoadingController:(id<OOModelLoadingController>)controller
			cachedRepresentation:(NSDictionary *)cachedRepresentation
						  loader:(OOMeshLoader *)loader
{
	OOConcreteMeshBuilder	*builder = nil;
	BOOL					OK = YES;
	
	if (controller == nil || loader == nil)  OK = NO;
	
	if (OK)
	{
		self = [super init];
		if (self == nil)  OK = NO;
	}
	
	if (OK)
	{
		_baseFile = [[loader fileName] copy];
		
		if (!cachedRepresentation || ![self setModelFromModelData:cachedRepresentation loadingController:controller])
		{
			builder = [[OOConcreteMeshBuilder alloc] initWithMeshLoader:loader];
			OK = [builder loadDataGettingMeshData:&_meshData retainedObjects:&_retainedObjects];
			[builder release];
			[_retainedObjects retain];
			
			if (OK && [controller permitCacheWrite])
			{
				// Cache for future reuse
				[OOCacheManager setMeshData:[self modelData] forName:_baseFile];
			}
		}
	}
	
	if (OK)
	{
		[self calculateBoundingVolumes];
	}
	else
	{
		[self release];
		self = nil;
	}
	
	return self;
}


- (id)mutableCopyWithZone:(NSZone *)zone
{
	OOMesh				*result = nil;
	
	result = [[OOMesh allocWithZone:zone] init];
	
	if (result != nil)
	{
		result->_baseFile = [_baseFile copyWithZone:zone];
		result->_octree = [_octree retain];
		
		if (!OOMeshDataDeepCopy(&_meshData, &result->_meshData, &result->_retainedObjects))
		{
			[result release];
			return nil;
		}
		
		result->_collisionRadius = _collisionRadius;
		result->_collisionRadius = _collisionRadius;
		result->_boundingBox = _boundingBox;
		[result->_retainedObjects retain];
		
		[[OOGraphicsResetManager sharedManager] registerClient:result];
	}
	
	return result;
}


- (void) resetGraphicsState
{
	if (_listsReady)
	{
		OO_ENTER_OPENGL();
		
		glDeleteLists(_displayList0, _meshData.materialCount);
		_listsReady = NO;
	}
}


- (NSDictionary *) modelData
{
	NSNumber *elementCount	= [NSNumber numberWithUnsignedLong:_meshData.elementCount];
	NSNumber *indexCount	= [NSNumber numberWithUnsignedLong:_meshData.indexCount];
	NSNumber *materialCount	= [NSNumber numberWithUnsignedLong:_meshData.materialCount];
	NSNumber *indexType		= [NSNumber numberWithUnsignedInt:_meshData.indexType];
	
	NSData *indexData		= [NSData dataWithBytes:_meshData.indexArray
										length:OOMeshDataIndexSize(_meshData.indexType) * _meshData.indexCount];
	NSData *vertexData		= [NSData dataWithBytes:_meshData.vertexArray
										 length:sizeof (Vector) * _meshData.elementCount];
	NSData *normalData		= [NSData dataWithBytes:_meshData.normalArray
										 length:sizeof (Vector) * _meshData.elementCount];
	NSData *tangentData		= [NSData dataWithBytes:_meshData.tangentArray
										  length:sizeof (Vector) * _meshData.elementCount];
	NSData *textureUVData	= [NSData dataWithBytes:_meshData.textureUVArray
										   length:sizeof (GLfloat) * 2 * _meshData.elementCount];
	NSData *matlOffsetData	= [NSData dataWithBytes:_meshData.materialIndexOffsets
										   length:sizeof (GLuint) * _meshData.materialCount];
	NSData *matlCountData	= [NSData dataWithBytes:_meshData.materialIndexCounts
										   length:sizeof (GLuint) * _meshData.materialCount];
	
	// Ensure nothing went wrong
	if (elementCount == nil ||
		indexCount == nil ||
		materialCount == nil ||
		indexType == nil ||
		indexData == nil ||
		vertexData == nil ||
		normalData == nil ||
		tangentData == nil ||
		textureUVData == nil ||
		matlOffsetData == nil ||
		matlCountData == nil ||
		_meshData.materialKeys == nil ||
		OOMeshDataIndexSize(_meshData.indexType) == 0)
	{
		return nil;
	}
	
	return [NSDictionary dictionaryWithObjectsAndKeys:
			elementCount, kModelDataKeyElementCount,
			indexCount, kModelDataKeyIndexCount,
			materialCount, kModelDataKeyMaterialCount,
			indexType, kModelDataKeyIndexType,
			indexData, kModelDataKeyIndices,
			vertexData, kModelDataKeyVertices,
			normalData, kModelDataKeyNormals,
			tangentData, kModelDataKeyTangents,
			textureUVData, kModelDataKeyTextureCoordinates,
			matlOffsetData, kModelDataKeyMaterialOffsets,
			matlCountData, kModelDataKeyMaterialCounts,
			_meshData.materialKeys, kModelDataKeyMaterialKeys,
			nil];
}


- (BOOL) setModelFromModelData:(NSDictionary *)dict
			 loadingController:(id<OOModelLoadingController>)controller
{
	OOUInteger elementCount	= [dict unsignedLongForKey:kModelDataKeyElementCount];
	OOUInteger indexCount	= [dict unsignedLongForKey:kModelDataKeyIndexCount];
	OOUInteger materialCount= [dict unsignedLongForKey:kModelDataKeyMaterialCount];
	GLenum indexType		= [dict unsignedIntForKey:kModelDataKeyIndexType];
	
	// Sanity check.
	if (elementCount == 0 ||
		indexCount == 0 ||
		materialCount == 0 ||
		OOMeshDataIndexSize(indexType) == 0)
	{
		return NO;
	}
	
	NSData *indexData		= [dict dataForKey:kModelDataKeyIndices];
	NSData *vertexData		= [dict dataForKey:kModelDataKeyVertices];
	NSData *normalData		= [dict dataForKey:kModelDataKeyNormals];
	NSData *tangentData		= [dict dataForKey:kModelDataKeyTangents];
	NSData *textureUVData	= [dict dataForKey:kModelDataKeyTextureCoordinates];
	NSData *matlOffsetData	= [dict dataForKey:kModelDataKeyMaterialOffsets];
	NSData *matlCountData	= [dict dataForKey:kModelDataKeyMaterialCounts];
	NSArray *materialKeys	= [dict arrayForKey:kModelDataKeyMaterialKeys];
	
	// Sanity check some more.
	if ([indexData length] != OOMeshDataIndexSize(indexType) * indexCount ||
		[vertexData length] != sizeof (Vector) * elementCount ||
		[normalData length] != sizeof (Vector) * elementCount ||
		[tangentData length] != sizeof (Vector) * elementCount ||
		[textureUVData length] != sizeof (GLfloat) * 2 * elementCount ||
		[matlOffsetData length] != sizeof (GLuint) * materialCount ||
		[matlCountData length] != sizeof (GLuint) * materialCount ||
		[materialKeys count] != materialCount)
	{
		return NO;
	}
	
	// Retain data.
	[self addRetainedObject:indexData];
	[self addRetainedObject:vertexData];
	[self addRetainedObject:normalData];
	[self addRetainedObject:tangentData];
	[self addRetainedObject:textureUVData];
	[self addRetainedObject:matlOffsetData];
	[self addRetainedObject:matlCountData];
	[self addRetainedObject:materialKeys];
	
	/*	Pack into _meshData.
		Note that this casts away constness. Editing a mesh created this way
		will corrupt other meshes loaded from the same cache. Use -mutableCopy
		to get a deep copy of the data.
	*/
	_meshData.elementCount = elementCount;
	_meshData.indexCount = indexCount;
	_meshData.materialCount = materialCount;
	_meshData.indexType = indexType;
	_meshData.indexArray = (void *)[indexData bytes];
	_meshData.vertexArray = (void *)[vertexData bytes];
	_meshData.normalArray = (void *)[normalData bytes];
	_meshData.tangentArray = (void *)[tangentData bytes];
	_meshData.textureUVArray = (void *)[textureUVData bytes];
	_meshData.materialIndexOffsets = (void *)[matlOffsetData bytes];
	_meshData.materialIndexCounts = (void *)[matlCountData bytes];
	_meshData.materialKeys = materialKeys;
	
	// Reify materials.
	_meshData.materials = [self allocateBytesWithSize:sizeof (OOMaterial *) count:materialCount];
	OOUInteger i;
	for (i = 0; i != materialCount; ++i)
	{
		OOMaterial *material = [controller loadMaterialWithKey:[materialKeys objectAtIndex:i]];
		if (material == nil)  return NO;
		[self addRetainedObject:material];
		_meshData.materials[i] = material;
	}
	
	return YES;
}


- (void) calculateBoundingVolumes
{
	OOUInteger			i, count;
	GLfloat				d_squared, length_longest_axis, length_shortest_axis;
	GLfloat				result = 0.0f;
	
	count = _meshData.elementCount;
	if (count != 0)  bounding_box_reset_to_vector(&_boundingBox, _meshData.vertexArray[0]);
	else  bounding_box_reset(&_boundingBox);

	for (i = 0; i < count; i++)
	{
		d_squared = magnitude2(_meshData.vertexArray[i]);
		if (d_squared > result)  result = d_squared;
		bounding_box_add_vector(&_boundingBox, _meshData.vertexArray[i]);
	}
	
	length_longest_axis = OOMax_f(OOMax_f(_boundingBox.max.x - _boundingBox.min.x, _boundingBox.max.y - _boundingBox.min.y), _boundingBox.max.z - _boundingBox.min.z);
	length_shortest_axis = OOMin_f(OOMin_f(_boundingBox.max.x - _boundingBox.min.x, _boundingBox.max.y - _boundingBox.min.y), _boundingBox.max.z - _boundingBox.min.z);
	
	d_squared = (length_longest_axis + length_shortest_axis) * (length_longest_axis + length_shortest_axis) * 0.25; // square of average length
	_maxDrawDistance = d_squared * NO_DRAW_DISTANCE_FACTOR * NO_DRAW_DISTANCE_FACTOR;
	
	_collisionRadius = sqrtf(result);
}


- (void)rescaleByX:(GLfloat)scaleX y:(GLfloat)scaleY z:(GLfloat)scaleZ
{
	
	OOUInteger			i;
	BOOL				isotropic;
	Vector				*v = NULL;
	
	isotropic = (scaleX == scaleY && scaleY == scaleZ);
	
	for (i = 0; i != _meshData.elementCount; ++i)
	{
		v = &_meshData.vertexArray[i];
		
		v->x *= scaleX;
		v->y *= scaleY;
		v->z *= scaleZ;
		
		if (!isotropic)
		{
			v = &_meshData.normalArray[i];
			v->x *= scaleX;
			v->y *= scaleY;
			v->z *= scaleZ;
			*v = vector_normal(*v);
			
			v = &_meshData.tangentArray[i];
			v->x *= scaleX;
			v->y *= scaleY;
			v->z *= scaleZ;
			*v = vector_normal(*v);
		}
	}
	
	[self calculateBoundingVolumes];
	[_octree release];
	_octree = nil;
}


- (BoundingBox)_boundingBox
{
	return _boundingBox;
}


#ifndef NDEBUG
- (void)debugDrawNormals
{
	GLuint				i, count, elem;
	Vector				v, n, t, b;
	float				length, blend;
	GLfloat				color[3];
	OODebugWFState		state;
	
	OO_ENTER_OPENGL();
	
	state = OODebugBeginWireframe(NO);
	
	// Draw
	glBegin(GL_LINES);
	count = _meshData.elementCount / 3;
	for (i = 0; i < count; ++i)
	{
		if (!OOMeshDataGetElementIndex(&_meshData, i, &elem))  break;
		
		v = _meshData.vertexArray[elem];
		n = _meshData.normalArray[elem];
		t = _meshData.tangentArray[elem];
		b = true_cross_product(n, t);
		
		// Draw normal
		length = magnitude2(n);
		blend = fabsf(length - 1) * 5.0;
		color[0] = MIN(blend, 1.0f);
		color[1] = 1.0f - color[0];
		color[2] = color[1];
		glColor3fv(color);
		
		glVertex3f(v.x, v.y, v.z);
		scale_vector(&n, 5.0f);
		n = vector_add(n, v);
		glVertex3f(n.x, n.y, n.z);
		
		// Draw tangent
		glColor3f(1.0f, 1.0f, 0.0f);
		t = vector_add(v, vector_multiply_scalar(t, 3.0f));
		glVertex3f(v.x, v.y, v.z);
		glVertex3f(t.x, t.y, t.z);
		
		// Draw binormal
		glColor3f(0.0f, 1.0f, 0.0f);
		b = vector_add(v, vector_multiply_scalar(b, 3.0f));
		glVertex3f(v.x, v.y, v.z);
		glVertex3f(b.x, b.y, b.z);
	}
	glEnd();
	
	OODebugEndWireframe(state);
}
#endif


- (void) clearGLCaches
{
	OO_ENTER_OPENGL();
	
	if (_listsReady)
	{
		glDeleteLists(_displayList0, _meshData.materialCount);
		_listsReady = NO;
		_displayList0 = 0;
	}
}


- (void) addRetainedObject:(id)object
{
	if (object != nil)
	{
		if (_retainedObjects == nil)  _retainedObjects = [[NSMutableArray alloc] init];
		[_retainedObjects addObject:object];
	}
}


- (void *) allocateBytesWithSize:(size_t)size count:(OOUInteger)count
{
	size *= count;
	void *bytes = malloc(size);
	if (bytes != NULL)
	{
		NSData *holder = [NSData dataWithBytesNoCopy:bytes length:size freeWhenDone:YES];
		[self addRetainedObject:holder];
	}
	return bytes;
}

@end


static NSString * const kOOCacheMeshes = @"OOMesh";

@implementation OOCacheManager (OOMesh)

+ (NSDictionary *) meshDataForName:(NSString *)inShipName
{
	return [[self sharedCache] objectForKey:inShipName inCache:kOOCacheMeshes];
}


+ (void) setMeshData:(NSDictionary *)inData forName:(NSString *)inShipName
{
	if (inData != nil && inShipName != nil)
	{
		[[self sharedCache] setObject:inData forKey:inShipName inCache:kOOCacheMeshes];
	}
}

@end


static NSString * const kOOCacheOctrees = @"octrees";

@implementation OOCacheManager (Octree)

+ (Octree *) octreeForModel:(NSString *)inKey
{
	NSDictionary		*dict = nil;
	Octree				*result = nil;
	
	dict = [[self sharedCache] objectForKey:inKey inCache:kOOCacheOctrees];
	if (dict != nil)
	{
		result = [[Octree alloc] initWithDictionary:dict];
		[result autorelease];
	}
	
	return result;
}


+ (void)setOctree:(Octree *)inOctree forModel:(NSString *)inKey
{
	if (inOctree != nil && inKey != nil)
	{
		[[self sharedCache] setObject:[inOctree dict] forKey:inKey inCache:kOOCacheOctrees];
	}
}

@end


size_t OOMeshDataIndexSize(GLenum indexType)
{
	switch (indexType)
	{
		case GL_UNSIGNED_BYTE:
			return sizeof (GLubyte);
			
		case GL_UNSIGNED_SHORT:
			return sizeof (GLushort);
			
		case GL_UNSIGNED_INT:
			return sizeof (GLuint);
	}
	
	return 0;
}


BOOL OOMeshDataGetElementIndex(OOMeshData *meshData, GLuint index, GLuint *outElement)
{
	assert (meshData != NULL && outElement != NULL);
	if (index >= meshData->indexCount)  return NO;
	
	switch (meshData->indexType)
	{
		case GL_UNSIGNED_BYTE:
			*outElement = ((GLubyte *)meshData->indexArray)[index];
			return YES;
			
		case GL_UNSIGNED_SHORT:
			*outElement = ((GLushort *)meshData->indexArray)[index];
			return YES;
			
		case GL_UNSIGNED_INT:
			*outElement = ((GLuint *)meshData->indexArray)[index];
			return YES;
		
		default:
			OOLog(@"mesh.meshData.badFormat", @"OOMeshData has invalid indexType (%u).", meshData->indexType);
			return NO;
	}
}


BOOL OOMeshDataDeepCopy(OOMeshData *inData, OOMeshData *outData, NSMutableArray **outRetainedObjects)
{
	if (outData == NULL)  return NO;
	memset(outData, 0, sizeof *outData);
	if (inData == NULL || outRetainedObjects == NULL)  return NO;
	
	NSData *indexData		= [NSData dataWithBytes:inData->indexArray length:OOMeshDataIndexSize(inData->indexType) * inData->indexCount];
	NSData *vertexData		= [NSData dataWithBytes:inData->vertexArray length:sizeof (Vector) * inData->elementCount];
	NSData *normalData		= [NSData dataWithBytes:inData->normalArray length:sizeof (Vector) * inData->elementCount];
	NSData *tangentData		= [NSData dataWithBytes:inData->tangentArray length:sizeof (Vector) * inData->elementCount];
	NSData *textureUVData	= [NSData dataWithBytes:inData->textureUVArray length:sizeof (GLfloat) * inData->elementCount * 2];
	NSData *matlOffsetData	= [NSData dataWithBytes:inData->materialIndexOffsets length:sizeof (GLuint) * inData->materialCount];
	NSData *matlCountData	= [NSData dataWithBytes:inData->materialIndexCounts length:sizeof (GLuint) * inData->materialCount];
	NSData *materials		= [NSData dataWithBytes:inData->materials length:sizeof (OOMaterial *) * inData->materialCount];
	
	if (indexData == nil ||
		vertexData == nil ||
		normalData == nil ||
		tangentData == nil ||
		textureUVData == nil ||
		matlOffsetData == nil ||
		matlCountData == nil ||
		materials == nil)
	{
		return NO;
	}
	
	NSMutableArray *holder = [NSMutableArray arrayWithObjects:
							  indexData, vertexData, normalData, tangentData,
							  textureUVData, matlOffsetData, matlCountData, nil];
	OOLogAlloc(holder);
	if (holder == nil)  return NO;
	
	/*	All bytes copied, set up structure.
		Note that we're casting away constness here; see note in -modelData.
	*/
	outData->elementCount	= inData->elementCount;
	outData->indexCount		= inData->indexCount;
	outData->materialCount	= inData->materialCount;
	outData->indexType		= inData->indexType;
	outData->indexArray		= (void *)[indexData bytes];
	outData->vertexArray	= (void *)[vertexData bytes];
	outData->normalArray	= (void *)[normalData bytes];
	outData->tangentArray	= (void *)[tangentData bytes];
	outData->textureUVArray	= (void *)[textureUVData bytes];
	outData->materialIndexOffsets	= (void *)[matlOffsetData bytes];
	outData->materialIndexCounts	= (void *)[matlCountData bytes];
	outData->materials				= (void *)[materials bytes];
	outData->materialKeys	= [inData->materialKeys retain];
	
	GLuint i;
	for (i = 0; i < outData->materialCount; i++)
	{
		[holder addObject:outData->materials[i]];
		OOLog(@"temp.trackMaterial", @"Copied material %p", outData->materials[i]);
	}
	
	*outRetainedObjects = holder;
	
	return YES;
}
