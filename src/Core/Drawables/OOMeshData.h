/*

OOMeshData.h

Low-level representation of meshes. Each mesh consists of a list of elements,
where an element is a vertex, a normal, a tangent and a texture coordinate
pair. Elements are referenced through the index array. The index array is
divided into ranges, with each range having an associated material; these
ranges are defined by materialIndexOffsets and materialIndexCounts.

The index array itself can consist of GLubytes, GLshorts or GLints, depending
on size. OOMeshDataGetElementIndex() and associated helper functions abstract
this, at least for purposes of reading.

Note that textureUVArray contains two entries per element, which are
textureUVArray[elementIndex * 2] and textureUVArray[elementIndex * 2 + 1].


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

#if __cplusplus
extern "C" {
#endif



typedef struct OOMeshData
{
	GLuint					elementCount;
	GLuint					indexCount;
	GLuint					materialCount;
	
	GLenum					indexType;	// GL_UNSIGNED_INT, GL_UNSIGNED_SHORT or GL_UNSIGNED_BYTE
	void					*indexArray;
	
	// Element arrays
	Vector					*vertexArray;
	Vector					*normalArray;
	Vector					*tangentArray;
	GLfloat					*textureUVArray;
	
	// Per-material info
	GLuint					*materialIndexOffsets;
	GLuint					*materialIndexCounts;
	OOMaterial				**materials;
	
	NSArray					*materialKeys;
} OOMeshData;


//	Functions for accessing OOMeshData elements.
size_t OOMeshDataIndexSize(GLenum indexType);
BOOL OOMeshDataGetElementIndex(OOMeshData *meshData, GLuint index, GLuint *outElement)  NONNULL_FUNC;
OOINLINE BOOL OOMeshDataGetVertex(OOMeshData *meshData, GLuint index, Vector *outVertex)  NONNULL_FUNC;
OOINLINE BOOL OOMeshDataGetNormal(OOMeshData *meshData, GLuint index, Vector *outNormal)  NONNULL_FUNC;
OOINLINE BOOL OOMeshDataGetTangent(OOMeshData *meshData, GLuint index, Vector *outTangent)  NONNULL_FUNC;
OOINLINE BOOL OOMeshDataGetTextureUV(OOMeshData *meshData, GLuint index, GLfloat *outU, GLfloat *outV)  NONNULL_FUNC;

BOOL OOMeshDataDeepCopy(OOMeshData *inData, OOMeshData *outData, NSMutableArray **outRetainedObjects);


// Inline implementations only beyond this point.

OOINLINE BOOL OOMeshDataGetVertex(OOMeshData *meshData, GLuint index, Vector *outVertex)
{
	assert(outVertex != NULL);
	GLuint element;
	if (!OOMeshDataGetElementIndex(meshData, index, &element))  return NO;
	*outVertex = meshData->vertexArray[element];
	return YES;
}


OOINLINE BOOL OOMeshDataGetNormal(OOMeshData *meshData, GLuint index, Vector *outNormal)
{
	assert(outNormal != NULL);
	GLuint element;
	if (!OOMeshDataGetElementIndex(meshData, index, &element))  return NO;
	*outNormal = meshData->normalArray[element];
	return YES;
}


OOINLINE BOOL OOMeshDataGetTangent(OOMeshData *meshData, GLuint index, Vector *outTangent)
{
	assert(outTangent != NULL);
	GLuint element;
	if (!OOMeshDataGetElementIndex(meshData, index, &element))  return NO;
	*outTangent = meshData->tangentArray[element];
	return YES;
}


OOINLINE BOOL OOMeshDataGetTextureUV(OOMeshData *meshData, GLuint index, GLfloat *outU, GLfloat *outV)
{
	assert(outU != NULL && outV != NULL);
	GLuint element;
	if (!OOMeshDataGetElementIndex(meshData, index, &element))  return NO;
	*outU = meshData->textureUVArray[element * 2];
	*outV = meshData->textureUVArray[element * 2 + 1];
	return YES;
}


#if __cplusplus
}
#endif
