/*

JoystickHandler.m

Oolite
Copyright (C) 2004-2010 Giles C Williams and contributors

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

Copyright (C) 2006-2010 Jens Ayton

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

#import "JoystickHandler.h"

OO_MAC_BEGIN_EXPORT


static Class sStickHandlerClass = Nil;
static JoystickHandler *sSharedStickHandler = nil;


@implementation JoystickHandler

+ (id) sharedStickHandler
{
	if (sSharedStickHandler == nil)
	{
		if (sStickHandlerClass == Nil)  sStickHandlerClass = [JoystickHandler class];
		sSharedStickHandler = [[sStickHandlerClass alloc] init];
	}
	return sSharedStickHandler;
}


- (OOUInteger) getNumSticks
{
	return 0;
}


- (NSPoint) getRollPitchAxis
{
	return NSZeroPoint;
}


- (NSPoint) getViewAxis
{
	return NSZeroPoint;
}


- (double) getAxisState:(OOJoystickAxisFunction)function
{
	NSParameterAssert(function < AXIS_end);
	return 0.0;
}


- (double) getSensitivity
{
	return 1.0;
}


- (const BOOL *) getAllButtonStates
{
	return butstate;
}


+ (BOOL) setStickHandlerClass:(Class)stickHandlerClass
{
	// Can't set class after handler has been created.
	if (sSharedStickHandler != nil)  return NO;
	
	Class jsClass = [JoystickHandler class];
	
	if (stickHandlerClass != Nil)
	{
		NSParameterAssert([stickHandlerClass isSubclassOfClass:jsClass/*[JoystickHandler class]*/]);
	}
	
	sStickHandlerClass = stickHandlerClass;
	return YES;
}


- (void) setButtonState:(BOOL)state forButton:(OOJoystickButtonFunction)button
{
	NSParameterAssert(button < BUTTON_end);
	butstate[button] = state;
}

// actual implementation of the following methods is in OOLeopardHIDJoystickHandler

- (NSArray *)listSticks
{
	NSMutableArray *stickList=[NSMutableArray array];
	return stickList;
}

- (void) unsetButtonFunction: (int)function
{
}

- (void) unsetAxisFunction: (int)function
{
}

- (void)saveStickSettings
{
}

- (NSDictionary *)getAxisFunctions
{
	NSMutableDictionary *fnList=[NSMutableDictionary dictionary];
	return fnList;
}


- (NSDictionary *)getButtonFunctions
{
	NSMutableDictionary *fnList=[NSMutableDictionary dictionary];
	return fnList;
}

- (void) setFunctionForAxis: (int)axis 
                   function: (int)function
                      stick: (int)stickNum
{
}


- (void) setFunctionForButton: (int)button 
                     function: (int)function 
                        stick: (int)stickNum
{
}

- (void) setFunction: (int)function  withDict: (NSDictionary *)stickFn
{
}

- (void)setCallback: (SEL) selector
             object: (id) obj
           hardware: (char)hwflags
{
}


- (void)clearCallback
{
}

@end


OO_MAC_END_EXPORT
