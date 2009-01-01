/*

OOConcreteMeshBuilder.m 

Oolite
Copyright (C) 2004-2008 Giles C Williams and contributors

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


This file may also be distributed under the MIT/X11 license:

Copyright (C) 2008-2009 Jens Ayton

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

*/

#import "OOConcreteMeshBuilder.h"
#import "OOMeshLoader.h"
#import "OOMeshData.h"
#import "OOCollectionExtractors.h"

#define OOMESH_EPSILON	(1e-6f)


/*	Class representing a single vertex (position, normal, u, v tuple) for
 purposes of finding duplicates.
 */
@interface OOMeshBuilderVertex: NSObject <NSCopying>
{
@private
	Vector					_position;
	Vector					_normal;
	Vector					_tangent;
	GLfloat					_u, _v;
}

- (id) initWithPosition:(Vector)position
				 normal:(Vector)normal
				tangent:(Vector)tangent
					  u:(GLfloat)u
					  v:(GLfloat)v;

- (Vector) position;
- (Vector) normal;
- (Vector) tangent;
- (void) getU:(GLfloat *)outU v:(GLfloat *)outV;
- (void) getPosition:(Vector *)outPosition normal:(Vector *)outNormal tangent:(Vector *)outTangent u:(GLfloat *)outU v:(GLfloat *)outV;

@end


@interface OOConcreteMeshBuilder (Private)

- (void) commitCurrentMaterial;
- (NSNumber *) indexForVertexWithPosition:(Vector)position
								   normal:(Vector)normal
								  tangent:(Vector)tangent
										u:(GLfloat)u
										v:(GLfloat)v;

- (BOOL) fillInMeshData:(struct OOMeshData *)outData;
- (BOOL) loadMaterialsForData:(struct OOMeshData *)data;

- (void *) allocateBytesWithSize:(size_t)size count:(OOUInteger)count;

@end


static void SynthesizeTangents(Vector *vertices, Vector *normals, float *textureUVs, Vector *tangents, GLuint count);


@implementation OOConcreteMeshBuilder

- (id) initWithMeshLoader:(OOMeshLoader *)loader
{
	if (loader == nil)
	{
		[self release];
		return nil;
	}
	
	if ((self = [super init]))
	{
		_loader = loader;
		_loadingController = [loader loadingController];
		[loader setMeshBuilder:self];
		
		_dataByMaterial = [[NSMutableDictionary alloc] init];
		_allMaterialKeys = [[NSMutableArray alloc] init];
		OOLogAlloc(_allMaterialKeys);
		_allVertices = [[NSMutableArray alloc] init];
		OOLogAlloc(_allVertices);
		_allIndices = [[NSMutableArray alloc] init];
		OOLogAlloc(_allIndices);
		_verticesToIndices = [[NSMutableDictionary alloc] init];
	}
	
	return self;
}


- (void) dealloc
{
	// loadingController is not owned and therefore not released.
	[self releaseData];
	
	[super dealloc];
}


- (OOMeshLoader *) meshLoader
{
	return _loader;
}


- (BOOL) loadDataGettingMeshData:(struct OOMeshData *)outData
				 retainedObjects:(NSMutableArray **)outRetainedObjects
{
	NSAutoreleasePool	*pool = [[NSAutoreleasePool alloc] init];
	BOOL				OK = YES;
	
	NS_DURING
		if ([[self meshLoader] performLoad] && ![[self meshLoader] encounteredFatalProblem])
		{
			[self commitCurrentMaterial];
		}
		else
		{
			[self releaseData];
			OK = NO;
		}
	NS_HANDLER
		OK = NO;
		[[self meshLoader] reportProblemWithKey:@"mesh.load.failed.exception"
										  fatal:YES
										 format:@"Failed to load mesh \"%@\" - encountered unexpected exception (%@: %@).",
												[[self meshLoader] fileName], [localException name], [localException reason]];
	NS_ENDHANDLER
	[pool release];
	if (!OK)  return NO;
	
	if (OK)  OK = [self fillInMeshData:outData];
	[self releaseData];
	
	if (OK)  OK = [self loadMaterialsForData:outData];
	
	if (OK)  *outRetainedObjects = _retainedObjects;
	
	[_retainedObjects autorelease];
	_retainedObjects = nil;
	
	return OK;
}


