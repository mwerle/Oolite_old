/*

OOLeopardHIDJoystickHandler.m


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

Copyright (C) 2010 Jens Ayton, 2010 Maik Schulz

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

#import "OOLeopardHIDJoystickHandler.h"
#import <IOKit/hid/IOHIDLib.h>


@interface OOLeopardHIDJoystickHandler (Private)

- (void) setRollAxis:(CGFloat)roll;
- (void) setPitchAxis:(CGFloat)roll;
- (void) setYawAxis:(double)yaw;

- (void) setNumSticks:(OOUInteger)sticks;
- (void) setViewAxisX:(CGFloat)x;
- (void) setViewAxisY:(CGFloat)y;

- (void) handleHIDInputValueCallbackWithResult:(IOReturn)result sender:(void *)sender value:(IOHIDValueRef)hidValue;

@end


static NSDictionary *hu_CreateDeviceMatchingDictionary(UInt32 usagePage, UInt32 usage);
static void Handle_IOHIDInputValueCallback(void *context, IOReturn result, void *sender, IOHIDValueRef hidValue);
static void Handle_DeviceMatchingCallback(void *context, IOReturn result, void *sender, IOHIDDeviceRef hidDevice);
static void Handle_RemovalCallback(void *context, IOReturn result, void *sender, IOHIDDeviceRef hidDevice);


@implementation OOLeopardHIDJoystickHandler

- (id) init
{
    if ((self = [super init]))
    {
        [self setNumSticks:0];
		[self setViewAxisX:(CGFloat)STICK_AXISUNASSIGNED];
		[self setViewAxisY:(CGFloat)STICK_AXISUNASSIGNED];
		
		OOLog(@"temp.joystick", @"Joystick handler loaded (%p).");
		
		IOHIDManagerRef tIOHIDManagerRef = IOHIDManagerCreate(kCFAllocatorDefault, kIOHIDOptionsTypeNone);
		NSDictionary *gamepadDict = hu_CreateDeviceMatchingDictionary(kHIDPage_GenericDesktop, kHIDUsage_GD_GamePad);
		NSDictionary *joystickDict = hu_CreateDeviceMatchingDictionary(kHIDPage_GenericDesktop, kHIDUsage_GD_Joystick);
		NSArray *matchingArray = [NSArray arrayWithObjects:gamepadDict, joystickDict, nil];
		IOHIDManagerSetDeviceMatchingMultiple(tIOHIDManagerRef, (CFArrayRef)matchingArray);
		
		IOHIDManagerRegisterDeviceMatchingCallback(tIOHIDManagerRef, Handle_DeviceMatchingCallback, self);
		IOHIDManagerRegisterDeviceRemovalCallback(tIOHIDManagerRef, Handle_RemovalCallback, &self);
		IOHIDManagerScheduleWithRunLoop(tIOHIDManagerRef, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
    }
    return self;
}


- (void) dealloc
{
	OOLog(@"temp.joystick", @"Singleton joystickhandler died! That can't be good.");
	return;
	[super dealloc];
}


- (OOUInteger) getNumSticks
{
	return _numSticks;
}


- (void) setNumSticks:(OOUInteger)sticks
{
	_numSticks = sticks;
}


- (NSPoint) getRollPitchAxis
{
	return _rollPitchAxis;
}

- (void) setRollAxis:(CGFloat)roll
{
	_rollPitchAxis.x = roll;
}

- (void) setPitchAxis:(CGFloat)pitch
{
	_rollPitchAxis.y = pitch;
}


- (NSPoint) getViewAxis
{
	return _viewAxis;
}

- (void) setViewAxisX:(CGFloat)x
{
	_viewAxis.x = x;
}

- (void) setViewAxisY:(CGFloat)y
{
	_viewAxis.y = y;
}

- (double) getYawAxis
{
	return _yawAxis;
}

- (void) setYawAxis:(double)yaw
{
	_yawAxis = yaw;
}


- (double) getAxisState:(OOJoystickAxisFunction)function
{
	switch (function)
	{
		case AXIS_THRUST:
			return STICK_AXISUNASSIGNED;
			break;
		case AXIS_YAW:
			return _yawAxis;
			break;
		default:
			break;
	}
	return 0.0;
}


- (double) getSensitivity
{
	return 1.0;
}


- (void) handleHIDInputValueCallbackWithResult:(IOReturn)result sender:(void *)sender value:(IOHIDValueRef)hidValue
{
	IOHIDElementRef elementRef = IOHIDValueGetElement(hidValue);
	IOHIDDeviceRef deviceRef = IOHIDElementGetDevice(elementRef);
	CFArrayRef elements = IOHIDDeviceCopyMatchingElements(deviceRef, NULL, kIOHIDOptionsTypeNone);
	
	CFIndex i, count = CFArrayGetCount(elements);
	for (i = 0; i < count; i++)
	{
		IOHIDElementRef e = (IOHIDElementRef)CFArrayGetValueAtIndex(elements, i);
		uint32_t myCookie = (uint32_t)IOHIDElementGetCookie(e);
		IOHIDValueRef valueRef = NULL;
		IOHIDDeviceGetValue(deviceRef, e, &valueRef);
		
		if (valueRef != NULL)
		{
			CFIndex v = IOHIDValueGetIntegerValue(valueRef);
			OOJoystickButtonFunction button = BUTTON_end;
			
			// FIXME: hard-coded assignments and sensitivities for Xbox 360 controller.
			switch (myCookie)
			{
				case 10:
					button = BUTTON_VIEWFORWARD;
					break;
				case 11:
					button = BUTTON_VIEWAFT;
					break;
				case 12:
					button = BUTTON_VIEWPORT;
					break;
				case 13:
					button = BUTTON_VIEWSTARBOARD;
					break;
				case 14:
					button = BUTTON_CYCLEMISSILE;
					break;
				case 15:
					button = BUTTON_ESCAPE;
					break;
				case 16: //left joystick button
					break;
				case 17: //right joystick button
					break;
				case 18:
					button = BUTTON_DECTHRUST;
					break;
				case 19:
					button = BUTTON_INCTHRUST;
					break;
				case 20:
					button = BUTTON_ENERGYBOMB;
					break;
				case 21:
					button = BUTTON_ARMMISSILE;
				case 22:
					button = BUTTON_UNARM;
					break;
				case 23:
					button = BUTTON_LAUNCHMISSILE;
					break;
				case 24:
					button = BUTTON_ECM;
					break;
				case 25:
					button = BUTTON_FUELINJECT;
					v = (v > 10);
					break;
				case 26:
					button = BUTTON_FIRE;
					v = (v > 10);
					break;
				case 27:
					[self setRollAxis: (CGFloat)v / (CGFloat)32768];
					break;
				case 28:
					break;
				case 29:
					[self setYawAxis: (CGFloat)v / (CGFloat)32768];
					break;
				case 30:
					[self setPitchAxis: (CGFloat)v / (CGFloat)32768];
					break;
				default:
					;
			}
			
			if (button < BUTTON_end)
			{
				[self setButtonState:v != 0 forButton:button];
			}
		}
	}
	
	CFRelease(elements);
}

@end


static NSDictionary *hu_CreateDeviceMatchingDictionary(UInt32 usagePage, UInt32 usage)
{
	return [NSDictionary dictionaryWithObjectsAndKeys:
			[NSNumber numberWithUnsignedInt:usagePage], @kIOHIDDeviceUsagePageKey,
			[NSNumber numberWithUnsignedInt:usage], @kIOHIDDeviceUsageKey,
			nil];
}


static void Handle_IOHIDInputValueCallback(void *context, IOReturn result, void *sender, IOHIDValueRef hidValue)
{
	OOLeopardHIDJoystickHandler *stickHandler = context;
	[stickHandler handleHIDInputValueCallbackWithResult:result sender:sender value:hidValue];
}


static void Handle_DeviceMatchingCallback(void *context, IOReturn result, void *sender, IOHIDDeviceRef hidDevice)
{
	OOLeopardHIDJoystickHandler *stickHandler = context;
	IOHIDManagerRef hidManager = (IOHIDManagerRef)sender;
	
	IOReturn err = IOHIDManagerOpen(hidManager, kIOHIDOptionsTypeNone);
	if (err != kIOReturnSuccess)
	{
		return;
	}
	
	IOHIDManagerRegisterInputValueCallback(hidManager, Handle_IOHIDInputValueCallback, context);
	[stickHandler setNumSticks:[stickHandler getNumSticks] + 1];
	OOLog(@"temp.joystick", @"Input device attached, numSticks: %d", [stickHandler getNumSticks]);	
}


static void Handle_RemovalCallback(void *context, IOReturn result, void *sender, IOHIDDeviceRef hidDevice)
{
	OOLeopardHIDJoystickHandler *stickHandler = context;
	IOHIDManagerClose((IOHIDManagerRef)sender, kIOHIDOptionsTypeNone);
	
	[stickHandler setNumSticks:[stickHandler getNumSticks] - 1];
    OOLog(@"temp.joystick", @"Input device detached, numSticks: %d", [stickHandler getNumSticks]);
}
