/*

OOMeshBuilder.h

Protocol for objects that take data from an OOMeshLoader and convert it to
some usable form. The primary implementation is OOConcreteMeshBuilder, which
converts the data to OOMeshData for use by OOMesh.
 

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

#import "OOCocoa.h"
#import "OOMaths.h"
#import "OOModelLoadingController.h"


@protocol OOMeshBuilder <NSObject>

// Subclass is responsible for ensuring material keys are unique.
- (void) startMaterialWithKey:(NSString *)key;

/*	If this returns NO, it has reported a fatal problem and loading has
	failed. If tangents is NULL or first tangent is kZeroVector, tangents will
	be calculated based on UVs.
*/
- (BOOL) addPolygonWithVertices:(Vector *)vertices		// Must be convex
						normals:(Vector *)normals
					   tangents:(Vector *)tangents
					 textureUVs:(GLfloat *)textureUVs	// 2 * count
						  count:(GLuint)count;			// Ignored if count < 3

- (void) releaseData;

@end
