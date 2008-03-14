//
//  OOAIDebugInspectorModule.m
//  DebugOXP
//
//  Created by Jens Ayton on 2008-03-14.
//  Copyright 2008 Jens Ayton. All rights reserved.
//

#import "OOAIDebugInspectorModule.h"
#import "AI.h"
#import "OOInstinct.h"
#import "Universe.h"
#import "OOEntityInspectorExtensions.h"


@implementation OOAIDebugInspectorModule

- (void) update
{
	AI					*object = [self object];
	NSString			*placeholder = InspectorUnknownValueString();
	
	[_stateMachineNameField setStringValue:[object name] ?: placeholder];
	[_stateField setStringValue:[object state] ?: placeholder];
	if (object != nil)
	{
		[_stackDepthField setIntValue:[object stackDepth]];
		[_timeToThinkField setStringValue:[NSString stringWithFormat:@"%.1f", [object nextThinkTime] - [UNIVERSE getTime]]];
	}
	else
	{
		[_stackDepthField setStringValue:placeholder];
		[_timeToThinkField setStringValue:placeholder];
	}
	[_instinctField setStringValue:[[object rulingInstinct] shortDescription] ?: placeholder];
}


- (IBAction) thinkNow:sender
{
	[[self object] setNextThinkTime:[UNIVERSE getTime]];
}

@end


@implementation AI (OOAIDebugInspectorModule)

- (NSString *) inspBasicIdentityLine
{
	if ([self owner] != nil)  return [NSString stringWithFormat:@"AI for %@", [[self owner] inspBasicIdentityLine]];
	return  [super inspBasicIdentityLine];
}


- (NSArray *) debugInspectorModules
{
	return [[super debugInspectorModules] arrayByAddingInspectorModuleOfClass:[OOAIDebugInspectorModule class]
																	forObject:(id)self];
}

@end
