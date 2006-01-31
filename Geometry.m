/*

	Oolite

	Geometry.m
	
	Created by Giles Williams on 30/01/2006.


Copyright (c) 2005, Giles C Williams
All rights reserved.

This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike License.
To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/2.0/
or send a letter to Creative Commons, 559 Nathan Abbott Way, Stanford, California 94305, USA.

You are free:

•	to copy, distribute, display, and perform the work
•	to make derivative works

Under the following conditions:

•	Attribution. You must give the original author credit.

•	Noncommercial. You may not use this work for commercial purposes.

•	Share Alike. If you alter, transform, or build upon this work,
you may distribute the resulting work only under a license identical to this one.

For any reuse or distribution, you must make clear to others the license terms of this work.

Any of these conditions can be waived if you get permission from the copyright holder.

Your fair use and other rights are in no way affected by the above.

*/

#import "Geometry.h"

#import "vector.h"
#import "ShipEntity.h"


@implementation Geometry

- (NSString*) description
{
	NSString* result = [[NSString alloc] initWithFormat:@"<Geometry with %d triangles currently %@.>", n_triangles, [self testIsConvex]? @"Convex":@"not convex"];
	return [result autorelease];
}

- (id) initWithCapacity:(int) amount
{
	if (amount < 1)
		return nil;
	self = [super init];
	
	max_triangles = amount;
	triangles = (Triangle*) malloc( max_triangles * sizeof(Triangle));	// allocate the required space
	n_triangles = 0;
	
	return self;
}

- (void) dealloc
{
	free((void *)triangles);	// free up the allocated space
	[super dealloc];
}

- (void) addTriangle:(Triangle) tri
{
	if (n_triangles == max_triangles)
	{
		// create more space by doubling the capacity of this geometry...
		int i;
		max_triangles = 1 + max_triangles * 2;
		Triangle* old_triangles = triangles;
		Triangle* new_triangles = (Triangle *) malloc( max_triangles * sizeof(Triangle));
		for (i = 0; i < n_triangles; i++)
			new_triangles[i] = old_triangles[i];	// copy old->new
		triangles = new_triangles;
		free((void *) old_triangles);	// free up previous memory
	}
	triangles[n_triangles++] = tri;
}

- (BOOL) testHasGeometry
{
	return (n_triangles > 0);
}

- (BOOL) testIsConvex
{
	// enumerate over triangles
	// calculate normal for each one
	// then enumerate over vertices relative to a vertex on the triangle
	// and check if they are on the forwardside or coplanar with the triangle
	// if a vertex is on the backside of any triangle then return NO;
	int i, j;
	for (i = 0; i < n_triangles; i++)
	{
		Vector v0 = triangles[i].v[0];
		Vector vn = calculateNormalForTriangle(&triangles[i]);
		//
		for (j = 0; j < n_triangles; j++)
		{
			if (j != i)
			{
				if ((dot_product( vector_between( v0, triangles[j].v[0]), vn) < -0.001)||
					(dot_product( vector_between( v0, triangles[j].v[1]), vn) < -0.001)||
					(dot_product( vector_between( v0, triangles[j].v[2]), vn) < -0.001))	// within 1mm tolerance
				{
					isConvex = NO;
					return NO;
				}
			}
		}
	}
	isConvex = YES;
	return YES;
}

- (void) translate:(Vector) offset
{
	int i;
	for (i = 0; i < n_triangles; i++)
	{
		triangles[i].v[0].x += offset.x;
		triangles[i].v[1].x += offset.x;
		triangles[i].v[2].x += offset.x;
		triangles[i].v[0].y += offset.y;
		triangles[i].v[1].y += offset.y;
		triangles[i].v[2].y += offset.y;
		triangles[i].v[0].z += offset.z;
		triangles[i].v[1].z += offset.z;
		triangles[i].v[2].z += offset.z;
	}
}

