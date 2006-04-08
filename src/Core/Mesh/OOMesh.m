/*
	OOMesh.m
	Oolite
	
	Copyright © 2006 Jens Ayton
	
	This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike License.
	To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/2.0/
	or send a letter to Creative Commons, 559 Nathan Abbott Way, Stanford, California 94305, USA.
	
	You are free:
	
	•	to copy, distribute, display, and perform the work
	•	to make derivative works
	
	Under the following conditions:
	
	•	Attribution. You must give the original author credit.
	
	•	Share Alike. If you alter, transform, or build upon this work,
	you may distribute the resulting work only under a license identical to this one.
	
	For any reuse or distribution, you must make clear to others the license terms of this work.
	
	Any of these conditions can be waived if you get permission from the copyright holder.
	
	Your fair use and other rights are in no way affected by the above.
*/

#import "OOMesh.h"
#import "OODATLexer.h"

/*	Cache
	There are two caches used for meshes. First is the in-memory instance cache, which contains a
	reference to each mesh currently in use, allowing instance sharing. This is stored in a mutable
	dictionary keyed by file path. The second is the on-disk data cache of “flattened” meshes, which
	contains binary data allowing fast loading.
*/


static NSMutableDictionary		*sInstanceCache = nil;


/*	Data types for handling loading from DAT files. The format of DAT files is sufficiently divorced
	from our internal format that it’s best to load them in one representation, then convert. Trust
	me, I tried the other way.
*/

enum
{
	kDATMaxVerticesPerFace = 16
};


typedef struct DATFace
{
	Vector					normal;
	OOMeshIndex				vertices[kDATMaxVerticesPerFace];
	OOTextureCoordinates	texCoords[kDATMaxVerticesPerFace];
	OOMaterial				*material;
	OOMeshIndex				vertexCount;
	OOMeshIndex				_padding;
} DATFace;


typedef struct DATData
{
	unsigned				vertexCount;
	unsigned				faceCount;
	unsigned				triangleCount;	// Number of faces the object will have once triangulated.
	Vector					*vertices;
	DATFace					*faces;
} DATData;


static DATData *ReadDATFile(NSString *inPath, NSDictionary *inOptions);
static void DisposeDATData(DATData **ioDataPtr);
static void SetUpDefaultTexturesForDAT(DATData *ioData);


@interface OOMesh (Private)

+ (id)cachedInstanceForPath:(NSString *)inFilePath;
+ (id)flattenedInstanceForPath:(NSString *)inFilePath date:(NSDate *)inModificationDate;
- (id)initWithFile:(NSString *)inFilePath options:(NSDictionary *)inOptions;
- (void)writeDataCacheForPath:(NSString *)inFilePath date:(NSDate *)inModificationDate;

@end


@implementation OOMesh


+ (id)meshWithFile:(NSString *)inFilePath options:(NSDictionary *)inOptions
{
	id						result;
	NSDate					*date = nil;
	
	// Look for existing instance
	result = [self cachedInstanceForPath:inFilePath];
	if (nil != result) NSLog(@"Reusing mesh instance %@", result);
	
	// Look for “flattened” instance (cached data)
	if (nil == result)
	{
		date = [[[NSFileManager defaultManager]
					fileAttributesAtPath:inFilePath traverseLink:YES]
					objectForKey:NSFileModificationDate];
		result = [self flattenedInstanceForPath:inFilePath date:date];
		if (nil != result) NSLog(@"Using unflattened mesh %@", result);
	}
	
	// If no cached instance is available, load the file (and add it to the caches)
	if (nil == result)
	{
		result = [[self alloc] initWithFile:inFilePath options:inOptions];
		if (nil != result)
		{
			if (nil == sInstanceCache) sInstanceCache = [[NSMutableDictionary alloc] init];
			[sInstanceCache setObject:result forKey:inFilePath];
			[result writeDataCacheForPath:inFilePath date:date];
			[result autorelease];
			NSLog(@"Created new mesh instance %@", result);
		}
	}
	
	return result;
}


+ (id)cachedInstanceForPath:(NSString *)inFilePath
{
	return [sInstanceCache objectForKey:inFilePath];
}


+ (id)flattenedInstanceForPath:(NSString *)inFilePath date:(NSDate *)inModificationDate
{
	return nil;
}


- (id)initWithFile:(NSString *)inFilePath options:(NSDictionary *)inOptions
{
	DATData					*data;
	
	self = [super init];
	if (self)
	{
		data = ReadDATFile(inFilePath, inOptions);
		if (NULL != data)
		{
			// TODO: Convert to internal representation
			
			DisposeDATData(&data);
		}
	}
	
	[self release];
	return nil;
}


