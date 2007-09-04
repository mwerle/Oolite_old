/*

OOJSConsole.m


Oolite Debug OXP

Copyright (C) 2007 Jens Ayton

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

*/

#import "OOJSConsole.h"
#import "OOJavaScriptConsoleController.h"
#import <stdint.h>

#import "OOJavaScriptEngine.h"
#import "OOJSScript.h"
#import "OOJSVector.h"


static JSObject *sConsolePrototype = NULL;
static JSObject *sConsoleSettingsPrototype = NULL;


static JSBool ConsoleGetProperty(JSContext *context, JSObject *this, jsval name, jsval *outValue);
static JSBool ConsoleSetProperty(JSContext *context, JSObject *this, jsval name, jsval *value);
static void ConsoleFinalize(JSContext *context, JSObject *this);

// Methods
static JSBool ConsoleConsoleMessage(JSContext *context, JSObject *this, uintN argc, jsval *argv, jsval *outResult);
static JSBool ConsoleClearConsole(JSContext *context, JSObject *this, uintN argc, jsval *argv, jsval *outResult);
static JSBool ConsoleScriptStack(JSContext *context, JSObject *this, uintN argc, jsval *argv, jsval *outResult);

static JSBool ConsoleSettingsDeleteProperty(JSContext *context, JSObject *this, jsval name, jsval *outValue);
static JSBool ConsoleSettingsGetProperty(JSContext *context, JSObject *this, jsval name, jsval *outValue);
static JSBool ConsoleSettingsSetProperty(JSContext *context, JSObject *this, jsval name, jsval *value);


static JSClass sConsoleClass =
{
	"Console",
	JSCLASS_HAS_PRIVATE,
	
	JS_PropertyStub,		// addProperty
	JS_PropertyStub,		// delProperty
	ConsoleGetProperty,		// getProperty
	ConsoleSetProperty,		// setProperty
	JS_EnumerateStub,		// enumerate
	JS_ResolveStub,			// resolve
	JS_ConvertStub,			// convert
	ConsoleFinalize,		// finalize
	JSCLASS_NO_OPTIONAL_MEMBERS
};


enum
{
	kConsole_global				// The global object
};


static JSPropertySpec sConsoleProperties[] =
{
	// JS name					ID							flags
//	{ "global",					kConsole_global,			JSPROP_PERMANENT | JSPROP_ENUMERATE | JSPROP_READONLY },
	{ 0 }
};


static JSFunctionSpec sConsoleMethods[] =
{
	// JS name					Function					min args
	{ "consoleMessage",			ConsoleConsoleMessage,		2 },
	{ "clearConsole",			ConsoleClearConsole,		0 },
	{ "scriptStack",			ConsoleScriptStack,			0 },
	{ 0 }
};


static JSClass sConsoleSettingsClass =
{
	"ConsoleSettings",
	JSCLASS_HAS_PRIVATE,
	
	JS_PropertyStub,		// addProperty
	ConsoleSettingsDeleteProperty, // delProperty
	ConsoleSettingsGetProperty, // getProperty
	ConsoleSettingsSetProperty, // setProperty
	JS_EnumerateStub,		// enumerate. FIXME: this should work.
	JS_ResolveStub,			// resolve
	JS_ConvertStub,			// convert
	ConsoleFinalize,		// finalize (same as Console)
	JSCLASS_NO_OPTIONAL_MEMBERS
};


static void InitOOJSConsole(JSContext *context, JSObject *global)
{
    sConsolePrototype = JS_InitClass(context, global, NULL, &sConsoleClass, NULL, 0, sConsoleProperties, sConsoleMethods, NULL, NULL);
	JSRegisterObjectConverter(&sConsoleClass, JSBasicPrivateObjectConverter);
	
    sConsoleSettingsPrototype = JS_InitClass(context, global, NULL, &sConsoleSettingsClass, NULL, 0, NULL, NULL, NULL, NULL);
	JSRegisterObjectConverter(&sConsoleSettingsClass, JSBasicPrivateObjectConverter);
}


JSObject *ConsoleToJSConsole(JSContext *context, OOJavaScriptConsoleController *console)
{
	OOJavaScriptEngine		*engine = nil;
	JSObject				*object = NULL;
	JSObject				*settingsObject = NULL;
	jsval					value;
	
	engine = [OOJavaScriptEngine sharedEngine];
	if (context == NULL) context = [engine context];
	
	if (sConsolePrototype == NULL)
	{
		InitOOJSConsole(context, [engine globalObject]);
	}
	
	// Create Console object
	object = JS_NewObject(context, &sConsoleClass, sConsolePrototype, NULL);
	if (object != NULL)
	{
		if (!JS_SetPrivate(context, object, [console weakRetain]))  object = NULL;
	}
	
	if (object != NULL)
	{
		// Create ConsoleSettings object
		settingsObject = JS_NewObject(context, &sConsoleSettingsClass, sConsoleSettingsPrototype, NULL);
		if (settingsObject != NULL)
		{
			if (!JS_SetPrivate(context, settingsObject, [console weakRetain]))  settingsObject = NULL;
		}
		if (settingsObject != NULL)
		{
			value = OBJECT_TO_JSVAL(settingsObject);
			if (!JS_SetProperty(context, object, "settings", &value))
			{
				settingsObject = NULL;
			}
		}

		if (settingsObject == NULL)  object = NULL;
	}
	
	return object;
}