- (void) scale:(GLfloat) scalar
{
	int i;
	for (i = 0; i < n_triangles; i++)
	{
		triangles[i].v[0].x *= scalar;
		triangles[i].v[1].x *= scalar;
		triangles[i].v[2].x *= scalar;
		triangles[i].v[0].y *= scalar;
		triangles[i].v[1].y *= scalar;
		triangles[i].v[2].y *= scalar;
		triangles[i].v[0].z *= scalar;
		triangles[i].v[1].z *= scalar;
		triangles[i].v[2].z *= scalar;
	}
}

- (void) x_axisSplitBetween:(Geometry*) g_plus :(Geometry*) g_minus
{
	// test each triangle splitting agist x == 0.0
	//
	int i;
	for (i = 0; i < n_triangles; i++)
	{
		BOOL done_tri = NO;
		Vector v0 = triangles[i].v[0];
		Vector v1 = triangles[i].v[1];
		Vector v2 = triangles[i].v[2];
		if ((v0.x >= 0.0)&&(v1.x >= 0.0)&&(v2.x >= 0.0))
		{
			[g_plus addTriangle: triangles[i]];
			done_tri = YES;
		}
		if ((v0.x <= 0.0)&&(v1.x <= 0.0)&&(v2.x <= 0.0))
		{
			[g_minus addTriangle: triangles[i]];
			done_tri = YES;
		}
		if (!done_tri)	// triangle must cross y == 0.0
		{
			GLfloat i01, i12, i20;
			if (v0.x == v1.x)
				i01 = -1.0;
			else
				i01 = v0.x / (v0.x - v1.x);
			if (v1.x == v2.x)
				i12 = -1.0;
			else
				i12 = v1.x / (v1.x - v2.x);
			if (v2.x == v0.x)
				i20 = -1.0;
			else
				i20 = v2.x / (v2.x - v0.x);
			Vector v01 = make_vector( 0.0, i01 * (v1.y - v0.y) + v0.y, i01 * (v1.z - v0.z) + v0.z);
			Vector v12 = make_vector( 0.0, i12 * (v2.y - v1.y) + v1.y, i12 * (v2.z - v1.z) + v1.z);
			Vector v20 = make_vector( 0.0, i20 * (v0.y - v2.y) + v2.y, i20 * (v0.z - v2.z) + v2.z);
		
			if ((0.0 < i01)&&(i01 < 1.0))	// line from v0->v1 intersects z==0
			{
				if ((0.0 < i20)&&(i20 < 0.0))	// line from v2->v0 intersects z==0
				{
					// v0 is on the 'triangle' side of x==0
					Triangle t1 = make_triangle( v0, v01, v20);
					// v1 and v2 are on the 'quad' side of x==0
					Triangle t2 = make_triangle( v01, v1, v2);
					Triangle t3 = make_triangle( v2, v20, v01);
					if (v0.x > 0.0)
					{
						[g_plus addTriangle:t1];
						[g_minus addTriangle:t2];
						[g_minus addTriangle:t3];
					}
					else
					{
						[g_minus addTriangle:t1];
						[g_plus addTriangle:t2];
						[g_plus addTriangle:t3];
					}
				}
				else
				{
					// v0 and v2 are on the 'quad' side of x==0
					Triangle t1 = make_triangle( v0, v01, v12);
					Triangle t2 = make_triangle( v01, v12, v2);
					//
					Triangle t3 = make_triangle( v1, v12, v01);
					if (v0.x > 0.0)
					{
						[g_plus addTriangle:t1];
						[g_plus addTriangle:t2];
						[g_minus addTriangle:t3];
					}
					else
					{
						[g_minus addTriangle:t1];
						[g_minus addTriangle:t2];
						[g_plus addTriangle:t3];
					}
				}
			}
			else
			{
				// v0 and v1 are on the 'quad' side of y ==0
				Triangle t1 = make_triangle( v0, v1, v20);
				Triangle t2 = make_triangle( v1, v12, v20);
				//
				Triangle t3 = make_triangle( v2, v20, v12);
				if (v0.x > 0.0)
				{
					[g_plus addTriangle:t1];
					[g_plus addTriangle:t2];
					[g_minus addTriangle:t3];
				}
				else
				{
					[g_minus addTriangle:t1];
					[g_minus addTriangle:t2];
					[g_plus addTriangle:t3];
				}
			
			}

		}
	}
}