// *** <OOMeshBuilder>


- (void) startMaterialWithKey:(NSString *)key
{
	[self commitCurrentMaterial];
	
	_currentMaterialKey = [key copy];
	if (_currentMaterialKey == nil)  return;
	
	[_allMaterialKeys addObject:key];
	
	_currentMaterialStartIndex = _nextIndex;
}


- (BOOL) addPolygonWithVertices:(Vector *)vertices
						normals:(Vector *)normals
					   tangents:(Vector *)tangents
					 textureUVs:(GLfloat *)textureUVs
						  count:(GLuint)count
{
	if (count < 3)
	{
		if (!_notedDegenerateGeometry)
		{
			_notedDegenerateGeometry = YES;
			[[self meshLoader] reportProblemWithKey:@"mesh.load.degenerateGeometry"
											  fatal:NO
											 format:@"Mesh \"%@\" contains faces with fewer than three vertices. These will be ignored.", [[self meshLoader] fileName]];
			return YES;	// Not a fatal problem
		}
	}
	
	if (_currentMaterialKey == nil)
	{
		[[self meshLoader] reportProblemWithKey:@"mesh.load.internalError.loaderFailedToStartMaterial"
										  fatal:YES
										 format:@"Mesh loader %@ for \"%@\" failed to start a material before committing geometry. This is an internal error, please report it.", self, [[self meshLoader] fileName]];
		return NO;
	}
	
	BOOL OK = YES;
	BOOL freeTangents = NO;
	if (tangents == NULL || vector_equal(tangents[0], kZeroVector))
	{
		tangents = malloc(sizeof *tangents * count);
		if (tangents == NULL)
		{
			[self releaseData];
			[[self meshLoader] reportProblemWithKey:kOOLogAllocationFailure
											  fatal:YES
											 format:@"Out of memory."];
			OK = NO;
		}
		else
		{
			freeTangents = YES;
			SynthesizeTangents(vertices, normals, textureUVs, tangents, count);
		}
	}
	
	// This triangulates N-gons by turning them into triangle fans.
	if (OK)
	{
		GLuint i;
		NSNumber *index0 = nil, *index1 = nil, *indexN = nil;
		
		index0 = [self indexForVertexWithPosition:vertices[0]
										   normal:normals[0]
										  tangent:tangents[0]
												u:textureUVs[0]
												v:textureUVs[1]];
		index1 = [self indexForVertexWithPosition:vertices[1]
										   normal:normals[1]
										  tangent:tangents[1]
												u:textureUVs[2]
												v:textureUVs[3]];
		
		if (index0 == nil || index1 == nil)
		{
			OK = NO;
		}
		else
		{
			for (i = 2; i != count; i++)
			{
				indexN = [self indexForVertexWithPosition:vertices[i]
												   normal:normals[i]
												  tangent:tangents[i]
														u:textureUVs[i * 2]
														v:textureUVs[i * 2 + 1]];
				if (indexN == nil)
				{
					OK = NO;
					break;
				}
				
				// Add triangle
				[_allIndices addObject:index0];
				[_allIndices addObject:index1];
				[_allIndices addObject:indexN];
			}
		}
		
		if (!OK)
		{
			[self releaseData];
			[[self meshLoader] reportProblemWithKey:kOOLogAllocationFailure
											  fatal:YES
											 format:@"Out of memory."];
		}
	}
	
	if (OK)  _nextIndex += count;
	if (freeTangents)  free(tangents);
	return OK;
}


- (void) releaseData
{
	[_dataByMaterial release];
	_dataByMaterial = nil;
	
	[_allMaterialKeys release];
	_allMaterialKeys = nil;
	
	[_currentMaterialKey release];
	_currentMaterialKey = nil;
	
	[_allIndices release];
	_allIndices = nil;
	
	[_allVertices release];
	_allVertices = nil;
	
	[_verticesToIndices release];
	_verticesToIndices = nil;
	
	[_loader releaseData];
	if ([_loader meshBuilder] == self)  [_loader setMeshBuilder:nil];
	[_loader release];
	_loader = nil;
}


