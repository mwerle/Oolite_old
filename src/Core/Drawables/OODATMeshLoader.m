/*

OODATMeshLoader.h

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

#import "OODATMeshLoader.h"
#import "OOCollectionExtractors.h"


enum
{
	kOODATMeshMaxVertsPerFace	= 16
};


typedef struct OODATMeshLoaderFace
{
	GLuint					smoothGroup;
	GLuint					vertexCount;
	GLuint					materialIndex;
	GLuint					vertex[kOODATMeshMaxVertsPerFace];
	
	Vector					normal;
	Vector					tangent;
	GLfloat					u[kOODATMeshMaxVertsPerFace];
	GLfloat					v[kOODATMeshMaxVertsPerFace];
} OODATMeshLoaderFace;


static NSString *CleanData(NSString *data);
static NSScanner *LoadDataScanner(NSString *path, NSString *displayName);


@interface OODATMeshLoader (Internal)

// Allocate all per-vertex/per-face buffers.
- (BOOL) allocateVertexBuffersWithCount:(OOUInteger)count;
- (BOOL) allocateFaceBuffersWithCount:(OOUInteger)count;

- (BOOL) checkNormalsAndAdjustWinding;
- (BOOL) calculateVertexNormals;

- (void) submitGeometry;

@end



@implementation OODATMeshLoader

#if STATIC_ANALYSIS
- (void) dealloc
{
	/*	Placate clang static analyzer. (Super's dealloc calls -releaseData,
		which does the actual deallocing.)
	*/
	[super dealloc];
}
#endif


