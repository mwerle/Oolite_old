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

/*
 * This file contains the core JavaSCript interfacing code.
 */

#import "ScriptEngine.h"
#import "OXPScript.h"

#include <stdio.h>
#include <string.h>
//#include <stdlib.h>

Universe *scriptedUniverse;
JSObject *xglob, *universeObj;

JSBool GlobalGetProperty(JSContext *cx, JSObject *obj, jsval id, jsval *vp);

JSClass global_class = {
	"Oolite",0,
	JS_PropertyStub,JS_PropertyStub,JS_PropertyStub,JS_PropertyStub,
	JS_EnumerateStub,JS_ResolveStub,JS_ConvertStub,JS_FinalizeStub
};

enum global_propertyIds {
	GLOBAL_GALAXY_NUMBER, GLOBAL_PLANET_NUMBER, GLOBAL_DOCKED_AT_MAIN_STATION, GLOBAL_DOCKED_STATION_NAME, GLOBAL_MISSION_VARS
};

JSPropertySpec Global_props[] = {
	{ "GalaxyNumber", GLOBAL_GALAXY_NUMBER, JSPROP_ENUMERATE, GlobalGetProperty },
	{ "PlanetNumber", GLOBAL_PLANET_NUMBER, JSPROP_ENUMERATE, GlobalGetProperty },
	{ "DockedAtMainStation", GLOBAL_DOCKED_AT_MAIN_STATION, JSPROP_ENUMERATE, GlobalGetProperty },
	{ "StationName", GLOBAL_DOCKED_STATION_NAME, JSPROP_ENUMERATE, GlobalGetProperty },
	{ "MissionVars", GLOBAL_MISSION_VARS, JSPROP_ENUMERATE, GlobalGetProperty },
	{ 0 }
};


void runScripts(NSString* event);

//===========================================================================
// Universe proxy
//===========================================================================

JSBool UniverseGetProperty(JSContext *cx, JSObject *obj, jsval id, jsval *vp);

JSClass Universe_class = {
	"Universe", JSCLASS_HAS_PRIVATE,
	JS_PropertyStub,JS_PropertyStub,UniverseGetProperty,JS_PropertyStub,
	JS_EnumerateStub,JS_ResolveStub,JS_ConvertStub,JS_FinalizeStub
};

enum universe_propertyIds {
	UNI_PLAYER_ENTITY
};

JSPropertySpec Universe_props[] = {
	{ "PlayerEntity", UNI_PLAYER_ENTITY, JSPROP_ENUMERATE },
	{ 0 }
};

JSBool UniverseLog(JSContext *cx, JSObject *obj, uintN argc, jsval *argv, jsval *rval);
JSBool UniverseAddMessage(JSContext *cx, JSObject *obj, uintN argc, jsval *argv, jsval *rval);
JSBool UniverseAddCommsMessage(JSContext *cx, JSObject *obj, uintN argc, jsval *argv, jsval *rval);

JSFunctionSpec Universe_funcs[] = {
	{ "AddMessage", UniverseAddMessage, 2, 0 },
	{ "AddCommsMessage", UniverseAddMessage, 2, 0 },
	{ "Log", UniverseLog, 1, 0 },
	{ 0 }
};

//===========================================================================
// PlayerEntity proxy
//===========================================================================

JSBool PlayerEntityGetProperty(JSContext *cx, JSObject *obj, jsval id, jsval *vp);

JSClass PlayerEntity_class = {
	"PlayerEntity", JSCLASS_HAS_PRIVATE,
	JS_PropertyStub,JS_PropertyStub,PlayerEntityGetProperty,JS_PropertyStub,
	JS_EnumerateStub,JS_ResolveStub,JS_ConvertStub,JS_FinalizeStub
};

enum playerEntity_propertyIds {
	PE_SHIP_DESCRIPTION, PE_COMMANDER_NAME, PE_SCORE, PE_CREDITS, PE_LEGAL_STATUS
};

JSPropertySpec playerEntity_props[] = {
	{ "ShipDescription", PE_SHIP_DESCRIPTION, JSPROP_ENUMERATE },
	{ "CommanderName", PE_COMMANDER_NAME, JSPROP_ENUMERATE },
	{ "Score", PE_SCORE, JSPROP_ENUMERATE },
	{ "Credits", PE_CREDITS, JSPROP_ENUMERATE },
	{ "LegalStatus", PE_LEGAL_STATUS, JSPROP_ENUMERATE },
	{ 0 }
};

