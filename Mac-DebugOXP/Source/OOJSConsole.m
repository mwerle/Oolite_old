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

#import "OOJavaScriptEngine.h"
#import "OOJSScript.h"


static JSObject *sConsolePrototype = NULL;

OOJavaScriptConsoleController *sConsoleController;


static JSBool ConsoleGetProperty(JSContext *context, JSObject *this, jsval name, jsval *outValue);
static JSBool ConsoleSetProperty(JSContext *context, JSObject *this, jsval name, jsval *value);
static JSBool ConsoleConvert(JSContext *context, JSObject *this, JSType type, jsval *outValue);
static void ConsoleFinalize(JSContext *context, JSObject *this);

// Methods
static JSBool ConsoleConsoleMessage(JSContext *context, JSObject *this, uintN argc, jsval *argv, jsval *outResult);
static JSBool ConsoleScriptStack(JSContext *context, JSObject *this, uintN argc, jsval *argv, jsval *outResult);


static JSExtendedClass sConsoleClass =
{
	{
		"Console",
		JSCLASS_HAS_PRIVATE | JSCLASS_IS_EXTENDED,
		
		JS_PropertyStub,		// addProperty
		JS_PropertyStub,		// delProperty
		ConsoleGetProperty,		// getProperty
		ConsoleSetProperty,		// setProperty
		JS_EnumerateStub,		// enumerate
		JS_ResolveStub,			// resolve
		ConsoleConvert,			// convert
		ConsoleFinalize,		// finalize
		JSCLASS_NO_OPTIONAL_MEMBERS
	},
	NULL,						// equality
	NULL,						// outerObject
	NULL,						// innerObject
	JSCLASS_NO_RESERVED_MEMBERS
};


enum
{
	kConsole_global				// The global object
};


static JSPropertySpec sConsoleProperties[] =
{
	// JS name					ID							flags
	{ "global",					kConsole_global,			JSPROP_PERMANENT | JSPROP_ENUMERATE | JSPROP_READONLY },
	{ 0 }
};


static JSFunctionSpec sConsoleMethods[] =
{
	// JS name					Function					min args
	{ "consoleMessage",			ConsoleConsoleMessage,		2 },
	{ "scriptStack",			ConsoleScriptStack,			0 },
	{ 0 }
};


static void InitOOJSConsole(JSContext *context, JSObject *global)
{
    sConsolePrototype = JS_InitClass(context, global, NULL, &sConsoleClass.base, NULL, 0, sConsoleProperties, sConsoleMethods, NULL, NULL);
	JSRegisterObjectConverter(&sConsoleClass.base, JSBasicPrivateObjectConverter);
}


@implementation OOJavaScriptConsoleController (OOJavaScriptConversion)

- (jsval)javaScriptValueInContext:(JSContext *)context
{
	OOJavaScriptEngine		*engine = nil;
	JSObject				*object = NULL;
	
	engine = [OOJavaScriptEngine sharedEngine];
	
	if (sConsolePrototype == NULL)
	{
		InitOOJSConsole([engine context], [engine globalObject]);
	}
	
	if (context == NULL) context = [engine context];
	object = JS_NewObject(context, &sConsoleClass.base, sConsolePrototype, NULL);
	if (object != NULL)
	{
		if (!JS_SetPrivate(context, object, [self weakRetain]))  object = NULL;
	}
	if (object != NULL)  return OBJECT_TO_JSVAL(object);
	else  return JSVAL_NULL;
}

@end


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


static JSBool ConsoleConvert(JSContext *context, JSObject *this, JSType type, jsval *outValue)
{
	switch (type)
	{
		case JSTYPE_VOID:		// Used for string concatenation.
		case JSTYPE_STRING:
			*outValue = STRING_TO_JSVAL(JS_InternString(context, "[Console]"));
			return YES;
			
		default:
			// Contrary to what passes for documentation, JS_ConvertStub is not a no-op.
			return JS_ConvertStub(context, this, type, outValue);
	}
}


static void ConsoleFinalize(JSContext *context, JSObject *this)
{
	[(id)JS_GetPrivate(context, this) release];
	JS_SetPrivate(context, this, nil);
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


static JSBool ConsoleScriptStack(JSContext *context, JSObject *this, uintN argc, jsval *argv, jsval *outResult)
{
	NSArray				*result = nil;
	
	result = [OOJSScript scriptStack];
	*outResult = [result javaScriptValueInContext:context];
	OOLog(@"temp", @"Result = %@ -> %p", result, *outResult);
	return YES;
}