// The instance cache retains one reference to each active instance; therefore, an instance can be
// considered inactive when its retain count reaches one.
- (void)release
{
	if (2 == [self retainCount])
	{
		NSLog(@"Removing %@ from instance cache", self);
		[sInstanceCache removeObjectForKey:_key];
	}
	[super release];
}


- (void)dealloc
{
	OOMeshIndex				i;
	
	// Deallocate face sets - release materials, free face data arrays
	if (NULL != _faceSets)
	{
		for (i = 0; i != _faceSetCount; ++i)
		{
			[_faceSets[i].material release];
			if (NULL != _faceSets[i].faces) free(_faceSets[i].faces);
		}
		free(_faceSets);
	}
	
	if (NULL != _vertices) free(_vertices);
	if (NULL != _normals) free(_normals);
	if (NULL != _texCoords) free(_texCoords);
	
	[_key release];
	
	[super dealloc];
}


- (void)writeDataCacheForPath:(NSString *)inFilePath date:(NSDate *)inModificationDate
{
	NSLog(@"Flattening %@", self);
}


- (void)draw
{
	NSLog(@"Drawing %@", self);
}


- (NSString *)description
{
	return [NSString stringWithFormat:@"<%s %p>{%@}", object_getClassName(self), self, [_key lastPathComponent]];
}

@end