#if STATIC_ANALYSIS
- (GLuint) nextElement
{
	// Placate clang static analyzer. (_nextElement is otherwise only used in categories.)
	return _nextElement;
}
#endif

@end


@implementation OOConcreteMeshBuilder (Private)


- (void) commitCurrentMaterial
{
	if (_nextIndex != _currentMaterialStartIndex)
	{
		// Add to completed materials
		NSDictionary *completed = [NSDictionary dictionaryWithObjectsAndKeys:
								   [NSNumber numberWithUnsignedInt:_currentMaterialStartIndex], @"startIndex",
								   [NSNumber numberWithUnsignedInt:_nextIndex - _currentMaterialStartIndex], @"count",
								   nil];
		
		[_dataByMaterial setObject:completed forKey:_currentMaterialKey];
	}
	
	[_currentMaterialKey release];
	_currentMaterialKey = nil;
}


- (NSNumber *) indexForVertexWithPosition:(Vector)position normal:(Vector)normal tangent:(Vector)tangent u:(GLfloat)u v:(GLfloat)v
{
	OOMeshBuilderVertex *vertex = [[OOMeshBuilderVertex alloc] initWithPosition:position
																	   normal:normal
																	  tangent:tangent
																			u:u
																			v:v];
	if (vertex == nil)  return nil;
	
	// Look for matching vertex to avoid redundancy
	NSNumber *index = [_verticesToIndices objectForKey:vertex];
	
	if (index == nil)
	{
		// Add to vertex table
		index = [NSNumber numberWithUnsignedInt:_nextElement++];
		[_verticesToIndices setObject:index forKey:vertex];
		[_allVertices addObject:vertex];
	}
	
	[vertex release];
	return index;
}


- (BOOL) fillInMeshData:(struct OOMeshData *)outData
{
	// Set up the necessary buffers
	outData->elementCount = [_allVertices count];
	outData->indexCount = [_allIndices count];
	outData->materialCount = [_allMaterialKeys count];
	
	_retainedObjects = [[NSMutableArray alloc] initWithCapacity:9 + outData->materialCount];
	OOLogAlloc(_retainedObjects);
	
	if (outData->indexCount < 0xFF)  outData->indexType = GL_UNSIGNED_BYTE;
	else if (outData->indexCount < 0xFFFF)  outData->indexType = GL_UNSIGNED_SHORT;
	else outData->indexType = GL_UNSIGNED_INT;
	
	outData->indexArray = [self allocateBytesWithSize:OOMeshDataIndexSize(outData->indexType) count:outData->indexCount];
	outData->vertexArray = [self allocateBytesWithSize:sizeof (Vector) count:outData->elementCount];
	outData->normalArray = [self allocateBytesWithSize:sizeof (Vector) count:outData->elementCount];
	outData->tangentArray = [self allocateBytesWithSize:sizeof (Vector) count:outData->elementCount];
	outData->textureUVArray = [self allocateBytesWithSize:sizeof (GLfloat) * 2 count:outData->elementCount];
	outData->materialIndexOffsets = [self allocateBytesWithSize:sizeof (GLuint) count:outData->materialCount];
	outData->materialIndexCounts = [self allocateBytesWithSize:sizeof (GLuint) count:outData->materialCount];
	outData->materials = [self allocateBytesWithSize:sizeof (OOMaterial *) count:outData->materialCount];
	outData->materialKeys = [_allMaterialKeys copy];
	
	if (outData->indexArray == NULL ||
		outData->vertexArray == NULL ||
		outData->normalArray == NULL ||
		outData->tangentArray == NULL ||
		outData->textureUVArray == NULL ||
		outData->materialIndexOffsets == NULL ||
		outData->materialIndexCounts == NULL ||
		outData->materials == NULL ||
		outData->materialKeys == nil)
	{
		return NO;
	}
	
	// Copy vertex/element data
	OOUInteger i, count;
	for (i = 0; i < outData->elementCount; i++)
	{
		OOMeshBuilderVertex *vertex = [_allVertices objectAtIndex:i];
		[vertex getPosition:&outData->vertexArray[i]
					 normal:&outData->normalArray[i]
					tangent:&outData->tangentArray[i]
						  u:&outData->textureUVArray[i * 2]
						  v:&outData->textureUVArray[i * 2 + 1]];
	}
	
	// Copy material info
	count = [_allMaterialKeys count];
	for (i = 0; i < count; i++)
	{
		NSDictionary *data = [_dataByMaterial objectForKey:[_allMaterialKeys objectAtIndex:i]];
		outData->materialIndexOffsets[i] = [data unsignedLongForKey:@"startIndex"];
		outData->materialIndexCounts[i] = [data unsignedLongForKey:@"count"];
	}
	
	// Copy indices
	count = outData->indexCount;
	if (outData->indexType == GL_UNSIGNED_BYTE)
	{
		GLubyte *indexB = outData->indexArray;
		for (i = 0; i < count; i++)
		{
			GLubyte valB = [_allIndices unsignedCharAtIndex:i];
			*indexB++ = valB;
		}
	}
	else if (outData->indexType == GL_UNSIGNED_SHORT)
	{
		GLushort *indexS = outData->indexArray;
		for (i = 0; i < count; i++)
		{
			GLushort valS = [_allIndices unsignedShortAtIndex:i];
			*indexS++ = valS;
		}
	}
	else if (outData->indexType == GL_UNSIGNED_INT)
	{
		GLuint *indexI = outData->indexArray;
		for (i = 0; i < count; i++)
		{
			GLuint valI = [_allIndices unsignedIntAtIndex:i];
			*indexI++ = valI;
		}
	}
	else
	{
		return NO;
	}
	return YES;
}


