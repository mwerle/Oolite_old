/*

OOJavaScriptConsoleController.m


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


#import "OOJavaScriptConsoleController.h"
#import "OOCollectionExtractors.h"
#import "OOLogging.h"
#import "OOColor.h"
#import "OODebugUtilities.h"
#import "ResourceManager.h"
#import "NSStringOOExtensions.h"
#import "OOTextFieldHistoryManager.h"

#import "OOJSConsole.h"
#import "OOScript.h"
#import "OOJSScript.h"
#import "OOJavaScriptEngine.h"

enum
{
	// Size limit for console scrollback
	kConsoleMaxSize			= 100000,
	kConsoleTrimToSize		= 80000,
	
	// Number of lines of console input to remember
	kConsoleMemory			= 100
};


@interface OOJavaScriptConsoleController (Private) <OOJavaScriptEngineMonitor>

- (void)appendString:(id)string;	// May be plain or attributed

/*	Find a colour specified in the config plist, with the key
	key-foreground-color or key-background-color. A key of nil will be treated
	as "general", the fallback colour.
*/
- (NSColor *)foregroundColorForKey:(NSString *)key;
- (NSColor *)backgroundColorForKey:(NSString *)key;

- (BOOL)showOnWarning;
- (void)setShowOnWarning:(BOOL)flag;
- (BOOL)showOnError;
- (void)setShowOnError:(BOOL)flag;
- (BOOL)showOnLog;
- (void)setShowOnLog:(BOOL)flag;

- (NSString *)sourceCodeForFile:(NSString *)filePath line:(unsigned)line;

- (NSArray *)loadSourceFile:(NSString *)filePath;

// Load certain groups of config settings.
- (void)setUpFonts;

/*	Convert a configuration dictionary to a standard form. In particular,
	convert all colour specifiers to RGBA arrays with values in [0, 1], and
	converts "show-console" values to booleans.
*/
- (NSMutableDictionary *)normalizeConfigDictionary:(NSDictionary *)dictionary;
- (id)normalizeConfigValue:(id)value forKey:(NSString *)key;

@end


@implementation OOJavaScriptConsoleController

- (void)dealloc
{
	[consoleWindow release];
	[inputHistoryManager release];
	
	[_baseFont release];
	[_boldFont release];
	
	[_configFromOXPs release];
	[_configOverrides release];
	
	[_fgColors release];
	[_bgColors release];
	[_sourceFiles release];
	
	if (_jsSelf != NULL)
	{
		JS_RemoveRoot([[OOJavaScriptEngine sharedEngine] context], &_jsSelf);
	}
	
	[super dealloc];
}


- (void)awakeFromNib
{
	NSUserDefaults				*defaults = nil;
	NSDictionary				*jsProps = nil;
	NSDictionary				*config = nil;
	
	assert(kConsoleTrimToSize < kConsoleMaxSize);
	
	_consoleScrollView = [consoleTextView enclosingScrollView];
	
	defaults = [NSUserDefaults standardUserDefaults];
	[inputHistoryManager setHistory:[defaults arrayForKey:@"debug-js-console-scrollback"]];
	
	config = [[ResourceManager dictionaryFromFilesNamed:@"jsConsoleConfig.plist"
											   inFolder:@"Config"
											   andMerge:YES] mutableCopy];
	_configFromOXPs = [[self normalizeConfigDictionary:config] copy];
	
	config = [defaults dictionaryForKey:@"debug-settings-override"];
	config = [self normalizeConfigDictionary:config];
	if (config == nil)  config = [NSMutableDictionary dictionary];
	_configOverrides = [config retain];
	
	[self setUpFonts];
	[consoleTextView setBackgroundColor:[self backgroundColorForKey:nil]];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillTerminate:) name:NSApplicationWillTerminateNotification object:nil];
	
	[[OOJavaScriptEngine sharedEngine] setMonitor:self];
	
	// Ensure auto-scrolling will work.
	[[_consoleScrollView verticalScroller] setFloatValue:1.0];
	
	// Set up JavaScript side of console.
	jsProps = [NSDictionary dictionaryWithObject:self forKey:@"console"];
	_script = [[OOScript nonLegacyScriptFromFileNamed:@"oolite-mac-js-console.js" properties:jsProps] retain];
}


