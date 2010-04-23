/*

OOJSOolite.h

JavaScript proxy for Oolite (for version checking and similar).


Oolite
Copyright (C) 2004-2008 Giles C Williams and contributors

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
MA 02110-1301, USA.

*/

#import "OOJSOolite.h"
#import "OOJavaScriptEngine.h"
#import "OOStringParsing.h"
#import "OOTexture.h"
#import "GuiDisplayGen.h"
#import "OOJSPlayer.h"


static JSBool OoliteGetProperty(JSContext *context, JSObject *this, jsval name, jsval *outValue);

static NSString *VersionString(void);
static NSArray *VersionComponents(void);

static JSBool OoliteCompareVersion(JSContext *context, JSObject *this, uintN argc, jsval *argv, jsval *outResult);
static JSBool OoliteScreenBackground(JSContext *context, JSObject *this, uintN argc, jsval *argv, jsval *outResult);
static JSBool OoliteScreenOverlay(JSContext *context, JSObject *this, uintN argc, jsval *argv, jsval *outResult);


static JSClass sOoliteClass =
{
	"Oolite",
	0,
	
	JS_PropertyStub,
	JS_PropertyStub,
	OoliteGetProperty,
	JS_PropertyStub,
	JS_EnumerateStub,
	JS_ResolveStub,
	JS_ConvertStub,
	JS_FinalizeStub
};


enum
{
	// Property IDs
	kOolite_version,			// version number components, array, read-only
	kOolite_versionString,		// version number as string, string, read-only
	kOolite_jsVersion,			// JavaScript version, integer, read-only
	kOolite_jsVersionString,	// JavaScript version as string, string, read-only
	kOolite_gameSettings,		// Various game settings, object, read-only
};


static JSPropertySpec sOoliteProperties[] =
{
	// JS name						ID							flags
	{ "version",				kOolite_version,			JSPROP_PERMANENT | JSPROP_ENUMERATE | JSPROP_READONLY },
	{ "versionString",			kOolite_versionString,		JSPROP_PERMANENT | JSPROP_ENUMERATE | JSPROP_READONLY },
	{ "jsVersion",				kOolite_jsVersion,			JSPROP_PERMANENT | JSPROP_ENUMERATE | JSPROP_READONLY },
	{ "jsVersionString",		kOolite_jsVersionString,	JSPROP_PERMANENT | JSPROP_ENUMERATE | JSPROP_READONLY },
	{ "gameSettings",			kOolite_gameSettings,		JSPROP_PERMANENT | JSPROP_ENUMERATE | JSPROP_READONLY },
	{ 0 }
};


static JSFunctionSpec sOoliteMethods[] =
{
	// JS name						Function					min args
	{ "compareVersion",			OoliteCompareVersion,		1 },
	{ "setScreenBackground",	OoliteScreenBackground,		1 },
	{ "setScreenOverlay",		OoliteScreenOverlay, 1 },
	{ 0 }
};


void InitOOJSOolite(JSContext *context, JSObject *global)
{
	JSObject *oolitePrototype = JS_InitClass(context, global, NULL, &sOoliteClass, NULL, 0, sOoliteProperties, sOoliteMethods, NULL, NULL);
	JS_DefineObject(context, global, "oolite", &sOoliteClass, oolitePrototype, JSPROP_ENUMERATE | JSPROP_READONLY | JSPROP_PERMANENT);
}


static JSBool OoliteGetProperty(JSContext *context, JSObject *this, jsval name, jsval *outValue)
{
	id						result = nil;
	
	if (!JSVAL_IS_INT(name))  return YES;
	
	switch (JSVAL_TO_INT(name))
	{
		case kOolite_version:
			result = VersionComponents();
			if (result == nil)  result = [NSNull null];
			break;
		
		case kOolite_versionString:
			result = VersionString();
			if (result == nil)  result = [NSNull null];
			break;
		
		case kOolite_jsVersion:
			*outValue = INT_TO_JSVAL(JS_GetVersion(context));
			break;
		
		case kOolite_jsVersionString:
			*outValue = STRING_TO_JSVAL(JS_NewStringCopyZ(context, JS_VersionToString(JS_GetVersion(context))));
			break;
		
		case kOolite_gameSettings:
			result = [UNIVERSE gameSettings];
			if (result == nil)  result = [NSNull null];
			break;
		
		default:
			OOReportJSBadPropertySelector(context, @"Oolite", JSVAL_TO_INT(name));
			return NO;
	}
	
	if (result != nil)  *outValue = [result javaScriptValueInContext:context];
	return YES;
}


static NSString *VersionString(void)
{
	return [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
}


static NSArray *VersionComponents(void)
{
	return ComponentsFromVersionString(VersionString());
}


/*	oolite.compareVersion(versionSpec) : Number
	returns -1 if the current version of Oolite is less than versionSpec, 0 if
	they are equal, and 1 if the current version is newer. versionSpec may be
	a string or an array. Example:
	if (0 < oolite.compareVersion("1.70"))  log("Old version of Oolite!")
	else  this.doStuffThatRequires170()
*/
static JSBool OoliteCompareVersion(JSContext *context, JSObject *this, uintN argc, jsval *argv, jsval *outResult)
{
	id						components = nil;
	NSEnumerator			*componentEnum = nil;
	id						component = nil;
	
	components = JSValueToObject(context, argv[0]);
	if ([components isKindOfClass:[NSArray class]])
	{
		// Require each element to be a number
		for (componentEnum = [components objectEnumerator]; (component = [componentEnum nextObject]); )
		{
			if (![component isKindOfClass:[NSNumber class]])
			{
				components = nil;
				break;
			}
		}
	}
	else if ([components isKindOfClass:[NSString class]])
	{
		components = ComponentsFromVersionString(components);
	}
	else  components = nil;
	
	if (components != nil)
	{
		*outResult = INT_TO_JSVAL(CompareVersions(components, VersionComponents()));
	}
	// Else leave as JSVAL_VOID
	
	return YES;
}


static JSBool OoliteScreenBackground(JSContext *context, JSObject *this, uintN argc, jsval *argv, jsval *outResult)
{
	*outResult = JSVAL_FALSE;
	NSString 		*value = JSValToNSString(context, argv[0]);
	PlayerEntity	*player = OOPlayerForScripting();
	
	if ([UNIVERSE viewDirection] == VIEW_GUI_DISPLAY)
	{
		*outResult = BOOLEAN_TO_JSVAL([[UNIVERSE gui] setBackgroundTexture:[OOTexture textureWithName:value inFolder:@"Images"]]);
		// add some permanence to the override if we're in the equip ship screen
		if (*outResult == JSVAL_TRUE && [player guiScreen] == GUI_SCREEN_EQUIP_SHIP) [player setTempBackground:value];
	}
	
	return YES;
}


static JSBool OoliteScreenOverlay(JSContext *context, JSObject *this, uintN argc, jsval *argv, jsval *outResult)
{
	*outResult = JSVAL_FALSE;
	
	if ([UNIVERSE viewDirection] == VIEW_GUI_DISPLAY)
	{
		*outResult = BOOLEAN_TO_JSVAL([[UNIVERSE gui] setForegroundTexture:[OOTexture textureWithName:JSValToNSString(context, argv[0]) inFolder:@"Images"]]);
	}
	
	return YES;
}