NSString *JSValToNSString(JSContext *cx, jsval val) {
	JSString *str = JS_ValueToString(cx, val);
	char *chars = JS_GetStringBytes(str);
	return [NSString stringWithCString:chars];
}

JSBool GlobalGetProperty(JSContext *cx, JSObject *obj, jsval id, jsval *vp) {
	if (JSVAL_IS_INT(id)) {
		PlayerEntity *playerEntity = (PlayerEntity *)[scriptedUniverse entityZero];

		switch (JSVAL_TO_INT(id)) {
			case GLOBAL_GALAXY_NUMBER: {
				NSNumber *gn = [playerEntity galaxy_number];
				*vp = INT_TO_JSVAL([gn intValue]);
				break;
			}

			case GLOBAL_PLANET_NUMBER: {
				*vp = INT_TO_JSVAL([[playerEntity planet_number] intValue]);
				break;
			}

			case GLOBAL_DOCKED_AT_MAIN_STATION: {
				BOOL b = [[playerEntity dockedAtMainStation_bool] isEqualToString:@"YES"];
				if (b == YES)
					*vp = BOOLEAN_TO_JSVAL(1);
				else
					*vp = BOOLEAN_TO_JSVAL(0);
				break;
			}

			case GLOBAL_DOCKED_STATION_NAME: {
				NSString *name = [playerEntity dockedStationName_string];
				const char *name_str = [name cString];
				JSString *js_name = JS_NewStringCopyZ(cx, name_str);
				*vp = STRING_TO_JSVAL(js_name);
				break;
			}

			case GLOBAL_MISSION_VARS: {
				fprintf(stdout, "Creating MissionVars array\r\n");
				JSObject *mv = JS_DefineObject(cx, xglob, "MissionVars", &global_class, 0x00, JSPROP_ENUMERATE | JSPROP_READONLY | JSPROP_PERMANENT);
				*vp = OBJECT_TO_JSVAL(mv);
				break;
			}
		}
	}

	return JS_TRUE;
}

JSBool UniverseLog(JSContext *cx, JSObject *obj, uintN argc, jsval *argv, jsval *rval) {
	JSString *str;
	str = JS_ValueToString(cx, argv[0]);
	fprintf(stdout, "LOG: %s\r\n", JS_GetStringBytes(str));
	return JS_TRUE;
}

JSBool UniverseAddMessage(JSContext *cx, JSObject *obj, uintN argc, jsval *argv, jsval *rval) {
	JSBool ok;
	int32 count;
	if (argc != 2)
		return JS_FALSE;

	ok = JS_ValueToInt32(cx, argv[1], &count);
	NSString *str = JSValToNSString(cx, argv[0]);
	[scriptedUniverse addMessage: str forCount:(int)count];
	[str dealloc];
	return JS_TRUE;
}

JSBool UniverseAddCommsMessage(JSContext *cx, JSObject *obj, uintN argc, jsval *argv, jsval *rval) {
	JSBool ok;
	int32 count;
	if (argc != 2)
		return JS_FALSE;

	ok = JS_ValueToInt32(cx, argv[1], &count);
	NSString *str = JSValToNSString(cx, argv[0]);
	[scriptedUniverse addCommsMessage: str forCount:(int)count];
	[str dealloc];
	return JS_TRUE;
}

JSBool UniverseGetProperty(JSContext *cx, JSObject *obj, jsval id, jsval *vp) {
	if (JSVAL_IS_INT(id)) {
		PlayerEntity *playerEntity = (PlayerEntity *)[scriptedUniverse entityZero];

		switch (JSVAL_TO_INT(id)) {
			case UNI_PLAYER_ENTITY: {
				JSObject *pe = JS_DefineObject(cx, universeObj, "PlayerEntity", &PlayerEntity_class, 0x00, JSPROP_ENUMERATE | JSPROP_READONLY | JSPROP_PERMANENT);
				if (pe == 0x00) {
					return JS_FALSE;
				}
				JS_DefineProperties(cx, pe, playerEntity_props);

				*vp = OBJECT_TO_JSVAL(pe);
				break;
			}
		}
	}

	return JS_TRUE;
}