- (void)applicationWillTerminate:(NSNotification *)notification
{
	NSUserDefaults				*defaults = nil;
	NSArray						*history = nil;
	
	defaults = [NSUserDefaults standardUserDefaults];
	
	history = [inputHistoryManager history];
	if (history != nil)
	{
		[defaults setObject:history forKey:@"debug-js-console-scrollback"];
	}
	
	if (_configOverrides != nil)
	{
		[defaults setObject:_configOverrides forKey:@"debug-settings-override"];
	}
}


#pragma mark -

- (IBAction)showConsole:sender
{
	[consoleWindow makeKeyAndOrderFront:sender];
	[consoleWindow makeFirstResponder:consoleInputField];
}


- (IBAction)toggleShowOnWarning:sender
{
	[self setShowOnWarning:![self showOnWarning]];
}


- (IBAction)toggleShowOnError:sender
{
	[self setShowOnError:![self showOnError]];
}


- (IBAction)toggleShowOnLog:sender
{
	[self setShowOnLog:![self showOnLog]];
}


- (IBAction)consolePerformCommand:sender
{
	NSString					*command = nil;
	
	// Use consoleInputField rather than sender so we can, e.g., add a button.
	command = [consoleInputField stringValue];
	if ([command length] == 0)  return;
	
	[consoleInputField setStringValue:@""];
	[inputHistoryManager addToHistory:command];
	
	[self performCommand:command];
}


- (void)performCommand:(NSString *)command
{
	NSString					*indentedCommand = nil;
	NSMutableAttributedString	*attrString = nil;
	NSDictionary				*fullAttributes = nil,
								*cmdAttributes = nil;
	
	indentedCommand = [[command componentsSeparatedByString:@"\n"] componentsJoinedByString:@"\n  "];
	
	fullAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
		_baseFont, NSFontAttributeName,
		[self backgroundColorForKey:@"command"], NSBackgroundColorAttributeName,
		[self foregroundColorForKey:nil], NSForegroundColorAttributeName,
		nil];
	cmdAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
		_boldFont, NSFontAttributeName,
		[self foregroundColorForKey:@"command"], NSForegroundColorAttributeName,
		nil];
	
	attrString = [NSMutableAttributedString stringWithString:[NSString stringWithFormat:@"> %@\n", indentedCommand]];
	[attrString addAttributes:fullAttributes range:NSMakeRange(0, [attrString length])];
	[attrString addAttributes:cmdAttributes range:NSMakeRange(2, [indentedCommand length])];
	
	[self appendString:attrString];
	[consoleWindow makeFirstResponder:consoleInputField];
	
	// Perform the actual command.
	[_script doEvent:@"consolePerformJSCommand" withArgument:command];
}


- (void)appendLine:(id)string colorKey:(NSString *)colorKey
{
	NSMutableAttributedString			*mutableStr = nil;
	NSColor								*fgColor = nil,
		*bgColor = nil;
	
	if ([string isKindOfClass:[NSString class]])
	{
		mutableStr = [NSMutableAttributedString stringWithString:string font:_baseFont];
	}
	else if ([string isKindOfClass:[NSAttributedString class]])
	{
		mutableStr = [[string mutableCopy] autorelease];
	}
	else
	{
		if (string != nil)
		{
			OOLog(@"debugOXP.jsConsole.appendString.failed", @"Attempt to append non-string type %@ to JavaScript console. This is an internal error, please report it.", [string class]);
		}
		
		return;
	}
	
	[mutableStr appendAttributedString:[@"\n" asAttributedStringWithFont:_baseFont]];
	
	fgColor = [self foregroundColorForKey:colorKey];
	if (fgColor != nil)
	{
		if ([fgColor alphaComponent] == 0.0)  return;
		[mutableStr addAttribute:NSForegroundColorAttributeName value:fgColor range:NSMakeRange(0, [mutableStr length])];
	}
	
	bgColor = [self backgroundColorForKey:colorKey];
	if (bgColor != nil)
	{
		[mutableStr addAttribute:NSBackgroundColorAttributeName value:bgColor range:NSMakeRange(0, [mutableStr length])];
	}
	
	[self appendString:mutableStr];
}


