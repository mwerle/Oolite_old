/*
	OOMesh.h
	Oolite
	
	Implements a mesh, i.e. a 3D object consisting of polygons.
	
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

#import <Foundation/Foundation.h>
#import "OOOpenGL.h"
#import "OOMaterial.h"
#import "vector.h"


typedef uint_least16_t		OOMeshIndex;

enum
{
	kOOMeshIndexMax				= UINT_LEAST16_MAX - 1,
	kOOMeshIndexNotFound		= UINT_LEAST16_MAX
};


typedef struct OOTextureCoordinates
{
	float					s, t;
} OOTextureCoordinates;


typedef struct OOMeshFaceData
{
	OOMeshIndex				normal[3];
	OOMeshIndex				verts[3];
	OOMeshIndex				texCoords[3];
} OOMeshFaceData;


// A Face Set is a list of faces using the same material.
typedef struct OOMeshFaceSet
{
	OOMaterial				*material;
	OOMeshIndex				count;
	uint16_t				_padding;
	OOMeshFaceData			*faces;
} OOMeshFaceSet;


@interface OOMesh: NSObject
{
	OOMeshIndex					_faceSetCount;
	OOMeshIndex					_vertexCount;
	OOMeshIndex					_normalCount;
	OOMeshIndex					_texCoordsCount;
	
	OOMeshFaceSet				*_faceSets;
	
	// Do we need to separate vertices from normals?
	Vector						*_vertices;
	Vector						*_normals;
	OOTextureCoordinates		*_texCoords;
	
	NSString					*_key;	// For cache management and -description.
	
	GLuint						_displayList;
}

+ (id)meshWithFile:(NSString *)inFilePath options:(NSDictionary *)inOptions;

- (void)draw;

@end