- (BOOL) performLoad
{
	NSScanner			*scanner = nil;
	unsigned			i, j;
	int					intValue;
	
	_smooth = [[self loadingController] shouldUseSmoothShading];
	
	scanner = LoadDataScanner([self filePath], [self fileName]);
	if (scanner == nil)
	{
		[self reportProblemWithKey:@"mesh.load.failed.fileNotFound"
							 fatal:YES
							format:@"Could not load mesh file \"%@\".", [self fileName]];
		return NO;
	}
	
	_materialKeys = [[NSMutableArray alloc] init];
	
	// get number of vertices
	if ([scanner scanString:@"NVERTS" intoString:NULL] && [scanner scanInt:&intValue])
	{
		_vertexCount = intValue;
	}
	else
	{
		[self reportProblemWithKey:@"mesh.load.failed.badFormat"
							 fatal:YES
							format:@"Failed to parse mesh \"%@\" - could not read %@ value.", [self fileName], @"NVERTS"];
		return NO;
	}
	
	// get number of faces
	if ([scanner scanString:@"NFACES" intoString:NULL] && [scanner scanInt:&intValue])
	{
		_faceCount = intValue;
	}
	else
	{
		[self reportProblemWithKey:@"mesh.load.failed.badFormat"
							 fatal:YES
							format:@"Failed to parse mesh \"%@\" - could not read %@ value.", [self fileName], @"NFACES"];
		return NO;
	}
	
	if (![self allocateVertexBuffersWithCount:_vertexCount] || ![self allocateFaceBuffersWithCount:_faceCount])
	{
		[self releaseData];
		[self reportProblemWithKey:kOOLogAllocationFailure
							 fatal:YES
							format:@"Failed to allocate memory to load mesh \"%@\" with %u vertices and %u faces.", [self fileName], _vertexCount, _faceCount];
		return NO;
	}
	
	// Get vertex data.
	if ([scanner scanString:@"VERTEX" intoString:NULL])
	{
		for (j = 0; j < _vertexCount; j++)
		{
			if (![scanner scanFloat:&_vertices[j].x] ||
				![scanner scanFloat:&_vertices[j].y] ||
				![scanner scanFloat:&_vertices[j].z])
			{
				[self reportProblemWithKey:@"mesh.load.failed.badFormat"
									 fatal:YES
									format:@"Failed to parse mesh \"%@\" - could not read vertex %u.", [self fileName], j];
				return NO;
			}
		}
	}
	else
	{
		[self reportProblemWithKey:@"mesh.load.failed.badFormat"
							 fatal:YES
							format:@"Failed to parse mesh \"%@\" - %@ section not found where expected.", [self fileName], @"VERTEX"];
		return NO;
	}
	
	// Get face data.
	if ([scanner scanString:@"FACES" intoString:NULL])
	{
		for (j = 0; j < _faceCount; j++)
		{
			// First three columns are smoothing group followed by two unusued values (used to be RGB colour).
			if ([scanner scanInt:&intValue])  _faces[j].smoothGroup = intValue;
			else
			{
				[self reportProblemWithKey:@"mesh.load.failed.badFormat"
									 fatal:YES
									format:@"Failed to parse mesh \"%@\" - could not read smoothing group for face %u.", [self fileName], j];
				return NO;
			}
			if (![scanner scanInt:&intValue] || ![scanner scanInt:&intValue])
			{
				[self reportProblemWithKey:@"mesh.load.failed.badFormat"
									 fatal:YES
									format:@"Failed to parse mesh \"%@\" - could not read reserved attributes for face %u.", [self fileName], j];
				return NO;
			}
			
			// Next three columns are face normal.
			if (![scanner scanFloat:&_faces[j].normal.x] ||
				![scanner scanFloat:&_faces[j].normal.y] ||
				![scanner scanFloat:&_faces[j].normal.z])
			{
				[self reportProblemWithKey:@"mesh.load.failed.badFormat"
									 fatal:YES
									format:@"Failed to parse mesh \"%@\" - could not read normal for face %u.", [self fileName], j];
				return NO;
			}
			
			// Next column is vertex count.
			if ([scanner scanInt:&intValue])  _faces[j].vertexCount = intValue;
			else
			{
				[self reportProblemWithKey:@"mesh.load.failed.badFormat"
									 fatal:YES
									format:@"Failed to parse mesh \"%@\" - could not read vertex count for face %u.", [self fileName], j];
				return NO;
			}
			if (_faces[j].vertexCount > kOODATMeshMaxVertsPerFace)
			{
				[self reportProblemWithKey:@"mesh.load.failed.badData"
									 fatal:YES
									format:@"Face %u of mesh \"%@\" has %u vertices, but no more than %u are supported.", j, [self fileName], _faces[j].vertexCount, kOODATMeshMaxVertsPerFace];
				return NO;
			}
			
			// Remaining columns are vertexCount vertex indices.
			for (i = 0; i < _faces[j].vertexCount; i++)
			{
				if ([scanner scanInt:&intValue])  _faces[j].vertex[i] = intValue;
				else
				{
					[self reportProblemWithKey:@"mesh.load.failed.badFormat"
										 fatal:YES
										format:@"Failed to parse mesh \"%@\" - could not read vertex index %u for face %u.", [self fileName], i, j];
					return NO;
				}
			}
		}
	}
	else
	{
		[self reportProblemWithKey:@"mesh.load.failed.badFormat"
							 fatal:YES
							format:@"Failed to parse mesh \"%@\" - %@ section not found where expected.", [self fileName], @"FACES"];
		return NO;
	}
	
	// Get material data.
	if ([scanner scanString:@"TEXTURES" intoString:NULL])
	{
		NSMutableDictionary *texFileName2Idx = [NSMutableDictionary dictionary];
		
		for (j = 0; j < _faceCount; j++)
		{
			NSString	*materialKey;
			float		maxU, maxV;
			float		u, v;
			
			// Get material key.
			[scanner scanCharactersFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet] intoString:NULL];
			if ([scanner scanUpToCharactersFromSet:[NSCharacterSet whitespaceCharacterSet] intoString:&materialKey])
			{
				NSNumber *index = [texFileName2Idx objectForKey:materialKey];
				if (index != nil)
				{
					_faces[j].materialIndex = [index unsignedIntValue];
				}
				else
				{
					_faces[j].materialIndex = [_materialKeys count];
					index = [NSNumber numberWithUnsignedInt:_faces[j].materialIndex];
					[_materialKeys addObject:materialKey];
					[texFileName2Idx setObject:index forKey:materialKey];
				}
			}
			else
			{
				[self reportProblemWithKey:@"mesh.load.failed.badFormat"
									 fatal:YES
									format:@"Failed to parse mesh \"%@\" - could not read material key for face %u.", [self fileName], j];
				return NO;
			}
			
			// Get texture scale (two floats).
			if (![scanner scanFloat:&maxU] ||
				![scanner scanFloat:&maxV])
			{
				[self reportProblemWithKey:@"mesh.load.failed.badFormat"
									 fatal:YES
									format:@"Failed to parse mesh \"%@\" - could not read texture scale for face %u.", [self fileName], j];
				return NO;
			}
			
			// U/V coordinates per vertex.
			for (i = 0; i < _faces[j].vertexCount; i++)
			{
				if ([scanner scanFloat:&u] &&
					[scanner scanFloat:&v])
				{
					_faces[j].u[i] = u / maxU;
					_faces[j].v[i] = v / maxV;
				}
				else
				{
					[self reportProblemWithKey:@"mesh.load.failed.badFormat"
										 fatal:YES
										format:@"Failed to parse mesh \"%@\" - could not read texture coordinates for vertex %u of face %u.", [self fileName], i, j];
					return NO;
				}
			}
		}
	}
	else
	{
		[self reportProblemWithKey:@"mesh.load.failed.badFormat"
							 fatal:NO
							format:@"Mesh \"%@\" has no TEXTURES section, using placeholder material.", [self fileName]];
		
		[_materialKeys addObject:kOOPlaceholderMaterialName];
		
		for (j = 0; j < _faceCount; j++)
		{
			_faces[j].materialIndex = 0;
		}
	}
	
	[self checkNormalsAndAdjustWinding];
	
	// check for smooth shading and recalculate normals
	if (_smooth)
	{
		if (![self calculateVertexNormals])  return NO;
	}
	
	[self submitGeometry];
	
	return YES;
}