- (BOOL) loadMaterialsForData:(struct OOMeshData *)data
{
	OOUInteger		i, count;
	
	count = data->materialCount;
	for (i = 0; i < count; i++)
	{
		data->materials[i] = [_loadingController loadMaterialWithKey:[data->materialKeys objectAtIndex:i]];
		if (data->materials[i] == nil)  return NO;
		
		[_retainedObjects addObject:data->materials[i]];
	}
	
	return YES;
}


- (void *) allocateBytesWithSize:(size_t)size count:(OOUInteger)count
{
	size *= count;
	void *bytes = malloc(size);
	if (bytes != NULL)
	{
		NSData *holder = [NSData dataWithBytesNoCopy:bytes length:size freeWhenDone:YES];
		[_retainedObjects addObject:holder];
	}
	return bytes;
}

@end


static BOOL CompareFloats(GLfloat a, GLfloat b)
{
	return fabsf(a - b) < OOMESH_EPSILON;
}



static GLfloat CleanFloat(GLfloat f)
{
	GLfloat rounded = roundf(f);
	if (CompareFloats(f, rounded))  f = rounded;
	if (f == -0.0f)  f = 0.0f;
	return f;
}


static Vector CleanVector(Vector v)
{
	return make_vector(CleanFloat(v.x), CleanFloat(v.y), CleanFloat(v.z));
}

@implementation OOMeshBuilderVertex

- (id) initWithPosition:(Vector)position
				 normal:(Vector)normal
				tangent:(Vector)tangent
					  u:(GLfloat)u
					  v:(GLfloat)v
{
	self = [super init];
	if (self != nil)
	{
		_position = CleanVector(position);
		_normal = CleanVector(vector_normal(normal));
		_tangent = CleanVector(vector_normal(tangent));
		_u = CleanFloat(u);
		_v = CleanFloat(v);
	}
	return self;
}


- (id) copyWithZone:(NSZone *)zone
{
	// OOMeshBuilderVertex is immutable
	return [self retain];
}


- (BOOL) isEqual:(id)other
{
	if (![other isKindOfClass:[OOMeshBuilderVertex class]])  return NO;
	
	OOMeshBuilderVertex *otherV = other;
	return	vector_equal(_position, otherV->_position) &&
	vector_equal(_normal, otherV->_normal) &&
	vector_equal(_tangent, otherV->_tangent) &&
	_u == otherV->_u &&
	_v == otherV->_v;
}