- (void)clear
{
	NSTextStorage				*textStorage = nil;
	
	textStorage = [consoleTextView textStorage];
	[textStorage deleteCharactersInRange:NSMakeRange(0, [textStorage length])];
}


- (id)configurationValueForKey:(NSString *)key
{
	return [self configurationValueForKey:key class:Nil defaultValue:nil];
}


- (id)configurationValueForKey:(NSString *)key class:(Class)class defaultValue:(id)value
{
	id							result = nil;
	
	if (class == Nil)  class = [NSObject class];
	
	result = [_configOverrides objectForKey:key];
	if (![result isKindOfClass:class] && result != [NSNull null])  result = [_configFromOXPs objectForKey:key];
	if (![result isKindOfClass:class] && result != [NSNull null])  result = [[value retain] autorelease];
	if (result == [NSNull null])  result = nil;
	
	return result;
}


- (long long)configurationIntValueForKey:(NSString *)key defaultValue:(long long)value
{
	long long					result;
	id							object = nil;
	
	object = [self configurationValueForKey:key];
	if ([object respondsToSelector:@selector(longLongValue)])  result = [object longLongValue];
	else if ([object respondsToSelector:@selector(intValue)])  result = [object intValue];
	else  result = value;
	
	return result;
}


- (void)setConfigurationValue:(id)value forKey:(NSString *)key
{
	if (key == nil)  return;
	
	value = [self normalizeConfigValue:value forKey:key];
	
	if (value == nil)
	{
		[_configOverrides removeObjectForKey:key];
	}
	else
	{
		if (_configOverrides == nil)  _configOverrides = [[NSMutableDictionary alloc] init];
		[_configOverrides setObject:value forKey:key];
	}
	
	// Apply changes
	if ([key hasSuffix:@"-foreground-color"] || [key hasSuffix:@"-foreground-colour"])
	{
		// Flush foreground colour cache
		[_fgColors removeAllObjects];
	}
	else if ([key hasSuffix:@"-background-color"] || [key hasSuffix:@"-background-colour"])
	{
		// Flush background colour cache
		[_bgColors removeAllObjects];
		[consoleTextView setBackgroundColor:[self backgroundColorForKey:nil]];
	}
	else if ([key hasPrefix:@"font-"])
	{
		[self setUpFonts];
	}
}