- (BOOL) allocateVertexBuffersWithCount:(OOUInteger)count
{
	_vertices = malloc(sizeof *_vertices * count);
	_normals = malloc(sizeof *_normals * count);
	if (_smooth)  _tangents = malloc(sizeof *_tangents * count);
	return (_vertices != NULL && _normals != NULL && (!_smooth || _tangents != NULL));
}


- (BOOL) allocateFaceBuffersWithCount:(OOUInteger)count
{
	_faces = malloc(sizeof *_faces * count);
	return (_faces != NULL);
}


- (BOOL) checkNormalsAndAdjustWinding
{
	Vector				calculatedNormal, v0, v1, v2, normal;
	GLuint				faceIdx, vertIdx;
	OODATMeshLoaderFace	*face = NULL;
	
	for (faceIdx = 0; faceIdx < _faceCount; faceIdx++)
	{
		face = &_faces[faceIdx];
		
		v0 = _vertices[face->vertex[0]];
		v1 = _vertices[face->vertex[1]];
		v2 = _vertices[face->vertex[2]];
		normal = face->normal;
		
		calculatedNormal = normal_to_surface(v2, v1, v0);
		if (vector_equal(normal, kZeroVector))
		{
			normal = normal_to_surface(v0, v1, v2);
			face->normal = normal;
		}
		
		if (normal.x * calculatedNormal.x < 0 ||
			normal.y * calculatedNormal.y < 0 ||
			normal.z * calculatedNormal.z < 0)
		{
			// Normal direction is wrong, reverse winding.
			for (vertIdx = 0; vertIdx < face->vertexCount / 2; vertIdx++)
			{
				GLuint vtx = face->vertex[vertIdx];
				GLfloat u = face->u[vertIdx];
				GLfloat v = face->v[vertIdx];
				
				face->vertex[vertIdx] = face->vertex[face->vertexCount - vertIdx - 1];
				face->u[vertIdx] = face->u[face->vertexCount - vertIdx - 1];
				face->v[vertIdx] = face->v[face->vertexCount - vertIdx - 1];
				
				face->vertex[face->vertexCount - 1 - vertIdx] = vtx;
				face->u[face->vertexCount - 1 - vertIdx] = u;
				face->v[face->vertexCount - 1 - vertIdx] = v;
			}
		}
	}
	
	return YES;
}


static float FaceArea(GLuint *vertIndices, Vector *vertices)
{
	// Fixme: loading once again deals with up to 16 verts per face, but this
	// assumes triangles.
	
	// calculate areas using Herons formula
	// in the form Area = sqrt(2*(a2*b2+b2*c2+c2*a2)-(a4+b4+c4))/4
	float	a2 = distance2(vertices[vertIndices[0]], vertices[vertIndices[1]]);
	float	b2 = distance2(vertices[vertIndices[1]], vertices[vertIndices[2]]);
	float	c2 = distance2(vertices[vertIndices[2]], vertices[vertIndices[0]]);
	return sqrtf(2.0 * (a2 * b2 + b2 * c2 + c2 * a2) - 0.25 * (a2 * a2 + b2 * b2 +c2 * c2));
}


- (BOOL) calculateVertexNormals
{
	GLuint				faceIdx, vertIdx, fvIdx;
	GLfloat				*faceArea = NULL;
	GLfloat				area;
	Vector				normalSum, tangentSum;
	BOOL				isShared = NO;
	OODATMeshLoaderFace	*face = NULL;
	
	faceArea = malloc(sizeof *faceArea * _faceCount);
	if (faceArea == NULL)
	{
		[self releaseData];
		[self reportProblemWithKey:kOOLogAllocationFailure
							 fatal:YES
							format:@"Failed to allocate memory to load mesh \"%@\" with %u vertices and %u faces.", [self fileName], _vertexCount, _faceCount];
		return NO;
	}
	
	for (faceIdx = 0; faceIdx < _faceCount; faceIdx++)
	{
		faceArea[faceIdx] = FaceArea(_faces[faceIdx].vertex, _vertices);
	}
	
	// Nasty O(n,m) calculation...
	for (vertIdx = 0; vertIdx < _vertexCount; vertIdx++)
	{
		normalSum = kZeroVector;
		tangentSum = kZeroVector;
		
		for (faceIdx = 0; faceIdx < _faceCount; faceIdx++)
		{
			isShared = NO;
			face = &_faces[faceIdx];
			
			// Check to see if face #faceIdx uses vertex #vertIdx
			for (fvIdx = 0; fvIdx < face->vertexCount; fvIdx++)
			{
				if (face->vertex[fvIdx] == vertIdx)
				{
					isShared = YES;
					break;
				}
			}
			
			if (isShared)
			{
				area = faceArea[faceIdx];
				
				// sum += this * area
				normalSum = vector_add(normalSum, vector_multiply_scalar(face->normal, area));
				tangentSum = vector_add(tangentSum, vector_multiply_scalar(face->tangent, area));
			}
		}
		
		_normals[vertIdx] = vector_normal_or_fallback(normalSum, kBasisZVector);
		_tangents[vertIdx] = vector_normal_or_fallback(tangentSum, kBasisXVector);
	}
	
	free(faceArea);
	
	return YES;
}


