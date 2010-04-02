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
	[JoystickHandler setStickHandlerClass:[OOLeopardHIDJoystickHandler class]];
	
	return [super init];
}

@end
