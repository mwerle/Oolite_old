//
//  TestController.h
//  DisplayTest
//
//  Created by Jens Ayton on 2007-12-08.
//  Copyright 2007 Jens Ayton. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class OODisplay;


@interface TestController: NSObject
{
	IBOutlet NSTableView		*displayTable;
	IBOutlet NSTableView		*modeTable;
	
	OODisplay					*_selection;
}
@end
