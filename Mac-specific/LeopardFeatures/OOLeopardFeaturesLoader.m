//
//  OOLeopardFeaturesLoader.m
//  LeopardFeatures
//
//  Created by Jens Ayton on 2010-04-02.
//  Copyright 2010 Jens Ayton. All rights reserved.
//

#import "OOLeopardFeaturesLoader.h"
#import "OOLogging.h"
#import "OOLeopardHIDJoystickHandler.h"


@implementation OOLeopardFeaturesLoader

- (id) init
{
	if ([JoystickHandler setStickHandlerClass:[OOLeopardHIDJoystickHandler class]])
	{
		OOLog(@"temp.leopardJoystick", @"Successfully installed Leopard joystick handler.");
	}
	else
	{
		OOLog(@"temp.leopardJoystick.failed", @"Failed to install Leopard joystick handler.");
	}
	
	return [super init];
}

@end
