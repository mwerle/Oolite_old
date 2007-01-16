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

#import "OXPScript.h"

OXPScript *currentOXPScript;

JSClass OXP_class = {
	"OXPScript", JSCLASS_HAS_PRIVATE,
	JS_PropertyStub,JS_PropertyStub,JS_PropertyStub,JS_PropertyStub,
	JS_EnumerateStub,JS_ResolveStub,JS_ConvertStub,JS_FinalizeStub
};

extern NSString *JSValToNSString(JSContext *cx, jsval val);

@implementation OXPScript

- (id) initWithContext: (JSContext *) context andFilename: (NSString *) filename
{
	// Check if file exists before doing anything else
	// ...

	self = [super init];

	obj = JS_NewObject(context, &OXP_class, 0x00, JS_GetGlobalObject(context));
	JS_AddRoot(context, &obj); // note 2nd arg is a pointer-to-pointer

	cx = context;

	jsval rval;
	JSBool ok;
    JSScript *script = JS_CompileFile(context, obj, [filename cString]);
    if (script != 0x00) {
		ok = JS_ExecuteScript(context, obj, script, &rval);
		if (ok) {
			ok = JS_GetProperty(context, obj, "Name", &rval);
			if (ok && JSVAL_IS_STRING(rval)) {
				name = JSValToNSString(context, rval);
			} else {
				// No name given in the script so use the filename
				name = [NSString stringWithString:filename];
			}
			ok = JS_GetProperty(context, obj, "Description", &rval);
			if (ok && JSVAL_IS_STRING(rval)) {
				description = JSValToNSString(context, rval);
			} else {
				description = @"";
			}
			ok = JS_GetProperty(context, obj, "Version", &rval);
			if (ok && JSVAL_IS_STRING(rval)) {
				version = JSValToNSString(context, rval);
			} else {
				version= @"";
			}
			NSLog(@"Loaded JavaScript OXP: %@ %@ %@", name, description, version);

			/*
			 * Example code to read the mission variables.
			 *
			 * So far, this just gets their names. Need to add code to get their values
			 * and convert the whole thing to Obj-C friendly NSArray and types.
			 *
			ok = JS_GetProperty(context, obj, "MissionVars", &rval);
			if (ok && JSVAL_IS_OBJECT(rval)) {
				JSObject *ar = JSVAL_TO_OBJECT(rval);
				JSIdArray *ids = JS_Enumerate(context, ar);
				int i;
				for (i = 0; i < ids->length; i++) {
					if (JS_IdToValue(cx, ids->vector[i], &rval) == JS_TRUE) {
						if (JSVAL_IS_BOOLEAN(rval))	fprintf(stdout, "a boolean\r\n");
						if (JSVAL_IS_DOUBLE(rval))	fprintf(stdout, "a double\r\n");
						if (JSVAL_IS_INT(rval))	fprintf(stdout, "an integer\r\n");
						if (JSVAL_IS_NUMBER(rval))	fprintf(stdout, "a number\r\n");
						if (JSVAL_IS_OBJECT(rval))	fprintf(stdout, "an object\r\n");
						if (JSVAL_IS_STRING(rval)) {
							fprintf(stdout, "%s\r\n", JS_GetStringBytes(JSVAL_TO_STRING(rval)));
						}
					}
				}
				JS_DestroyIdArray(context, ids);
			}
			*/
		}
		JS_DestroyScript(context, script);
	}

	return self;
}

- (NSString *) name
{
	return name;
}

- (NSString *) description
{
	return description;
}

- (NSString *) version
{
	return version;
}

- (BOOL) doEvent: (NSString *) eventName
{
	jsval rval;
	JSBool ok;

	ok = JS_GetProperty(cx, obj, [eventName cString], &rval);
	if (ok && !JSVAL_IS_VOID(rval)) {
		JSFunction *func = JS_ValueToFunction(cx, rval);
		if (func != 0x00) {
			currentOXPScript = self;
			ok = JS_CallFunction(cx, obj, func, 0, 0x00, &rval);
			if (ok)
				return YES;
		}
	}

	return NO;
}

- (BOOL) doEvent: (NSString *) eventName withIntegerArgument:(int)argument
{
	jsval rval;
	JSBool ok;

	ok = JS_GetProperty(cx, obj, [eventName cString], &rval);
	if (ok && !JSVAL_IS_VOID(rval)) {
		JSFunction *func = JS_ValueToFunction(cx, rval);
		if (func != 0x00) {
			currentOXPScript = self;
			jsval args[1];
			args[0] = INT_TO_JSVAL(argument);
			ok = JS_CallFunction(cx, obj, func, 1, args, &rval);
			if (ok)
				return YES;
		}
	}

	return NO;
}

- (BOOL) doEvent: (NSString *) eventName withStringArgument:(NSString *)argument
{
	jsval rval;
	JSBool ok;

	ok = JS_GetProperty(cx, obj, [eventName cString], &rval);
	if (ok && !JSVAL_IS_VOID(rval)) {
		JSFunction *func = JS_ValueToFunction(cx, rval);
		if (func != 0x00) {
			currentOXPScript = self;
			ok = JS_CallFunction(cx, obj, func, 0, 0x00, &rval);
			if (ok)
				return YES;
		}
	}

	return NO;
}

@end
