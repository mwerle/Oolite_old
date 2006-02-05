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

#import <Cocoa/Cocoa.h>
#import "OOOpenGL.h"
#import "vector.h"

@interface Octree : NSObject
{
	GLfloat		radius;
	int			leafs;
	int*		octree;
}

- (GLfloat)	radius;
- (int)		leafs;
- (int*)	octree;

- (id) initWithRepresentationOfOctree:(GLfloat) octRadius :(NSObject*) octreeArray :(int) leafsize;

int copyRepresentationIntoOctree(NSObject* theRep, int* theBuffer, int atLocation, int nextFreeLocation);

- (void) drawOctree;
- (void) drawOctreeFromLocation:(int) loc :(GLfloat) scale :(Vector) offset;

@end
