//
//  OOEntityInspector.h
//  DebugOXP
//
//  Created by Jens Ayton on 2008-03-10.
//  Copyright 2008 Jens Ayton. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class OOWeakReference, Entity;


@interface OOEntityInspector: NSObject
{
	OOWeakReference				*_entity;
	IBOutlet NSPanel			*_panel;
	NSTimer						*_timer;
	NSValue						*_key;
	
	IBOutlet NSTextField		*_basicIdentityField;
	IBOutlet NSTextField		*_secondaryIdentityField;
	IBOutlet NSTextField		*_scanClassField;
	IBOutlet NSTextField		*_statusField;
	IBOutlet NSTextField		*_positionField;
	IBOutlet NSTextField		*_velocityField;
	IBOutlet NSTextField		*_orientationField;
	IBOutlet NSTextField		*_energyField;
	IBOutlet NSLevelIndicator	*_energyIndicator;
	IBOutlet NSTextField		*_targetField;
	IBOutlet NSButton			*_inspectTargetButton;
}

+ (id) inspectorForEntity:(Entity *)entity;
- (void) bringToFront;

+ (void) inspect:(Entity *)entity;

- (IBAction) inspectTarget:sender;

@end