- (void) y_axisSplitBetween:(Geometry*) g_plus :(Geometry*) g_minus
{
	// test each triangle splitting agist y == 0.0
	//
	int i;
	for (i = 0; i < n_triangles; i++)
	{
		BOOL done_tri = NO;
		Vector v0 = triangles[i].v[0];
		Vector v1 = triangles[i].v[1];
		Vector v2 = triangles[i].v[2];
		if ((v0.y >= 0.0)&&(v1.y >= 0.0)&&(v2.y >= 0.0))
		{
			[g_plus addTriangle: triangles[i]];
			done_tri = YES;
		}
		if ((v0.y <= 0.0)&&(v1.y <= 0.0)&&(v2.y <= 0.0))
		{
			[g_minus addTriangle: triangles[i]];
			done_tri = YES;
		}
		if (!done_tri)	// triangle must cross y == 0.0
		{
			GLfloat i01, i12, i20;
			if (v0.y == v1.y)
				i01 = -1.0;
			else
				i01 = v0.y / (v0.y - v1.y);
			if (v1.y == v2.y)
				i12 = -1.0;
			else
				i12 = v1.y / (v1.y - v2.y);
			if (v2.y == v0.y)
				i20 = -1.0;
			else
				i20 = v2.y / (v2.y - v0.y);
			Vector v01 = make_vector( i01 * (v1.x - v0.x) + v0.x, 0.0, i01 * (v1.z - v0.z) + v0.z);
			Vector v12 = make_vector( i12 * (v2.x - v1.x) + v1.x, 0.0, i12 * (v2.z - v1.z) + v1.z);
			Vector v20 = make_vector( i20 * (v0.x - v2.x) + v2.x, 0.0, i20 * (v0.z - v2.z) + v2.z);
		
			if ((0.0 < i01)&&(i01 < 1.0))	// line from v0->v1 intersects y==0
			{
				if ((0.0 < i20)&&(i20 < 0.0))	// line from v2->v0 intersects y==0
				{
					// v0 is on the 'triangle' side of y==0
					Triangle t1 = make_triangle( v0, v01, v20);
					// v1 and v2 are on the 'quad' side of y==0
					Triangle t2 = make_triangle( v01, v1, v2);
					Triangle t3 = make_triangle( v2, v20, v01);
					if (v0.y > 0.0)
					{
						[g_plus addTriangle:t1];
						[g_minus addTriangle:t2];
						[g_minus addTriangle:t3];
					}
					else
					{
						[g_minus addTriangle:t1];
						[g_plus addTriangle:t2];
						[g_plus addTriangle:t3];
					}
				}
				else
				{
					// v0 and v2 are on the 'quad' side of y==0
					Triangle t1 = make_triangle( v0, v01, v12);
					Triangle t2 = make_triangle( v01, v12, v2);
					//
					Triangle t3 = make_triangle( v1, v12, v01);
					if (v0.y > 0.0)
					{
						[g_plus addTriangle:t1];
						[g_plus addTriangle:t2];
						[g_minus addTriangle:t3];
					}
					else
					{
						[g_minus addTriangle:t1];
						[g_minus addTriangle:t2];
						[g_plus addTriangle:t3];
					}
				}
			}
			else
			{
				// v0 and v1 are on the 'quad' side of y ==0
				Triangle t1 = make_triangle( v0, v1, v20);
				Triangle t2 = make_triangle( v1, v12, v20);
				//
				Triangle t3 = make_triangle( v2, v20, v12);
				if (v0.y > 0.0)
				{
					[g_plus addTriangle:t1];
					[g_plus addTriangle:t2];
					[g_minus addTriangle:t3];
				}
				else
				{
					[g_minus addTriangle:t1];
					[g_minus addTriangle:t2];
					[g_plus addTriangle:t3];
				}
			
			}
		}
	}
}

