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
#include <jsapi.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>

#include "Universe.h"
#include "GameController.h"
#include "PlayerEntity.h"

JSClass global_class = {
	"Oolite",0,
	JS_PropertyStub,JS_PropertyStub,JS_PropertyStub,JS_PropertyStub,
	JS_EnumerateStub,JS_ResolveStub,JS_ConvertStub,JS_FinalizeStub
};

JSVersion version;
JSRuntime *rt;
JSContext *cx;
JSObject *glob;
JSBool builtins;

Universe *scriptedUniverse;

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

JSBool PlayerEntityGetProperty(JSContext *cx, JSObject *obj, jsval id, jsval *vp);

JSClass PlayerEntity_class = {
	"PlayerEntity", JSCLASS_HAS_PRIVATE,
	JS_PropertyStub,JS_PropertyStub,PlayerEntityGetProperty,JS_PropertyStub,
	JS_EnumerateStub,JS_ResolveStub,JS_ConvertStub,JS_FinalizeStub
};

enum playerEntity_propertyIds {
	PE_SHIP_DESCRIPTION, PE_COMMANDER_NAME, PE_FORWARD_SHIELD, PE_AFT_SHIELD
};

JSPropertySpec playerEntity_props[] = {
	{ "ShipDescription", PE_SHIP_DESCRIPTION, JSPROP_ENUMERATE },
	{ "CommanderName", PE_COMMANDER_NAME, JSPROP_ENUMERATE },
	{ "ForwardShield", PE_FORWARD_SHIELD, JSPROP_ENUMERATE },
	{ "AftShield", PE_AFT_SHIELD, JSPROP_ENUMERATE },
	{ 0 }
};

JSObject *universeObj, *playerEntityObj;

NSString *JSValToNSString(JSContext *cx, jsval val) {
	JSString *str = JS_ValueToString(cx, val);
	char *chars = JS_GetStringBytes(str);
	return [NSString stringWithCString:chars];
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
		switch (JSVAL_TO_INT(id)) {
			case UNI_PLAYER_ENTITY: {
				JSObject *pe = JS_DefineObject(cx, universeObj, "PlayerEntity", &PlayerEntity_class, 0x00, JSPROP_ENUMERATE | JSPROP_READONLY | JSPROP_PERMANENT);
				if (pe == 0x00) {
					return JS_FALSE;
				}
				JS_DefineProperties(cx, pe, playerEntity_props);

				*vp = OBJECT_TO_JSVAL(pe);
				return JS_TRUE;
			}
		}
	}

	return JS_TRUE;
}

JSBool PlayerEntityGetProperty(JSContext *cx, JSObject *obj, jsval id, jsval *vp) {
	JSBool ok;
	jsdouble *dp;

	//fprintf(stdout, "in PlayerEntity_getProperty\r\n");
	PlayerEntity *playerEntity = (PlayerEntity *)[scriptedUniverse entityZero];

	if (JSVAL_IS_INT(id)) {
		switch (JSVAL_TO_INT(id)) {
			case PE_SHIP_DESCRIPTION:
				{
					NSString *ship_desc = [playerEntity commanderShip_string];
					const char *ship_desc_str = [ship_desc cString];
					//fprintf(stdout, "PlayerEntity.ShipDescription = %s\r\n", ship_desc_str);
					JSString *js_ship_desc = JS_NewStringCopyZ(cx, ship_desc_str);
					*vp = STRING_TO_JSVAL(js_ship_desc);
					break;
				}
			case PE_COMMANDER_NAME:
				{
					NSString *ship_desc = [playerEntity commanderName_string];
					const char *ship_desc_str = [ship_desc cString];
					//fprintf(stdout, "PlayerEntity.CommanderName = %s\r\n", ship_desc_str);
					JSString *js_ship_desc = JS_NewStringCopyZ(cx, ship_desc_str);
					*vp = STRING_TO_JSVAL(js_ship_desc);
					break;
				}
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
		}
	}
	return JS_TRUE;
}

//===========================================================================
// PlayerEntity proxy
//
// This should not be created as an instance - just the class defined and an instance
// returned from Universe.PlayerEntity property.
//===========================================================================

//===========================================================================
// Universe proxy
//===========================================================================


//===========================================================================
// JavaScript engine initialisation and shutdown
//===========================================================================

JSBool xlog(JSContext *cx, JSObject *obj, uintN argc, jsval *argv, jsval *rval) {
	JSString *str;
	str = JS_ValueToString(cx, argv[0]);
	fprintf(stdout, "LOG: %s\r\n", JS_GetStringBytes(str));
	return JS_TRUE;
}

int initialiseJavaScript() {
	int c, i;
	/*set up global JS variables, including global and custom objects */

	/* initialize the JS run time, and return result in rt */
	rt = JS_NewRuntime(8L * 1024L * 1024L);

	/* if rt does not have a value, end the program here */
	if (!rt)
		exit(1); //return 1;

	/* create a context and associate it with the JS run time */
	cx = JS_NewContext(rt, 8192);

	/* if cx does not have a value, end the program here */
	if (cx == NULL)
		exit(1); //return 1;

	/* create the global object here */
	glob = JS_NewObject(cx, &global_class, NULL, NULL);

	/* initialize the built-in JS objects and the global object */
	builtins = JS_InitStandardClasses(cx, glob);

	//JS_DefineFunction(cx, glob, "Log", xlog, 1, 0);

	universeObj = JS_DefineObject(cx, glob, "Universe", &Universe_class, NULL, JSPROP_ENUMERATE);
	JS_DefineProperties(cx, universeObj, Universe_props);
	JS_DefineFunctions(cx, universeObj, Universe_funcs);

	/* These should indicate source location for diagnostics. */
    char filename[] = "TestScript";
    uintN lineno = 142;

    /*
     * The return value comes back here -- if it could be a GC thing, you must
     * add it to the GC's "root set" with JS_AddRoot(cx, &thing) where thing
     * is a JSString *, JSObject *, or jsdouble *, and remove the root before
     * rval goes out of scope, or when rval is no longer needed.
     */
    jsval rval;
    JSBool ok;
	jsdouble d;

 /*
     * Some example source in a C string.  Larger, non-null-terminated buffers
     * can be used, if you pass the buffer length to JS_EvaluateScript.
     */
    char *source = "Universe.Log(\"Commander \" + Universe.PlayerEntity.CommanderName + \" is flying a \" + Universe.PlayerEntity.ShipDescription);";
    ok = JS_EvaluateScript(cx, glob, source, strlen(source), filename, lineno, &rval);
    if (ok) {
		fprintf(stdout, "JS_EvaluateScript worked\r\n");
		/*
        //Should get a number back from the example source.
		
        jsdouble d;
        ok = JS_ValueToNumber(cx, rval, &d);
        if (ok) {
			//NSLog(@"script returned %f", d);
			fprintf(stdout, "script returned %f\r\n", d);
		} else {
			//NSLog(@"JS_ValueToNumber failed");
			fprintf(stdout, "JS_ValueToNumber failed\r\n");
		}
		*/
    } else {
		//NSLog(@"JS_EvaluateScript failed");
		fprintf(stdout, "JS_EvaluateScript failed\r\n");
	}
	return 0;
}

void shutdownJavaScript()
{
	JS_DestroyContext(cx);
	/* Before exiting the application, free the JS run time */
	JS_DestroyRuntime(rt);
}
