//
//  TestController.m
//  DisplayTest
//
//  Created by Jens Ayton on 2007-12-08.
//  Copyright 2007 Jens Ayton. All rights reserved.
//

#import "TestController.h"
#import "OODisplay.h"
#import <ApplicationServices/ApplicationServices.h>
#import <SDL/SDL.h>


#if !OOLITE_SDL
@interface OODisplay (MacSpecific)

- (CGDirectDisplayID) displayID;

@end


@interface OODisplayMode (MacSpecific)

- (NSDictionary *) modeDictionary;

@end
#endif


@interface OODisplay (TestUtilities)

- (OODisplayMode *) largestNonStretchedMode;

@end


@interface OODisplayMode (TestUtilities)

- (NSString *) aspectRatioString;

@end


static unsigned long long GreatestCommonDivisor(unsigned long long a, unsigned long long b);


@implementation TestController

- (void) awakeFromNib
{
	NSNotificationCenter	*nctr = nil;
	
#if OOLITE_SDL
	if ( SDL_Init(SDL_INIT_VIDEO) < 0 ) {
		fprintf(stderr,
				"Couldn't initialize SDL: %s\n", SDL_GetError());
		exit(1);
	}
#endif
	
	nctr = [NSNotificationCenter defaultCenter];
	[nctr addObserver:self selector:@selector(displayAdded:) name:kOODisplayAddedNotification object:nil];
	[nctr addObserver:self selector:@selector(displayRemoved:) name:kOODisplayRemovedNotification object:nil];
	[nctr addObserver:self selector:@selector(displayConfigurationChanged:) name:kOODisplaySettingsChangedNotification object:nil];
	[nctr addObserver:self selector:@selector(displayOrderChanged:) name:kOODisplayOrderChangedNotification object:nil];
}


- (void) displayAdded:(NSNotification *)notification
{
	OODisplay				*display = nil;
	
	display = [notification object];
	NSLog(@"Display %@ added.", display);
	[displayTable deselectAll:nil];
	[displayTable reloadData];
}


- (void) displayRemoved:(NSNotification *)notification
{
	OODisplay				*display = nil;
	
	display = [notification object];
	NSLog(@"Display %@ removed.", display);
	[displayTable deselectAll:nil];
	[displayTable reloadData];
}


- (void) displayConfigurationChanged:(NSNotification *)notification
{
	OODisplay				*display = nil;
	unsigned				selectedRow;
	
	display = [notification object];
	NSLog(@"Display %@ configuration changed.", display);
	if (display == _selection)
	{
		[modeTable reloadData];
		selectedRow = [_selection indexOfCurrentMode];
		if (selectedRow != NSNotFound)
		{
			[modeTable selectRow:selectedRow byExtendingSelection:NO];
			[modeTable scrollRowToVisible:selectedRow];
		}
	}
}


- (void) displayOrderChanged:(NSNotification *)notification
{
	NSLog(@"Display order changed.");
	[displayTable deselectAll:nil];
	[displayTable reloadData];
}


- (NSInteger) numberOfRowsInTableView:(NSTableView *)tableView
{
	if (tableView == displayTable)
	{
		return [[OODisplay allDisplays] count];
	}
	else if (tableView == modeTable)
	{
		return [[_selection modes] count];
	}
	
	return 0;
}


