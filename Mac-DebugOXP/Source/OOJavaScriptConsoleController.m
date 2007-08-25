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

#import "OOJavaScriptEngine.h"

enum
{
	// Size limit for console scrollback
	kConsoleMaxSize			= 100000,
	kConsoleTrimToSize		= 80000
};


@interface OOJavaScriptConsoleController (Private) <OOJavaScriptEngineMonitor>

- (void)appendString:(id)string;	// May be plain or attributed
- (void)appendLine:(id)string colorKey:(NSString *)colorKey;

/*	Find a colour specified in the config plist, with the key
key-foreground-color or key-background-color. A key of nil will be treated
as "general", the fallback colour.
*/
- (NSColor *)foregroundColorForKey:(NSString *)key;
- (NSColor *)backgroundColorForKey:(NSString *)key;

- (NSString *)sourceCodeForFile:(NSString *)filePath line:(unsigned)line;

- (NSArray *)loadSourceFile:(NSString *)filePath;

@end


@implementation OOJavaScriptConsoleController

- (void)dealloc
{
	[consoleWindow release];
	
	[_baseFont release];
	[_boldFont release];
	
	[_config release];
	
	[_fgColors release];
	[_bgColors release];
	[_sourceFiles release];
	
	[super dealloc];
}


- (void)awakeFromNib
{
	NSUserDefaults				*defaults = nil;
	
	assert(kConsoleTrimToSize < kConsoleMaxSize);
	
	_consoleScrollView = [consoleTextView enclosingScrollView];
	
	defaults = [NSUserDefaults standardUserDefaults];
	_showOnWarning = [defaults boolForKey:@"debug-show-js-console-on-warning" defaultValue:YES];
	_showOnError = [defaults boolForKey:@"debug-show-js-console-on-error" defaultValue:YES];
	_showOnLog = [defaults boolForKey:@"debug-show-js-console-on-log" defaultValue:NO];
	
	OOLog(@"debugOXP.jsConsole.flags", @"showOnWarning: %s  showOnError: %s", _showOnWarning ? "YES" : "NO", _showOnError ? "YES" : "NO");
	
	_config = [ResourceManager dictionaryFromFilesNamed:@"jsConsoleConfig.plist"
											   inFolder:@"Config"
											   andMerge:YES];
	[_config retain];
	
	// Set font.
	NSString *fontFace = [_config stringForKey:@"font-face" defaultValue:@"Courier"];
	int fontSize = [_config intForKey:@"font-size" defaultValue:12];
	_baseFont = [NSFont fontWithName:fontFace size:fontSize];
	if (_baseFont == nil)  _baseFont = [NSFont userFixedPitchFontOfSize:0];
	[_baseFont retain];
	
	// Get bold variant of font.
	_boldFont = [[NSFontManager sharedFontManager] convertFont:_baseFont toHaveTrait:NSBoldFontMask];
	if (_boldFont == nil)  _boldFont = _baseFont;
	[_boldFont retain];
	
	OOLog(@"debugOXP.jsConsole.setMonitor", @"Setting monitor for JS engine %@", [OOJavaScriptEngine sharedEngine]);
	[[OOJavaScriptEngine sharedEngine] setMonitor:self];
	
	[consoleTextView setBackgroundColor:[self backgroundColorForKey:nil]];
}


#pragma mark -

- (IBAction)showConsole:sender
{
	[consoleWindow makeKeyAndOrderFront:sender];
	[consoleWindow makeFirstResponder:consoleInputField];
}


- (IBAction)toggleShowOnLog:sender
{
	_showOnLog = !_showOnLog;
	[[NSUserDefaults standardUserDefaults] setBool:_showOnLog forKey:@"debug-show-js-console-on-log"];
}


- (IBAction)toggleShowOnWarning:sender
{
	_showOnWarning = !_showOnWarning;
	[[NSUserDefaults standardUserDefaults] setBool:_showOnWarning forKey:@"debug-show-js-console-on-warning"];
}