static JSBool ConsoleGetProperty(JSContext *context, JSObject *this, jsval name, jsval *outValue)
{
	if (!JSVAL_IS_INT(name))  return YES;
	
	switch (JSVAL_TO_INT(name))
	{
		case kConsole_global:
			*outValue = OBJECT_TO_JSVAL([[OOJavaScriptEngine sharedEngine] globalObject]);
			break;
			
		default:
			OOReportJavaScriptBadPropertySelector(context, @"Console", JSVAL_TO_INT(name));
			return NO;
	}
	
	return YES;
}


static JSBool ConsoleSetProperty(JSContext *context, JSObject *this, jsval name, jsval *value)
{
	if (!JSVAL_IS_INT(name))  return YES;
	OOReportJavaScriptBadPropertySelector(context, @"Console", JSVAL_TO_INT(name));
	return NO;
}


static void ConsoleFinalize(JSContext *context, JSObject *this)
{
	[(id)JS_GetPrivate(context, this) release];
	JS_SetPrivate(context, this, nil);
}


static JSBool ConsoleSettingsDeleteProperty(JSContext *context, JSObject *this, jsval name, jsval *outValue)
{
	NSString			*key = nil;
	id					console = nil;
	
	if (!JSVAL_IS_STRING(name))  return NO;
	
	key = [NSString stringWithJavaScriptValue:name inContext:context];
	
	console = JSObjectToObject(context, this);
	if (![console isKindOfClass:[OOJavaScriptConsoleController class]])
	{
		OOReportJavaScriptError(context, @"Expected OOJavaScriptConsoleController, got %@ in %s. This is an internal error, please report it.", [console class], __PRETTY_FUNCTION__);
		return NO;
	}
	
	[console setConfigurationValue:nil forKey:key];
	*outValue = JSVAL_TRUE;
	return YES;
}


static JSBool ConsoleSettingsGetProperty(JSContext *context, JSObject *this, jsval name, jsval *outValue)
{
	NSString			*key = nil;
	id					value = nil;
	id					console = nil;
	
	if (!JSVAL_IS_STRING(name))  return YES;
	key = [NSString stringWithJavaScriptValue:name inContext:context];
	
	console = JSObjectToObject(context, this);
	if (![console isKindOfClass:[OOJavaScriptConsoleController class]])
	{
		OOReportJavaScriptError(context, @"Expected OOJavaScriptConsoleController, got %@ in %s. This is an internal error, please report it.", [console class], __PRETTY_FUNCTION__);
		return YES;
	}
	
	value = [console configurationValueForKey:key];
	*outValue = [value javaScriptValueInContext:context];
	
	return YES;
}


static JSBool ConsoleSettingsSetProperty(JSContext *context, JSObject *this, jsval name, jsval *inValue)
{
	NSString			*key = nil;
	id					value = nil;
	id					console = nil;
	
	if (!JSVAL_IS_STRING(name))  return YES;
	key = [NSString stringWithJavaScriptValue:name inContext:context];
	
	console = JSObjectToObject(context, this);
	if (![console isKindOfClass:[OOJavaScriptConsoleController class]])
	{
		OOReportJavaScriptError(context, @"Expected OOJavaScriptConsoleController, got %@ in %s. This is an internal error, please report it.", [console class], __PRETTY_FUNCTION__);
		return YES;
	}
	
	if (JSVAL_IS_NULL(*inValue) || JSVAL_IS_VOID(*inValue))
	{
		[console setConfigurationValue:nil forKey:key];
	}
	else
	{
		value = JSValueToObject(context, *inValue);
		if (value != nil)
		{
			[console setConfigurationValue:value forKey:key];
		}
		else
		{
			OOReportJavaScriptWarning(context, @"debugConsole.settings: could not convert %@ to native object.", [NSString stringWithJavaScriptValue:*inValue inContext:context]);
		}
	}
	
	return YES;
}


// Methods
static JSBool ConsoleConsoleMessage(JSContext *context, JSObject *this, uintN argc, jsval *argv, jsval *outResult)
{
	id					console = nil;
	NSString			*colorKey = nil, *message = nil;
	
	console = JSObjectToObject(context, this);
	if (![console isKindOfClass:[OOJavaScriptConsoleController class]])
	{
		OOReportJavaScriptError(context, @"Expected OOJavaScriptConsoleController, got %@ in %s. This is an internal error, please report it.", [console class], __PRETTY_FUNCTION__);
		return NO;
	}
	
	colorKey = [NSString stringWithJavaScriptValue:argv[0] inContext:context];
	message = [NSString concatenationOfStringsFromJavaScriptValues:argv + 1 count:argc - 1 separator:@", " inContext:context];
	
	[console appendLine:message colorKey:colorKey];
	return YES;
}


static JSBool ConsoleClearConsole(JSContext *context, JSObject *this, uintN argc, jsval *argv, jsval *outResult)
{
	id					console = nil;
	
	console = JSObjectToObject(context, this);
	if (![console isKindOfClass:[OOJavaScriptConsoleController class]])
	{
		OOReportJavaScriptError(context, @"Expected OOJavaScriptConsoleController, got %@ in %s. This is an internal error, please report it.", [console class], __PRETTY_FUNCTION__);
		return YES;
	}
	
	[console clear];
	return YES;
}


static JSBool ConsoleScriptStack(JSContext *context, JSObject *this, uintN argc, jsval *argv, jsval *outResult)
{
	NSArray				*result = nil;
	
	result = [OOJSScript scriptStack];
	*outResult = [result javaScriptValueInContext:context];
	OOLog(@"temp", @"Result = %@ -> %p", result, *outResult);
	return YES;
}