JSBool PlayerEntityGetProperty(JSContext *cx, JSObject *obj, jsval id, jsval *vp) {
	JSBool ok;
	jsdouble *dp;

	PlayerEntity *playerEntity = (PlayerEntity *)[scriptedUniverse entityZero];

	if (JSVAL_IS_INT(id)) {
		switch (JSVAL_TO_INT(id)) {
			case PE_SHIP_DESCRIPTION:
				{
					NSString *ship_desc = [playerEntity commanderShip_string];
					const char *ship_desc_str = [ship_desc cString];
					JSString *js_ship_desc = JS_NewStringCopyZ(cx, ship_desc_str);
					*vp = STRING_TO_JSVAL(js_ship_desc);
					break;
				}
			case PE_COMMANDER_NAME:
				{
					NSString *ship_desc = [playerEntity commanderName_string];
					const char *ship_desc_str = [ship_desc cString];
					JSString *js_ship_desc = JS_NewStringCopyZ(cx, ship_desc_str);
					*vp = STRING_TO_JSVAL(js_ship_desc);
					break;
				}
/*
			case PE_FORWARD_SHIELD:
				{
					double fs = (double)[playerEntity dial_forward_shield];
					dp = JS_NewDouble(cx, fs);
					ok = (dp != 0x00);
					if (ok)
						*vp = DOUBLE_TO_JSVAL(dp);
					break;
				}
			case PE_AFT_SHIELD:
				{
					double fs = (double)[playerEntity dial_aft_shield];
					dp = JS_NewDouble(cx, fs);
					ok = (dp != 0x00);
					if (ok)
						*vp = DOUBLE_TO_JSVAL(dp);
					break;
				}
*/
		}
	}
	return JS_TRUE;
}


@implementation ScriptEngine

//===========================================================================
// JavaScript engine initialisation and shutdown
//===========================================================================

- (id) initWithUniverse: (Universe *)universe
{
	self = [super init];
	scriptedUniverse = universe;

	/*set up global JS variables, including global and custom objects */

	/* initialize the JS run time, and return result in rt */
	rt = JS_NewRuntime(8L * 1024L * 1024L);

	/* if rt does not have a value, end the program here */
	if (!rt) {
		[super dealloc];
		exit(1); //return nil;
	}

	/* create a context and associate it with the JS run time */
	cx = JS_NewContext(rt, 8192);

	/* if cx does not have a value, end the program here */
	if (cx == NULL) {
		[super dealloc];
		exit(1); //return nil;
	}

	/* create the global object here */
	glob = JS_NewObject(cx, &global_class, NULL, NULL);
	xglob = glob;

	/* initialize the built-in JS objects and the global object */
	builtins = JS_InitStandardClasses(cx, glob);

	JS_DefineProperties(cx, glob, Global_props);
	
	universeObj = JS_DefineObject(cx, glob, "Universe", &Universe_class, NULL, JSPROP_ENUMERATE);
	JS_DefineProperties(cx, universeObj, Universe_props);
	JS_DefineFunctions(cx, universeObj, Universe_funcs);

	oxps = [[NSMutableArray arrayWithCapacity:10] retain];

	OXPScript *scr = [[[OXPScript alloc] initWithContext:cx andFilename:@"testoxp.js"] retain];
	[oxps addObject: scr];
	//scr = [[OXPScript alloc] initWithContext:cx andFilename:@"otheroxp.js"];
	//[oxps addObject: scr];

	return self;
}

- (void) dealloc
{
	// free up the OXPScripts too!

	JS_DestroyContext(cx);
	/* Before exiting the application, free the JS run time */
	JS_DestroyRuntime(rt);
	[super dealloc];
}

/*
 * This function runs all functions associated with the named event (eg exitingWitchspace).
 */
- (void) doEvent: (NSString *) event
{
	int i;
	int c = [oxps count];
	for (i = 0; i < c; i++) {
		OXPScript *scr = (OXPScript *)[oxps objectAtIndex: i];
		[scr doEvent: event];
	}
}

@end
