//
//  OOEntityInspectorExtensions.h
//  DebugOXP
//
//  Created by Jens Ayton on 2008-03-10.
//  Copyright 2008 Jens Ayton. All rights reserved.
//

#import "Entity.h"


@interface Entity (OOEntityInspectorExtensions)

- (NSString *) inspBasicIdentityLine;
- (NSString *) inspSecondaryIdentityLine;
- (NSString *) inspScanClassLine;
- (NSString *) inspStatusLine;
- (NSString *) inspPositionLine;
- (NSString *) inspVelocityLine;
- (NSString *) inspOrientationLine;
- (NSString *) inspEnergyLine;
- (NSString *) inspTargetLine;

@end