static DATData *ReadDATFile(NSString *inFilePath, NSDictionary *inOptions)
{
	BOOL					OK;
	OODATLexer				*lexer = nil;
	OOMeshIndex				vertexIndex, faceIndex;
	DATData					*result = NULL;
	unsigned				faceVertexCount;
	DATFace					*face;
	unsigned				longIndex;
	NSMutableDictionary		*materialLUT;
	NSString				*materialName;
	float					scaleS, scaleT, s, t;
	OOMeshIndex				triangles;
	
	assert(nil != inFilePath);
	
	result = calloc(1, sizeof result);
	if (NULL == result) return NULL;
	
	lexer = [[OODATLexer alloc] initWithPath:inFilePath];
	OK = (nil != lexer);
	
	[lexer skipLineBreaks];
	
	if (OK)
	{
		// Get number of vertices
		OK = [lexer passRequiredToken:kOoliteDatToken_NVERTS];
		if (OK) OK = [lexer readInteger:&result->vertexCount] && [lexer passAtLeastOneLineBreak];
		
		if (OK && kOOMeshIndexMax < result->vertexCount)
		{
			OK = NO;
			NSLog(@"%@ cannot be read by Oolite. It contains %u %s, but Oolite can handle at most %u.", [inFilePath lastPathComponent], result->vertexCount, "vertices", kOOMeshIndexMax);
		}
	}
	
	if (OK)
	{
		// Get number of faces
		OK = [lexer passRequiredToken:kOoliteDatToken_NFACES];
		if (OK) OK = [lexer readInteger:&result->faceCount] && [lexer passAtLeastOneLineBreak];
		
		if (OK && kOOMeshIndexMax < result->faceCount)
		{
			OK = NO;
			NSLog(@"%@ cannot be read by Oolite. It contains %u %s, but Oolite can handle at most %u.", [inFilePath lastPathComponent], result->faceCount, "faces", kOOMeshIndexMax);
		}
	}
	
	if (OK && (result->vertexCount < 3 || result->faceCount < 1))
	{
		OK = NO;
		NSLog(@"A valid mesh must have at least 3 vertices and one face, but %@ has %u vertices and %u faces.", [inFilePath lastPathComponent], result->vertexCount, result->faceCount);
	}
	
	triangles = result->vertexCount - 2;
	if (OK && kOOMeshIndexMax - result->triangleCount < triangles)
	{
		OK = NO;
		NSLog(@"%@ cannot be read by Oolite. It contains too many triangles - Oolite can handle at most %u.", [inFilePath lastPathComponent], kOOMeshIndexMax);
	}
	else result->triangleCount += triangles;
	
	// Load vertices
	if (OK) OK = [lexer passRequiredToken:kOoliteDatToken_VERTEX_SECTION];
	if (OK)
	{
		result->vertices = calloc(sizeof(Vector), result->vertexCount);
		if (NULL == result->vertices)
		{
			DisposeDATData(&result);
			NSLog(@"%@ could not be loaded, because there is not enough memory.", [inFilePath lastPathComponent]);
			OK = NO;
		}
	}
	if (OK) for (vertexIndex = 0; OK && vertexIndex != result->vertexCount; ++vertexIndex)
	{
		if (![lexer readVector:&result->vertices[vertexIndex]]) OK = NO;
		if (OK) OK = [lexer passAtLeastOneLineBreak];
	}
	
	// Load faces
	if (OK) OK = [lexer passRequiredToken:kOoliteDatToken_FACES_SECTION];
	if (OK)
	{
		result->faces = calloc(sizeof(DATFace), result->faceCount);
		if (NULL == result->faces)
		{
			DisposeDATData(&result);
			NSLog(@"%@ could not be loaded, because there is not enough memory.", [inFilePath lastPathComponent]);
			OK = NO;
		}
		face = result->faces;
	}
	if (OK) for (faceIndex = 0; faceIndex != result->faceCount; ++faceIndex)
	{
		// Read and discard colour
		if (![lexer readInteger:NULL] ||
			![lexer readInteger:NULL] ||
			![lexer readInteger:NULL])
		{
			OK = NO;
			break;
		}
		
		// Read normal. As currently defined DAT always has one normal per face.
		if (![lexer readVector:&face->normal]) { OK = NO; break; }
		
		// Read vertex count
		if (![lexer readInteger:&faceVertexCount]) { OK = NO; break; }
		face->vertexCount = faceVertexCount;
		
		if (faceVertexCount < 3)
		{
			NSLog(@"%@ cannot be loaded, because it contains an invalid polygon with only %u sides.", faceVertexCount);
			OK = NO; break;
		}
		
		for (vertexIndex = 0; vertexIndex != faceVertexCount; ++vertexIndex)
		{
			if (![lexer readInteger:&longIndex]) OK = NO;
			if (result->vertexCount == longIndex) OK = NO;
			face->vertices[vertexIndex] = longIndex;
		}
		
		if (OK) OK = [lexer passAtLeastOneLineBreak];
		if (!OK) break;
		++face;
	}
	
	if (OK)
	{
		if (kOoliteDatToken_TEXTURES_SECTION == [lexer nextToken:nil])
		{
			// Load textures
			materialLUT = [NSMutableDictionary dictionary];
			if (nil == materialLUT)
			{
				DisposeDATData(&result);
				NSLog(@"%@ could not be loaded, because there is not enough memory.", [inFilePath lastPathComponent]);
				OK = NO;
			}
			
			if (OK)
			{
				face = result->faces;
				for (faceIndex = 0; faceIndex != result->faceCount; ++faceIndex)
				{
					// Read material name
					if (![lexer readString:&materialName]) { OK = NO; break; }
					
					// Note: at this stage materials aren’t retained except by materialLUT (which is
					// itself autoreleased). As such, the materials can be considered autoreleased.
					face->material = [materialLUT objectForKey:materialName];
					if (nil == face->material)
					{
						face->material = [[OOMaterial alloc] initWithMainTextureName:materialName options:[inOptions objectForKey:materialName]];
						[materialLUT setObject:face->material forKey:materialName];
						[face->material release];
					}
					
					// Read texture scale
					if (![lexer readReal:&scaleS] ||
						![lexer readReal:&scaleT]) { OK = NO; break; }
					
					// Read texture co-ordinates for each vertex
					for (vertexIndex = 0; OK && vertexIndex != face->vertexCount; ++vertexIndex)
					{
						if (![lexer readReal:&scaleS] ||
							![lexer readReal:&scaleT]) { OK = NO; break; }
						
						face->texCoords[vertexIndex].s = s * scaleS;
						face->texCoords[vertexIndex].t = t * scaleT;
					}
		
					if (OK) OK = [lexer passAtLeastOneLineBreak];
					if (!OK) break;
					++face;
				}
			}
		}
		else
		{
			// No textures specified in file; use fall-back.
			SetUpDefaultTexturesForDAT(result);
		}
	}
	
	if (!OK) DisposeDATData(&result);
	
	return result;
}


static void DisposeDATData(DATData **ioDataPtr)
{
	if (NULL != ioDataPtr && NULL != *ioDataPtr)
	{
		if (NULL != (*ioDataPtr)->vertices)
		{
			free((*ioDataPtr)->vertices);
			(*ioDataPtr)->vertices = NULL;
		}
		if (NULL != (*ioDataPtr)->faces)
		{
			free((*ioDataPtr)->faces);
			(*ioDataPtr)->faces = NULL;
		}
		
		free(*ioDataPtr);
		*ioDataPtr = NULL;
	}
}


static void SetUpDefaultTexturesForDAT(DATData *ioData)
{
	// This just makes untextured objects pink.
	OOMeshIndex				faceCount;
	DATFace					*face;
	OOMaterial				*material;
	
	if (NULL == ioData || 0 == ioData->faceCount) return;
	
	material = [[[OOMaterial alloc] initWithMainTextureName:@"left_metal.png" options:nil] autorelease];
	
	face = ioData->faces;
	faceCount = ioData->faceCount;
	do
	{
		face->material = material;
	} while (--faceCount);
}