- (id) tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
	OODisplay				*display = nil;
	OODisplayMode			*mode = nil;
	NSString				*colID = nil;
	id						result = nil;
	
	colID = [tableColumn identifier];
	
	if (tableView == displayTable)
	{
		display = [[OODisplay allDisplays] objectAtIndex:row];
		if ([colID isEqual:@"index"])
		{
			result = [NSNumber numberWithInteger:row];
		}
		else if ([colID isEqual:@"name"])
		{
			result = [display name];
		}
	}
	else if (tableView == modeTable)
	{
		mode = [[_selection modes] objectAtIndex:row];
		if ([colID isEqual:@"mode"])
		{
			NSSize dimensions = [mode dimensions];
			result = [NSString stringWithFormat:NSLocalizedString(@"%u x %u", @""), (unsigned)dimensions.width, (unsigned)dimensions.height];
			float refresh = [mode refreshRate];
			if (refresh > 0)
			{
				result = [NSString stringWithFormat:NSLocalizedString(@"%@, %.3g Hz", @""), result, refresh];
			}
		}
		else if ([colID isEqual:@"depth"])
		{
			result = [NSString stringWithFormat:NSLocalizedString(@"%u bits", @""), [mode bitDepth]];
		}
		else if ([colID isEqual:@"misc"])
		{
			NSMutableArray *misc = [NSMutableArray array];
			if ([mode isEqual:[[mode display] currentMode]])  [misc addObject:@"current"];
			if ([mode isStretched])
			{
				[misc addObject:[NSString stringWithFormat:@"stretched (%@)", [mode aspectRatioString]]];
			}
			if ([mode isInterlaced])  [misc addObject:@"interlaced"];
			if ([mode isTV])  [misc addObject:@"TV"];
			if (![mode requiresConfirmation])  [misc addObject:@"safe"];
			if ([mode isOKForWindowedMode])  [misc addObject:@"desktop"];
			if ([mode isOKForFullScreenMode])  [misc addObject:@"full-screen"];
			result = [misc componentsJoinedByString:@", "];
		}
	}
	
	return result;
}


- (void) tableViewSelectionDidChange:(NSNotification *)notification
{
	NSTableView				*tableView = nil;
	NSInteger				selectedRow;
	
	tableView = [notification object];
	selectedRow = [tableView selectedRow];
	
	if ([notification object] == displayTable)
	{
		[_selection release];
		
		if (selectedRow == -1)  _selection = nil;
		else _selection = [[[OODisplay allDisplays] objectAtIndex:selectedRow] retain];
		
		if (_selection != nil)  NSLog(@"Matching dict:\n%@\n", [_selection matchingDictionary]);
		
		[modeTable reloadData];
		
		selectedRow = [_selection indexOfCurrentMode];
		if (selectedRow != NSNotFound)
		{
			[modeTable selectRow:selectedRow byExtendingSelection:NO];
			[modeTable scrollRowToVisible:selectedRow];
		}
	}
	else if ([notification object] == modeTable)
	{
#if !OOLITE_SDL
		if (selectedRow != -1)
		{
			NSLog(@"Mode dict:\n%@\n", [[[_selection modes] objectAtIndex:selectedRow] modeDictionary]);
		}
#endif
	}
}

@end


//	Euclid’s Algorithm
static unsigned long long GreatestCommonDivisor(unsigned long long a, unsigned long long b)
{
	unsigned long long		q, r, swap;
	
	if (a < b)
		// Exchange them so that a > b
	{
		swap = a;
		a = b;
		b = swap;
	}
	
	for (;;)
	{
		q = a / b;
		r = a % b;
		
		if (!r)
		{
			break;
		}
		
		a = b;
		b = r;
	}
	
	return b;
}


@implementation OODisplay (TestUtilities)

- (OODisplayMode *) largestNonStretchedMode
{
	NSEnumerator			*modeEnum = nil;
	OODisplayMode			*mode = nil;
	
	for (modeEnum = [[self modes] reverseObjectEnumerator]; (mode = [modeEnum nextObject]); )
	{
		if (![mode isStretched])  return mode;
	}
	
	return nil;
}

@end


@implementation OODisplayMode (TestUtilities)

- (NSString *) aspectRatioString
{
	OODisplayMode			*largest = nil;
	unsigned long long		nom, den, gcd;
	
	largest = [[self display] largestNonStretchedMode];
	if (largest == nil)  return @"unknown";
	
#if 1
	// Return stretch ratio
	nom = [self height] * [largest width];
	den = [self width] * [largest height];
#else
	// Return pixel aspect ratio assuming square pixel grid
	nom = [self width];
	den = [self height];
#endif	
	gcd = GreatestCommonDivisor(nom, den);
	
	return [NSString stringWithFormat:@"%llu:%llu", nom/gcd, den/gcd];
}

@end