static inline void Hash(OOUInteger *ioHash, OOUInteger value)
{
	assert(ioHash != NULL);
	*ioHash = *ioHash * 31 + value;
}


static inline void HashFloat(OOUInteger *ioHash, GLfloat value)
{
	Hash(ioHash, *(uint32_t *)&value);
}


static inline void HashVector(OOUInteger *ioHash, Vector vector)
{
	HashFloat(ioHash, vector.x);
	HashFloat(ioHash, vector.y);
	HashFloat(ioHash, vector.z);
}


- (OOUInteger) hash
{
	OOUInteger result = 1;
	HashVector(&result, _position);
	HashVector(&result, _normal);
	HashVector(&result, _tangent);
	HashFloat(&result, _u);
	HashFloat(&result, _v);
	return result;
}


- (NSString *) descriptionComponents
{
	return [NSString stringWithFormat:@"%@ %@ %@ %g, %g", VectorDescription(_position), VectorDescription(_normal), VectorDescription(_tangent), _u, _v];
}


- (NSString *) shortDescriptionComponents
{
	return VectorDescription(_position);
}


- (Vector) position
{
	return _position;
}


- (Vector) normal
{
	return _normal;
}


- (Vector) tangent
{
	return _tangent;
}


- (void) getU:(GLfloat *)outU v:(GLfloat *)outV
{
	if (outU != NULL)  *outU = _u;
	if (outV != NULL)  *outV = _v;
}


- (void) getPosition:(Vector *)outPosition normal:(Vector *)outNormal tangent:(Vector *)outTangent u:(GLfloat *)outU v:(GLfloat *)outV
{
	assert(outPosition != NULL && outNormal != NULL && outTangent != NULL && outU != NULL && outV != NULL);
	
	*outPosition = _position;
	*outNormal = _normal;
	*outTangent = _tangent;
	*outU = _u;
	*outV = _v;
}

@end


static void SynthesizeTangents(Vector *vertices, Vector *normals, float *textureUVs, Vector *tangents, GLuint count)
{
	/*	Calculate tangent for a face. Despite the name, this generates one
	 tangent and uses it for all vertices.
	 TODO: does this make sense for more than three vertices? Possibly
	 the face should be triangulated before tangent generation. As it is,
	 it's treating vertex 0, 1 and 2 as a triangle and ignoring the rest.
	 On top of that, using normals[0] doesn't make much sense for non-flat
	 faces. Basically, this is bogus. Bah.
	 
	 Based on code I found in a forum somewhere and
	 then lost track of. Sorry to whomever I should be crediting.
	 -- Ahruman 2008-11-23
	 */
	
	Vector vAB = vector_subtract(vertices[1], vertices[0]);
	Vector vAC = vector_subtract(vertices[2], vertices[0]);
	Vector nA = normals[0];
	
	// projAB = aB - (nA . vAB) * nA
	Vector vProjAB = vector_subtract(vAB, vector_multiply_scalar(nA, dot_product(nA, vAB)));
	Vector vProjAC = vector_subtract(vAC, vector_multiply_scalar(nA, dot_product(nA, vAC)));
	
	// delta u/v
	GLfloat dsAB = textureUVs[2] - textureUVs[0];
	GLfloat dsAC = textureUVs[4] - textureUVs[0];
	GLfloat dtAB = textureUVs[3] - textureUVs[1];
	GLfloat dtAC = textureUVs[5] - textureUVs[1];
	
	if (dsAC * dtAB > dsAB * dtAC)
	{
		dsAB = -dsAB;
		dsAC = -dsAC;
	}
	
	Vector tangent = vector_subtract(vector_multiply_scalar(vProjAB, dsAC), vector_multiply_scalar(vProjAC, dsAB));
	if (magnitude2(tangent) > 0.0)
	{
		tangent = cross_product(nA, tangent);	// Rotate 90 degrees. Done this way because I'm too lazy to grok the code above.
	}
	else
	{
		tangent = kBasisYVector;
	}
	
	GLuint i;
	for (i = 0; i != count; i++)
	{
		tangents[i] = tangent;
	}
}