- (void) submitGeometry
{
	GLuint					matIdx, matCount;
	GLuint					faceIdx, vertIdx;
	Vector					verts[kOODATMeshMaxVertsPerFace];
	Vector					normals[kOODATMeshMaxVertsPerFace];
	Vector					tangents[kOODATMeshMaxVertsPerFace];
	GLfloat					texUVs[kOODATMeshMaxVertsPerFace * 2];
	id<OOMeshBuilder>		builder = nil;
	
	builder = [self meshBuilder];
	matCount = [_materialKeys count];
	for (matIdx = 0; matIdx < matCount; matIdx++)
	{
		[builder startMaterialWithKey:[_materialKeys stringAtIndex:matIdx]];
		
		for (faceIdx = 0; faceIdx < _faceCount; faceIdx++)
		{
			struct OODATMeshLoaderFace *face = &_faces[faceIdx];
			
			if (face->materialIndex == matIdx)
			{
				assert(face->vertexCount <= kOODATMeshMaxVertsPerFace);
				
				for (vertIdx = 0; vertIdx < face->vertexCount; vertIdx++)
				{
					verts[vertIdx] = _vertices[face->vertex[vertIdx]];
					if (_smooth)
					{
						normals[vertIdx] = _normals[face->vertex[vertIdx]];
						tangents[vertIdx] = _tangents[face->vertex[vertIdx]];
					}
					else
					{
						normals[vertIdx] = face->normal;
						tangents[vertIdx] = face->tangent;
					}
					texUVs[vertIdx * 2] = face->u[vertIdx];
					texUVs[vertIdx * 2 + 1] = face->v[vertIdx];
				}
				[builder addPolygonWithVertices:verts
										normals:normals
									   tangents:tangents
									 textureUVs:texUVs
										  count:face->vertexCount];
			}
		}
	}
}


- (void) releaseData
{
	free(_vertices);
	_vertices = NULL;
	
	free(_normals);
	_normals = NULL;
	
	free(_tangents);
	_tangents = NULL;
	
	free(_faces);
	_faces = NULL;
	
	[_materialKeys release];
	_materialKeys = nil;
	
	[super releaseData];
}

@end


// TODO: this would benefit significantly from using a simple custom tokenizer instead of NSScanner.
static NSString *CleanData(NSString *data)
{
	// strip out comments and commas between values
	NSMutableArray	*lines = [NSMutableArray arrayWithArray:[data componentsSeparatedByString:@"\n"]];
	OOUInteger		i;
	
	for (i = 0; i < [lines count]; i++)
	{
		NSString *line = [lines objectAtIndex:i];
		NSArray *parts = nil;
		
		// comments
		parts = [line componentsSeparatedByString:@"#"];
		line = [parts objectAtIndex:0];
		parts = [line componentsSeparatedByString:@"//"];
		line = [parts objectAtIndex:0];
		
		// commas
		line = [[line componentsSeparatedByString:@","] componentsJoinedByString:@" "];
		
		[lines replaceObjectAtIndex:i withObject:line];
	}
	return [lines componentsJoinedByString:@"\n"];
}


static NSScanner *LoadDataScanner(NSString *path, NSString *displayName)
{
	NSAutoreleasePool		*pool = nil;
	NSString				*data = nil;
	NSScanner				*scanner = nil;
	
	/*	Load data, strip out comments and commas, and create NSScanner.
		Done in an autorelease pool because it creates lots of temporary
		objects.
	*/
	
	pool = [[NSAutoreleasePool alloc] init];
	
	data = [NSString stringWithContentsOfFile:path];
	if (data != nil)
	{
		data = CleanData(data);
		scanner = [NSScanner scannerWithString:data];
	}
	
	[scanner retain];
	[pool drain];
	return [scanner autorelease];
}
