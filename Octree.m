/*

	Oolite

	Octree.m
	
	Created by Giles Williams on 31/01/2006.


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

#import "Octree.h"
#import "vector.h"
#import "OOOpenGL.h"


@implementation Octree

- (id) init
{
	self = [super init];
	radius = 0;
	leafs = 0;
	octree = malloc(sizeof(int));
	octree[0] = 0;
	return self;
}

- (void) dealloc
{
	free(octree);
	[super dealloc];
}

- (GLfloat) radius
{
	return radius;
}

- (int) leafs
{
	return leafs;
}

- (int*) octree
{
	return octree;
}

- (id) initWithRepresentationOfOctree:(GLfloat) octRadius :(NSObject*) octreeArray :(int) leafsize
{
	self = [super init];
	
	radius = octRadius;
	leafs = leafsize;
	octree = malloc(leafsize *sizeof(int));

	int i;
	for (i = 0; i< leafsize; i++)
		octree[i] = 0;
	
	NSLog(@"---> %d", copyRepresentationIntoOctree( octreeArray, octree, 0, 1));
		
	return self;
}

int copyRepresentationIntoOctree(NSObject* theRep, int* theBuffer, int atLocation, int nextFreeLocation)
{
	if ([theRep isKindOfClass:[NSNumber class]])
	{
		if ([(NSNumber*)theRep intValue] != 0)
		{
			theBuffer[atLocation] = -1;
			return nextFreeLocation;
		}
		else
		{
			theBuffer[atLocation] = 0;
			return nextFreeLocation;
		}
	}
	if ([theRep isKindOfClass:[NSArray class]])
	{
		NSArray* theArray = (NSArray*)theRep;
		int i;
		int theNextSpace = nextFreeLocation + 8;
		for (i = 0; i < 8; i++)
		{
			NSObject* rep = [theArray objectAtIndex:i];
			theNextSpace = copyRepresentationIntoOctree( rep, theBuffer, nextFreeLocation + i, theNextSpace);
		}
		theBuffer[atLocation] = nextFreeLocation;
		return theNextSpace;
	}
	NSLog(@"**** some error creating octree *****");
	return nextFreeLocation;
}

- (void) drawOctree
{
	// it's a series of cubes
	[self drawOctreeFromLocation:0 :radius :make_vector( 0.0, 0.0, 0.0)];
//	if (octreeRep)
//		[self drawOctreeWithRepresentation:octreeRep :radius :make_vector( 0.0, 0.0, 0.0)];
}

- (void) drawOctreeFromLocation:(int) loc :(GLfloat) scale :(Vector) offset
{
	if (octree[loc] == 0)
		return;
	if (octree[loc] == -1)	// full
	{
		// draw a cube
		glDisable(GL_CULL_FACE);			// face culling
		
		glDisable(GL_TEXTURE_2D);

		glBegin(GL_LINE_STRIP);
			
		glVertex3f(-scale + offset.x, -scale + offset.y, -scale + offset.z);
		glVertex3f(-scale + offset.x, scale + offset.y, -scale + offset.z);
		glVertex3f(scale + offset.x, scale + offset.y, -scale + offset.z);
		glVertex3f(scale + offset.x, -scale + offset.y, -scale + offset.z);
		glVertex3f(-scale + offset.x, -scale + offset.y, -scale + offset.z);
		
		glEnd();
		
		glBegin(GL_LINE_STRIP);
			
		glVertex3f(-scale + offset.x, -scale + offset.y, scale + offset.z);
		glVertex3f(-scale + offset.x, scale + offset.y, scale + offset.z);
		glVertex3f(scale + offset.x, scale + offset.y, scale + offset.z);
		glVertex3f(scale + offset.x, -scale + offset.y, scale + offset.z);
		glVertex3f(-scale + offset.x, -scale + offset.y, scale + offset.z);
		
		glEnd();
			
		glBegin(GL_LINES);
			
		glVertex3f(-scale + offset.x, -scale + offset.y, -scale + offset.z);
		glVertex3f(-scale + offset.x, -scale + offset.y, scale + offset.z);
		
		glVertex3f(-scale + offset.x, scale + offset.y, -scale + offset.z);
		glVertex3f(-scale + offset.x, scale + offset.y, scale + offset.z);
		
		glVertex3f(scale + offset.x, scale + offset.y, -scale + offset.z);
		glVertex3f(scale + offset.x, scale + offset.y, scale + offset.z);
		
		glVertex3f(scale + offset.x, -scale + offset.y, -scale + offset.z);
		glVertex3f(scale + offset.x, -scale + offset.y, scale + offset.z);
		
		glEnd();
			
		glEnable(GL_CULL_FACE);			// face culling
		return;
	}
	if (octree[loc] > 0)
	{
		GLfloat sc = 0.5 * scale;
		glColor4f( 0.4, 0.4, 0.4, 0.5);	// gray translucent
		[self drawOctreeFromLocation:octree[loc] + 0 :sc :make_vector( offset.x - sc, offset.y - sc, offset.z - sc)];
		glColor4f( 0.0, 0.0, 1.0, 0.5);	// green translucent
		[self drawOctreeFromLocation:octree[loc] + 1 :sc :make_vector( offset.x - sc, offset.y - sc, offset.z + sc)];
		glColor4f( 0.0, 1.0, 0.0, 0.5);	// green translucent
		[self drawOctreeFromLocation:octree[loc] + 2 :sc :make_vector( offset.x - sc, offset.y + sc, offset.z - sc)];
		glColor4f( 0.0, 1.0, 1.0, 0.5);	// green translucent
		[self drawOctreeFromLocation:octree[loc] + 3 :sc :make_vector( offset.x - sc, offset.y + sc, offset.z + sc)];
		glColor4f( 1.0, 0.0, 0.0, 0.5);	// green translucent
		[self drawOctreeFromLocation:octree[loc] + 4 :sc :make_vector( offset.x + sc, offset.y - sc, offset.z - sc)];
		glColor4f( 1.0, 0.0, 1.0, 0.5);	// green translucent
		[self drawOctreeFromLocation:octree[loc] + 5 :sc :make_vector( offset.x + sc, offset.y - sc, offset.z + sc)];
		glColor4f( 1.0, 1.0, 0.0, 0.5);	// green translucent
		[self drawOctreeFromLocation:octree[loc] + 6 :sc :make_vector( offset.x + sc, offset.y + sc, offset.z - sc)];
		glColor4f( 1.0, 1.0, 1.0, 0.5);	// green translucent
		[self drawOctreeFromLocation:octree[loc] + 7 :sc :make_vector( offset.x + sc, offset.y + sc, offset.z + sc)];
	}
}

@end
