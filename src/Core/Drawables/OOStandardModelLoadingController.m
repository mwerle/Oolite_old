/*

OOStandardModelLoadingController.m
 

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

#import "OOStandardModelLoadingController.h"
#import "OOLogging.h"
#import "ResourceManager.h"
#import "OOMaterial.h"


@implementation OOStandardModelLoadingController

- (id) initWithFileName:(NSString *)fileName
	 materialDictionary:(NSDictionary *)materialDict
	  shadersDictionary:(NSDictionary *)shadersDict
				 smooth:(BOOL)smooth
		   shaderMacros:(NSDictionary *)macros
	shaderBindingTarget:(id<OOWeakReferenceSupport>)object
{
	if ((self = [super init]))
	{
		_fileName = [fileName copy];
		_materialDict = [materialDict copy];
		_shadersDict = [materialDict copy];
		_smooth = smooth;
		_macros = [macros copy];
		_bindingTarget = [object weakRetain];
	}
	
	return self;
}


- (void) dealloc
{
	[_fileName release];
	[_materialDict release];
	[_shadersDict release];
	[_macros release];
	[_bindingTarget release];
	
	[super dealloc];
}


- (void) reportProblemWithKey:(NSString *)key
						fatal:(BOOL)isFatal
					   format:(NSString *)format, ...
{
	va_list args;
	va_start(args, format);
	[self reportProblemWithKey:key
						 fatal:isFatal
						format:format
					 arguments:args];
	va_end(args);
}


- (void) reportProblemWithKey:(NSString *)key
						fatal:(BOOL)isFatal
					   format:(NSString *)format
					arguments:(va_list)args
{
	NSString *prefix = isFatal ? @"***** ERROR: " : @"----- WARNING: ";
	format = [prefix stringByAppendingString:format];
	OOLogWithFunctionFileAndLineAndArguments(key, NULL, NULL, 0, format, args);
}


- (NSString *) pathForMeshNamed:(NSString *)name
{
	return [ResourceManager pathForFileNamed:name inFolder:@"Models"];
}


- (OOMaterial *) loadMaterialWithKey:(NSString *)key
{
	/*	TODO: material selection and synthesis should be part of the loading
		controller, not OOMaterial itself.
	*/
	return [OOMaterial materialWithName:key
						  forModelNamed:_fileName
					 materialDictionary:_materialDict
					  shadersDictionary:_shadersDict
								 macros:_macros
						  bindingTarget:_bindingTarget
						forSmoothedMesh:_smooth];
}


// Only applies to model formats with no direct representation of vertices.
- (BOOL) shouldUseSmoothShading
{
	return _smooth;
}


- (BOOL) permitCacheRead
{
	return YES;
}


- (BOOL) permitCacheWrite
{
	return YES;
}

@end


@implementation OOMesh (OOStandardModelLoadingController)

+ (id)meshWithName:(NSString *)name
materialDictionary:(NSDictionary *)materialDict
 shadersDictionary:(NSDictionary *)shadersDict
			smooth:(BOOL)smooth
	  shaderMacros:(NSDictionary *)macros
shaderBindingTarget:(id<OOWeakReferenceSupport>)object
{
	OOStandardModelLoadingController	*loadingController = nil;
	OOMesh								*result = nil;
	
	loadingController = [[OOStandardModelLoadingController alloc] initWithFileName:name
																materialDictionary:materialDict
																 shadersDictionary:shadersDict
																			smooth:smooth
																	  shaderMacros:macros
															   shaderBindingTarget:object];
	
	result = [[self alloc] initWithLoadingController:loadingController fileName:name];
	[loadingController release];
	return [result autorelease];
}

@end