- (NSArray *)configurationKeys
{
	NSMutableSet				*result = nil;
	
	result = [NSMutableSet setWithCapacity:[_configFromOXPs count] + [_configOverrides count]];
	[result addObjectsFromArray:[_configFromOXPs allKeys]];
	[result addObjectsFromArray:[_configOverrides allKeys]];
	
	return [[result allObjects] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
}


#pragma mark -

- (BOOL)validateMenuItem:(id <NSMenuItem>)menuItem
{
	SEL							action = NULL;
	
	action = [menuItem action];
	
	if (action == @selector(toggleShowOnWarning:))
	{
		[menuItem setState:[self showOnWarning]];
		return YES;
	}
	if (action == @selector(toggleShowOnError:))
	{
		[menuItem setState:[self showOnError]];
		return YES;
	}
	if (action == @selector(toggleShowOnLog:))
	{
		[menuItem setState:[self showOnLog]];
		return YES;
	}
	
	return [self respondsToSelector:action];
}

@end


@implementation OOJavaScriptConsoleController (Private)

- (void)appendString:(id)string
{
	NSTextStorage					*textStorage = nil;
	BOOL							doScroll;
	unsigned						length;
	
	if ([string isKindOfClass:[NSString class]])
	{
		string = [NSMutableAttributedString stringWithString:string font:_baseFont];
	}
	if (![string isKindOfClass:[NSAttributedString class]])
	{
		if (string != nil)
		{
			OOLog(@"debugOXP.jsConsole.appendString.failed", @"Attempt to append non-string type %@ to JavaScript console. This is an internal error, please report it.", [string class]);
		}
		
		return;
	}
	
	doScroll = [[_consoleScrollView verticalScroller] floatValue] > 0.980;
	
	textStorage = [consoleTextView textStorage];
	[textStorage appendAttributedString:string];
	length = [textStorage length];
	if (length > kConsoleMaxSize)
	{
		[textStorage deleteCharactersInRange:NSMakeRange(length - kConsoleTrimToSize, kConsoleTrimToSize)];
	}
	
	// Scroll to end of field
	if (doScroll)  [consoleTextView scrollRangeToVisible:NSMakeRange([[consoleTextView string] length], 0)];
}


- (NSColor *)foregroundColorForKey:(NSString *)key
{
	NSColor						*result = nil;
	NSString					*expandedKey = nil;
	
	if (key == nil)  key = @"general";
	
	result = [_fgColors objectForKey:key];
	if (result == nil)
	{
		// No cached colour; load colour description from config file
		expandedKey = [key stringByAppendingString:@"-foreground-color"];
		result = [NSColor colorWithOOColorDescription:[self configurationValueForKey:expandedKey]];
		if (result == nil)
		{
			expandedKey = [key stringByAppendingString:@"-foreground-colour"];
			result = [NSColor colorWithOOColorDescription:[self configurationValueForKey:expandedKey]];
		}
		if (result == nil && ![key isEqualToString:@"general"])
		{
			result = [self foregroundColorForKey:nil];
		}
		if (result == nil)  result = [NSColor blackColor];
		
		// Store loaded colour in cache
		if (result != nil)
		{
			if (_fgColors == nil)  _fgColors = [[NSMutableDictionary alloc] init];
			[_fgColors setObject:result forKey:key];
		}
	}
	
	return result;
}


- (NSColor *)backgroundColorForKey:(NSString *)key
{
	NSColor						*result = nil;
	NSString					*expandedKey = nil;
	
	if (key == nil)  key = @"general";
	
	result = [_bgColors objectForKey:key];
	if (result == nil)
	{
		// No cached colour; load colour description from config file
		expandedKey = [key stringByAppendingString:@"-background-color"];
		result = [NSColor colorWithOOColorDescription:[self configurationValueForKey:expandedKey]];
		if (result == nil)
		{
			expandedKey = [key stringByAppendingString:@"-background-colour"];
			result = [NSColor colorWithOOColorDescription:[self configurationValueForKey:expandedKey]];
		}
		if (result == nil && ![key isEqualToString:@"general"])
		{
			result = [self backgroundColorForKey:nil];
		}
		if (result == nil)  result = [NSColor whiteColor];
		
		// Store loaded colour in cache
		if (result != nil)
		{
			if (_bgColors == nil)  _bgColors = [[NSMutableDictionary alloc] init];
			[_bgColors setObject:result forKey:key];
		}
	}
	
	return result;
}


- (BOOL)showOnWarning
{
	return OOBooleanFromObject([self configurationValueForKey:@"show-console-on-warning"], YES);
}


- (void)setShowOnWarning:(BOOL)flag
{
	[self setConfigurationValue:[NSNumber numberWithBool:flag] forKey:@"show-console-on-warning"];
}


- (BOOL)showOnError
{
	return OOBooleanFromObject([self configurationValueForKey:@"show-console-on-error"], YES);
}


- (void)setShowOnError:(BOOL)flag
{
	[self setConfigurationValue:[NSNumber numberWithBool:flag] forKey:@"show-console-on-error"];
}


- (BOOL)showOnLog
{
	return OOBooleanFromObject([self configurationValueForKey:@"show-console-on-log"], NO);
}


- (void)setShowOnLog:(BOOL)flag
{
	[self setConfigurationValue:[NSNumber numberWithBool:flag] forKey:@"show-console-on-log"];
}


- (NSString *)sourceCodeForFile:(NSString *)filePath line:(unsigned)line
{
	id							linesForFile = nil;
	
	linesForFile = [_sourceFiles objectForKey:filePath];
	
	if (linesForFile == nil)
	{
		linesForFile = [self loadSourceFile:filePath];
		if (linesForFile == nil)  linesForFile = [NSString stringWithFormat:@"<Can't load file %@>", filePath];
		
		if (_sourceFiles == nil)  _sourceFiles = [[NSMutableDictionary alloc] init];
		[_sourceFiles setObject:linesForFile forKey:filePath];
	}
	
	if ([linesForFile count] < line || line == 0)  return @"<line out of range!>";
	
	return [linesForFile objectAtIndex:line - 1];
}


- (NSArray *)loadSourceFile:(NSString *)filePath
{
	NSString					*contents = nil;
	NSArray						*lines = nil;
	
	if (filePath == nil)  return nil;
	
	contents = [NSString stringWithContentsOfUnicodeFile:filePath];
	if (contents == nil)  return nil;
	
	/*	Extract lines from file.
		FIXME: this works with CRLF and LF, but not CR.
	*/
	lines = [contents componentsSeparatedByString:@"\n"];
	return lines;
}


- (void)setUpFonts
{
	NSString					*fontFace = nil;
	int							fontSize;
	
	[_baseFont release];
	_baseFont = nil;
	[_boldFont release];
	_boldFont = nil;
	
	// Set font.
	fontFace = [self configurationValueForKey:@"font-face"
										class:[NSString class]
								 defaultValue:@"Courier"];
	fontSize = [self configurationIntValueForKey:@"font-size"
									defaultValue:12];
	
	_baseFont = [NSFont fontWithName:fontFace size:fontSize];
	if (_baseFont == nil)  _baseFont = [NSFont userFixedPitchFontOfSize:0];
	[_baseFont retain];
	
	// Get bold variant of font.
	_boldFont = [[NSFontManager sharedFontManager] convertFont:_baseFont
												   toHaveTrait:NSBoldFontMask];
	if (_boldFont == nil)  _boldFont = _baseFont;
	[_boldFont retain];
}


- (NSMutableDictionary *)normalizeConfigDictionary:(NSDictionary *)dictionary
{
	NSMutableDictionary		*result = nil;
	NSEnumerator			*keyEnum = nil;
	NSString				*key = nil;
	id						value = nil;
	
	result = [NSMutableDictionary dictionaryWithCapacity:[dictionary count]];
	for (keyEnum = [dictionary keyEnumerator]; (key = [keyEnum nextObject]); )
	{
		value = [dictionary objectForKey:key];
		value = [self normalizeConfigValue:value forKey:key];
		
		if (key != nil && value != nil)  [result setObject:value forKey:key];
	}
	
	return result;
}


- (id)normalizeConfigValue:(id)value forKey:(NSString *)key
{
	OOColor					*color = nil;
	BOOL					boolValue;
	
	if (value != nil)
	{
		if ([key hasSuffix:@"-color"] || [key hasSuffix:@"-colour"])
		{
			color = [OOColor colorWithDescription:value];
			value = [color normalizedArray];
		}
		else if ([key hasPrefix:@"show-console"])
		{
			boolValue = OOBooleanFromObject(value, NO);
			value = [NSNumber numberWithBool:boolValue];
		}
	}
	
	return value;
}


#pragma mark -

- (oneway void)jsEngine:(in byref OOJavaScriptEngine *)engine
				context:(in JSContext *)context
				  error:(in JSErrorReport *)errorReport
			withMessage:(in NSString *)message
{
	NSString					*colorKey = nil;
	NSString					*prefix = nil;
	NSMutableAttributedString	*formattedMessage = nil;
	NSString					*filePath = nil;
	NSString					*fileAndLine = nil;
	NSString					*sourceLine = nil;
	NSString					*scriptLine = nil;
	BOOL						show;
	
	if (errorReport->flags & JSREPORT_WARNING)
	{
		colorKey = @"warning";
		prefix = @"Warning";
	}
	else if (errorReport->flags & JSREPORT_EXCEPTION)
	{
		colorKey = @"exception";
		prefix = @"Exception";
	}
	else
	{
		colorKey = @"error";
		prefix = @"Error";
	}
	
	if (errorReport->flags & JSREPORT_STRICT)
	{
		prefix = [prefix stringByAppendingString:@" (strict mode)"];
	}
	prefix = [prefix stringByAppendingString:@": "];
	
	// Format string: bold for prefix, standard font for rest.
	formattedMessage = [NSMutableAttributedString stringWithString:[prefix stringByAppendingString:message]];
	[formattedMessage addAttribute:NSFontAttributeName
							 value:_boldFont
							 range:NSMakeRange(0, [prefix length])];
	[formattedMessage addAttribute:NSFontAttributeName
							 value:_baseFont
							 range:NSMakeRange([prefix length], [message length])];
	
	// Note that the "active script" isn't necessarily the one causing the error, since one script can call another's methods.
	scriptLine = [[OOJSScript currentlyRunningScript] displayName];
	if (scriptLine != nil)  scriptLine = [@"    Active script: " stringByAppendingString:[[OOJSScript currentlyRunningScript] displayName]];
	
	filePath = [NSString stringWithUTF8String:errorReport->filename];
	fileAndLine = [filePath lastPathComponent];
	fileAndLine = [NSString stringWithFormat:@"    %@, line %u:", fileAndLine, errorReport->lineno];
	
	sourceLine = [self sourceCodeForFile:filePath line:errorReport->lineno];
	sourceLine = [@"    " stringByAppendingString:sourceLine];
	
	[self appendLine:formattedMessage colorKey:colorKey];
	[self appendLine:fileAndLine colorKey:colorKey];
	if (sourceLine != nil)  [self appendLine:sourceLine colorKey:colorKey];
	if (scriptLine != nil)  [self appendLine:scriptLine colorKey:colorKey];
	
	if (errorReport->flags & JSREPORT_WARNING)  show = [self showOnWarning];
	else  show = [self showOnError];
	if (show)
	{
		[self showConsole:nil];
	}
}


- (oneway void)jsEngine:(in byref OOJavaScriptEngine *)engine
				context:(in JSContext *)context
			 logMessage:(in NSString *)message
				ofClass:(in NSString *)messageClass
{
	[self appendLine:message colorKey:@"log"];
	if ([self showOnLog])  [self showConsole:nil];
}


#pragma mark -

- (jsval)javaScriptValueInContext:(JSContext *)context
{
	if (context != [[OOJavaScriptEngine sharedEngine] context])  return JSVAL_VOID;
	if (_jsSelf == NULL)
	{
		_jsSelf = ConsoleToJSConsole(context, self);
		if (_jsSelf != NULL)
		{
			if (!JS_AddNamedRoot(context, &_jsSelf, "debug console"))
			{
				_jsSelf = NULL;
			}
		}
	}
	
	if (_jsSelf != NULL)  return OBJECT_TO_JSVAL(_jsSelf);
	else  return JSVAL_NULL;
}

@end
