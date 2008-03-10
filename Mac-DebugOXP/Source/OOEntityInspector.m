//
//  OOEntityInspector.m
//  DebugOXP
//
//  Created by Jens Ayton on 2008-03-10.
//  Copyright 2008 Jens Ayton. All rights reserved.
//

#import "OOEntityInspector.h"
#import "Entity.h"
#import "ShipEntity.h"
#import "OOEntityInspectorExtensions.h"


static NSMutableDictionary		*sActiveInspectors = nil;


@interface OOEntityInspector (Private)

- (id) initWithEntity:(Entity *)entity;

- (Entity *) entity;

- (void) update;

@end


@implementation OOEntityInspector

+ (id) inspectorForEntity:(Entity *)entity
{
	OOEntityInspector		*inspector = nil;
	NSValue					*key = nil;
	
	// Look for existing inspector
	key = [NSValue valueWithNonretainedObject:entity];
	inspector = [sActiveInspectors objectForKey:key];
	if (inspector != nil)
	{
		if ([inspector entity] == entity)  return inspector;
		else
		{
			// Existing inspector is for an old object that used to be at the same address.
			[sActiveInspectors removeObjectForKey:key];
		}
	}
	
	// No existing inspector; create one.
	inspector = [[[self alloc] initWithEntity:entity] autorelease];
	
	return inspector;
}


+ (void) inspect:(Entity *)entity
{
	if (entity != nil)  [[self inspectorForEntity:entity] bringToFront];
}


- (void) dealloc
{
	[_timer invalidate];
	_timer = nil;
	_panel = nil;
	[_entity release];
	_entity = nil;
	[sActiveInspectors removeObjectForKey:_key];
	[_key release];
	_key = nil;
	[_panel close];
	
	[super dealloc];
}


- (void) bringToFront
{
	[_panel orderFront:nil];
}


- (IBAction) inspectTarget:sender
{
	if ([[self entity] respondsToSelector:@selector(primaryTarget)])
	{
		[OOEntityInspector inspect:[(id)[self entity] primaryTarget]];
	}
}

@end


@implementation OOEntityInspector (Private)

- (id) initWithEntity:(Entity *)entity
{
	if ((self = [super init]))
	{
		_key = [[NSValue valueWithNonretainedObject:entity] retain];
		_entity = [entity weakRetain];
		
		[NSBundle loadNibNamed:@"OODebugInspector" owner:self];
		[self update];
		_timer = [NSTimer scheduledTimerWithTimeInterval:0.1
												  target:self
												selector:@selector(updateTick:)
												userInfo:nil
												 repeats:YES];
		
		if (![[self entity] respondsToSelector:@selector(primaryTarget)])
		{
			[_inspectTargetButton setEnabled:NO];
		}
		
		if (sActiveInspectors == nil)  sActiveInspectors = [[NSMutableDictionary alloc] init];
		[sActiveInspectors setObject:self forKey:_key];
	}
	
	return self;
}


- (Entity *) entity
{
	if (_entity != nil)
	{
		Entity *result = [_entity weakRefUnderlyingObject];
		if (result == nil)
		{
			[_entity release];
			_entity = nil;
		}
		return result;
	}
	else
	{
		return nil;
	}
}


- (void) update
{
	Entity *entity = [self entity];
	static NSString *placeholder = nil;
	if (placeholder == nil)  placeholder = [NSLocalizedStringFromTableInBundle(@"--", nil, [NSBundle bundleForClass:[self class]], @"") retain];
	
	if (entity == nil)
	{
		[_secondaryIdentityField setStringValue:@"Dead"];
		[_energyIndicator setDoubleValue:0.0];
		[_timer invalidate];
		_timer = nil;
	}
	else
	{
		[_basicIdentityField setStringValue:[entity inspBasicIdentityLine] ?: placeholder];
		[_secondaryIdentityField setStringValue:[entity inspSecondaryIdentityLine] ?: placeholder];
		[_energyIndicator setDoubleValue:[entity energy] / [entity maxEnergy] * 100.0];
	}
	
	[_scanClassField setStringValue:[entity inspScanClassLine] ?: placeholder];
	[_statusField setStringValue:[entity inspStatusLine] ?: placeholder];
	[_positionField setStringValue:[entity inspPositionLine] ?: placeholder];
	[_velocityField setStringValue:[entity inspVelocityLine] ?: placeholder];
	[_orientationField setStringValue:[entity inspOrientationLine] ?: placeholder];
	[_energyField setStringValue:[entity inspEnergyLine] ?: placeholder];
	[_targetField setStringValue:[entity inspTargetLine] ?: placeholder];
}


- (void) updateTick:(NSTimer *)timer
{
	if ([_panel isVisible])  [self update];
}


- (void)windowWillClose:(NSNotification *)notification
{
	_panel = nil;
	NSValue *key = _key;
	_key = nil;
	[sActiveInspectors removeObjectForKey:key];
	[key release];
}

@end