- (IBAction)toggleShowOnError:sender
{
	_showOnError = !_showOnError;
	[[NSUserDefaults standardUserDefaults] setBool:_showOnWarning forKey:@"debug-show-js-console-on-error"];
}


- (IBAction)consolePerformCommand:sender
{
	NSString					*string = nil;
	NSMutableAttributedString	*attrString = nil;
	NSDictionary				*fullAttributes = nil,
								*cmdAttributes = nil;
	
	// Use consoleInputField rather than sender so we can, e.g., add a button.
	string = [consoleInputField stringValue];
	[consoleInputField setStringValue:@""];
	
	fullAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
						_baseFont, NSFontAttributeName,
						[self backgroundColorForKey:@"command"], NSBackgroundColorAttributeName,
						[self foregroundColorForKey:nil], NSForegroundColorAttributeName,
						nil];
	cmdAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
						_boldFont, NSFontAttributeName,
						[self foregroundColorForKey:@"command"], NSForegroundColorAttributeName,
						nil];
	
	attrString = [NSMutableAttributedString stringWithString:[NSString stringWithFormat:@"> %@\n", string]];
	[attrString addAttributes:fullAttributes range:NSMakeRange(0, [attrString length])];
	[attrString addAttributes:cmdAttributes range:NSMakeRange(2, [string length])];
	
	[self appendString:attrString];
	[consoleWindow makeFirstResponder:consoleInputField];
}


#pragma mark -

- (BOOL)validateMenuItem:(id <NSMenuItem>)menuItem
{
	SEL							action = NULL;
	
	action = [menuItem action];
	
	if (action == @selector(toggleShowOnWarning:))
	{
		[menuItem setState:_showOnWarning];
		return YES;
	}
	if (action == @selector(toggleShowOnError:))
	{
		[menuItem setState:_showOnError];
		return YES;
	}
	if (action == @selector(toggleShowOnLog:))
	{
		[menuItem setState:_showOnLog];
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
		mutableStr = [string mutableCopy];
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
		[mutableStr addAttribute:NSForegroundColorAttributeName value:fgColor range:NSMakeRange(0, [mutableStr length])];
	}
	
	bgColor = [self backgroundColorForKey:colorKey];
	if (bgColor != nil)
	{
		[mutableStr addAttribute:NSBackgroundColorAttributeName value:bgColor range:NSMakeRange(0, [mutableStr length])];
	}
	
	[self appendString:mutableStr];
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
		result = [NSColor colorWithOOColorDescription:[_config objectForKey:expandedKey]];
		if (result == nil)
		{
			expandedKey = [key stringByAppendingString:@"-foreground-colour"];
			result = [NSColor colorWithOOColorDescription:[_config objectForKey:expandedKey]];
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
		result = [NSColor colorWithOOColorDescription:[_config objectForKey:expandedKey]];
		if (result == nil)
		{
			expandedKey = [key stringByAppendingString:@"-background-colour"];
			result = [NSColor colorWithOOColorDescription:[_config objectForKey:expandedKey]];
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
	[formattedMessage addAttribute:NSFontAttributeName value:_boldFont range:NSMakeRange(0, [prefix length])];
	[formattedMessage addAttribute:NSFontAttributeName value:_baseFont range:NSMakeRange([prefix length], [message length])];
	
	filePath = [NSString stringWithUTF8String:errorReport->filename];
	fileAndLine = [filePath lastPathComponent];
	fileAndLine = [NSString stringWithFormat:@"    %@, line %u:", fileAndLine, errorReport->lineno];
	
	sourceLine = [self sourceCodeForFile:filePath line:errorReport->lineno];
	sourceLine = [@"    " stringByAppendingString:sourceLine];
	
	[self appendLine:formattedMessage colorKey:colorKey];
	[self appendLine:fileAndLine colorKey:colorKey];
	if (sourceLine != nil)  [self appendLine:sourceLine colorKey:colorKey];
	
	if (((errorReport->flags & JSREPORT_WARNING) && _showOnWarning) || _showOnError)
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
	if (_showOnLog)  [self showConsole:nil];
}

@end
