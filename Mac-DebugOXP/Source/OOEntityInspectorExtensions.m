//
//  OOEntityInspectorExtensions.m
//  DebugOXP
//
//  Created by Jens Ayton on 2008-03-10.
//  Copyright 2008 Jens Ayton. All rights reserved.
//

#import "OOEntityInspectorExtensions.h"
#import "OOConstToString.h"
#import "PlayerEntity.h"
#import "OOEntityInspector.h"


@implementation Entity (OOEntityInspectorExtensions)

// Callable via JS Ship.call("inspect")
- (void) inspect
{
	[OOEntityInspector inspect:self];
}


- (NSString *) inspBasicIdentityLine
{
	OOUniversalID		myID = [self universalID];
	
	if (myID != NO_TARGET)
	{
		return [NSString stringWithFormat:@"%@ ID %u", [self class], myID];
	}
	else
	{
		return [self className];
	}
}


- (NSString *) inspSecondaryIdentityLine
{
	return nil;
}


- (NSString *) inspScanClassLine
{
	return ScanClassToString([self scanClass]);
}


- (NSString *) inspStatusLine
{
	return EntityStatusToString([self status]);
}


- (NSString *) inspPositionLine
{
	Vector v = [self position];
	return [NSString stringWithFormat:@"%.0f, %.0f, %.0f", v.x, v.y, v.z];
}


- (NSString *) inspVelocityLine
{
	Vector v = [self velocity];
	return [NSString stringWithFormat:@"%.1f, %.1f, %.1f (%.1f)", v.x, v.y, v.z, magnitude(v)];
}


- (NSString *) inspOrientationLine
{
	Quaternion q = [self orientation];
	return [NSString stringWithFormat:@"%.3f (%.3f, %.3f, %.3f)", q.w, q.x, q.y, q.z];
}


- (NSString *) inspEnergyLine
{
	return [NSString stringWithFormat:@"%i/%i", (int)[self energy], (int)[self maxEnergy]];
}


- (NSString *) inspTargetLine
{
	return nil;
}

@end


@implementation ShipEntity (OOEntityInspectorExtensions)

- (NSString *) inspSecondaryIdentityLine
{
	return [self displayName];
}


- (NSString *) inspTargetLine
{
	Entity *target = [self primaryTarget];
	if ([target isKindOfClass:[PlayerEntity class]])
	{
		return [NSString stringWithFormat:@"Player"];
	}
	else if ([target isKindOfClass:[ShipEntity class]])
	{
		return [NSString stringWithFormat:@"%@ ID %u", [(ShipEntity *)target displayName], [target universalID]];
	}
	else
	{
		return [target shortDescription];
	}
}

@end


@implementation PlayerEntity (OOEntityInspectorExtensions)

- (NSString *) inspSecondaryIdentityLine
{
	return [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"\"%@\", %@", nil, [NSBundle bundleForClass:[self class]], @""), player_name, [self displayName]];
}

@end
