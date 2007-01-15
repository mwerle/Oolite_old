/*
 *
 *  Oolite
 *
 *  Created by Giles Williams on Sat Apr 03 2004.
 *  Copyright (c) 2004 for aegidian.org. All rights reserved.
 *

This file copyright (c) 2007, David Taylor
All rights reserved.

This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike License.
To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/2.0/
or send a letter to Creative Commons, 559 Nathan Abbott Way, Stanford, California 94305, USA.

You are free:

•	to copy, distribute, display, and perform the work
•	to make derivative works

Under the following conditions:

•	Attribution. You must give the original author credit.
•	Noncommercial. You may not use this work for commercial purposes.
•	Share Alike. If you alter, transform, or build upon this work,
you may distribute the resulting work only under a license identical to this one.

For any reuse or distribution, you must make clear to others the license terms of this work.

Any of these conditions can be waived if you get permission from the copyright holder.

Your fair use and other rights are in no way affected by the above.
*/

#ifndef OXPSCRIPT_H_SEEN
#define OXPSCRIPT_H_SEEN

#include <Foundation/Foundation.h>
#include <jsapi.h>

@interface OXPScript : NSObject
{
	JSContext *cx;
	JSObject *obj;

	NSString *name;
	NSString *description;
	NSString *version;
}

- (id) initWithContext: (JSContext *) context andFilename: (NSString *) filename;

- (NSString *) name;
- (NSString *) description;
- (NSString *) version;

- (BOOL) doEvent: (NSString *) eventName;
- (BOOL) doEvent: (NSString *) eventName withIntegerArgument:(int)argument;
- (BOOL) doEvent: (NSString *) eventName withStringArgument:(NSString *)argument;

@end

#endif