- (void) z_axisSplitBetween:(Geometry*) g_plus :(Geometry*) g_minus
{
	// test each triangle splitting agist z == 0.0
	//
	int i;
	for (i = 0; i < n_triangles; i++)
	{
		BOOL done_tri = NO;
		Vector v0 = triangles[i].v[0];
		Vector v1 = triangles[i].v[1];
		Vector v2 = triangles[i].v[2];
		if ((v0.z >= 0.0)&&(v1.z >= 0.0)&&(v2.z >= 0.0))
		{
			[g_plus addTriangle: triangles[i]];
			done_tri = YES;
		}
		if ((v0.z <= 0.0)&&(v1.z <= 0.0)&&(v2.z <= 0.0))
		{
			[g_minus addTriangle: triangles[i]];
			done_tri = YES;
		}
		if (!done_tri)	// triangle must cross y == 0.0
		{
			GLfloat i01, i12, i20;
			if (v0.z == v1.z)
				i01 = -1.0;
			else
				i01 = v0.z / (v0.z - v1.z);
			if (v1.z == v2.z)
				i12 = -1.0;
			else
				i12 = v1.z / (v1.z - v2.z);
			if (v2.z == v0.z)
				i20 = -1.0;
			else
				i20 = v2.z / (v2.z - v0.z);
			Vector v01 = make_vector( i01 * (v1.x - v0.x) + v0.x, i01 * (v1.y - v0.y) + v0.y, 0.0);
			Vector v12 = make_vector( i12 * (v2.x - v1.x) + v1.x, i12 * (v2.y - v1.y) + v1.y, 0.0);
			Vector v20 = make_vector( i20 * (v0.x - v2.x) + v2.x, i20 * (v0.y - v2.y) + v2.y, 0.0);
		
			if ((0.0 < i01)&&(i01 < 1.0))	// line from v0->v1 intersects z==0
			{
				if ((0.0 < i20)&&(i20 < 0.0))	// line from v2->v0 intersects z==0
				{
					// v0 is on the 'triangle' side of z==0
					Triangle t1 = make_triangle( v0, v01, v20);
					// v1 and v2 are on the 'quad' side of z==0
					Triangle t2 = make_triangle( v01, v1, v2);
					Triangle t3 = make_triangle( v2, v20, v01);
					if (v0.z > 0.0)
					{
						[g_plus addTriangle:t1];
						[g_minus addTriangle:t2];
						[g_minus addTriangle:t3];
					}
					else
					{
						[g_minus addTriangle:t1];
						[g_plus addTriangle:t2];
						[g_plus addTriangle:t3];
					}
				}
				else
				{
					// v0 and v2 are on the 'quad' side of z==0
					Triangle t1 = make_triangle( v0, v01, v12);
					Triangle t2 = make_triangle( v01, v12, v2);
					//
					Triangle t3 = make_triangle( v1, v12, v01);
					if (v0.z > 0.0)
					{
						[g_plus addTriangle:t1];
						[g_plus addTriangle:t2];
						[g_minus addTriangle:t3];
					}
					else
					{
						[g_minus addTriangle:t1];
						[g_minus addTriangle:t2];
						[g_plus addTriangle:t3];
					}
				}
			}
			else
			{
				// v0 and v1 are on the 'quad' side of y ==0
				Triangle t1 = make_triangle( v0, v1, v20);
				Triangle t2 = make_triangle( v1, v12, v20);
				//
				Triangle t3 = make_triangle( v2, v20, v12);
				if (v0.z > 0.0)
				{
					[g_plus addTriangle:t1];
					[g_plus addTriangle:t2];
					[g_minus addTriangle:t3];
				}
				else
				{
					[g_minus addTriangle:t1];
					[g_minus addTriangle:t2];
					[g_plus addTriangle:t3];
				}
			
			}
		}
	}
}

@end
