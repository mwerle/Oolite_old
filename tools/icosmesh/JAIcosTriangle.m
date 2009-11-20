//
//  JAIcosTriangle.m
//  icosmesh
//
//  Created by Jens Ayton on 2009-11-18.
//  Copyright 2009 Jens Ayton. All rights reserved.
//

#import "JAIcosTriangle.h"


static inline BOOL IsPolarVector(Vector v)
{
	return v.x == 0.0 && v.z == 0.0;
}


@interface JAIcosTriangle ()

- (void) rotate;	// a = b, b = c, c = a
- (void) generateTextureCoordinates;	// Requires that any polar coordinate is in [0].

@end


static NSComparisonResult CompareVertices(Vertex *a, Vertex *b)
{
	return NSOrderedSame;
}


static NSString *VertexDescription(Vertex v)
{
	return [NSString stringWithFormat:@"{ %g, %g, %g} (%g, %g)", v.v.x, v.v.y, v.v.z, v.s, v.t];
}


@implementation JAIcosTriangle

+ (id) triangleWithVectorA:(Vector)a b:(Vector)b c:(Vector)c
{
	return [[[self alloc] initWithVectorA:a b:b c:c] autorelease];
}


- (id) initWithVectorA:(Vector)a b:(Vector)b c:(Vector)c
{
	if ((self = [super init]))
	{
		_vertices[0].v = VectorNormal(a);
		_vertices[1].v = VectorNormal(b);
		_vertices[2].v = VectorNormal(c);
		
		// If one of our vertices is a pole, make it the first.
		if (IsPolarVector(_vertices[2].v))  [self rotate];
		if (IsPolarVector(_vertices[1].v))  [self rotate];
		
		[self generateTextureCoordinates];
	}
	
	return self;
}


- (NSString *) description
{
	return [NSString stringWithFormat:@"{%@, %@, %@}", VertexDescription(_vertices[0]), VertexDescription(_vertices[1]), VertexDescription(_vertices[2])];
}


- (Vertex) vertexA
{
	return _vertices[0];
}


- (Vertex) vertexB
{
	return _vertices[1];
}


- (Vertex) vertexC
{
	return _vertices[2];
}


- (void) rotate
{
	Vertex temp = _vertices[0];
	_vertices[0] = _vertices[1];
	_vertices[1] = _vertices[2];
	_vertices[2] = temp;
}


- (void) generateTextureCoordinates
{
	VectorToCoords0_1(_vertices[1].v, &_vertices[1].t, &_vertices[1].s);
	VectorToCoords0_1(_vertices[2].v, &_vertices[2].t, &_vertices[2].s);
	if (!IsPolarVector(_vertices[0].v))  VectorToCoords0_1(_vertices[0].v, &_vertices[0].t, &_vertices[0].s);
	else
	{
		// Use longitude of average of v1 and v2.
		VectorToCoords0_1(VectorAdd(_vertices[1].v, _vertices[2].v), NULL, &_vertices[0].s);
		_vertices[0].t = (_vertices[0].v.y < 0) ? 1.0 : 0.0;
	}
	
	/*	Texture seam handling
		At the back of the mesh, at the longitude = 180°/-180° meridian, the
		texture wraps around. However, there isn't a convenient matching seam
		in the geometry - there are no great circles on a subdivided
		icosahedron - so we need to adjust texture coordinates and use the
		GL_REPEAT texture wrapping mode to cover it over.
		
		The technique is to establish whether we have at least one vertex in
		each of the (x, -z) and (-x, -z) quadrants, and if so, add 1 to the
		texture coordinates for the vertices in (-x, -z) -- corresponding to
		the east Pacific.
		
		NOTE: this technique is suboptimal because the selection of wrapped
		vertices changes at each subdivision level. Interpolating texture
		coordinates during subidivision, then finding the "nearest" option
		for "correct" calculated s for interpolated vertices could fix this.
	*/
	
	bool haveNXNZ = false;
	bool havePXNZ = false;
	unsigned i;
	for (i = 0; i < 3; i++)
	{
		if (_vertices[i].v.z < 0)
		{
			if (_vertices[i].v.x <= 0)
			{
				haveNXNZ = true;
			}
			else
			{
				havePXNZ = true;
			}
		}
	}
	
	if (haveNXNZ && havePXNZ)
	{
		for (i = 0; i < 3; i++)
		{
			if (_vertices[i].v.z < 0 && _vertices[i].v.x >= 0)
			{
				printf("Remapping %g -> %g\n", _vertices[i].s, _vertices[i].s + 1.0);
				_vertices[i].s += 1.0;
			}
		}
	}
}


- (NSArray *) subdivide
{
	Vector a = _vertices[0].v;
	Vector b = _vertices[1].v;
	Vector c = _vertices[2].v;
	
	Vector ab = VectorNormal(VectorAdd(a, b));
	Vector bc = VectorNormal(VectorAdd(b, c));
	Vector ca = VectorNormal(VectorAdd(c, a));
	
	/*	Note: vertex orders preserve winding. Triangle order is intended to be
		somewhat cache-friendly, but not as good as actually optimizing the
		data.
	*/
	JAIcosTriangle *subTris[4];
	subTris[0] = [JAIcosTriangle triangleWithVectorA:a b:ab c:ca];
	subTris[3] = [JAIcosTriangle triangleWithVectorA:ab b:bc c:ca];
	subTris[1] = [JAIcosTriangle triangleWithVectorA:ab b:b c:bc];
	subTris[2] = [JAIcosTriangle triangleWithVectorA:ca b:bc c:c];
	
	return [NSArray arrayWithObjects:subTris count:4];
}

@end
