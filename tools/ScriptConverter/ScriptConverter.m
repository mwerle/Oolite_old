#import <Foundation/Foundation.h>
#import <stdlib.h>
#import "OOLegacyScriptToJavaScriptConverter.h"


@interface SimpleProblemReporter: NSObject <OOProblemReportManager>
{
	OOProblemSeverity			_highest;
}
@end


int main (int argc, const char * argv[])
{
	NSString				*path = nil;
	NSDictionary			*scripts = nil;
	SimpleProblemReporter	*problemReporter = nil;
	NSDictionary			*result = nil;
	NSEnumerator			*scriptEnum = nil;
	NSString				*name = nil;
	
	[[NSAutoreleasePool alloc] init];
	
	if (argc < 2)
	{
		printf("No file specified.\n");
		return EXIT_FAILURE;
	}
	
	path = [[NSString stringWithUTF8String:argv[1]] stringByStandardizingPath];
	scripts = [NSDictionary dictionaryWithContentsOfFile:path];
	if (scripts == nil)
	{
		printf("Could not open file %s.\n", [path UTF8String]);
		return EXIT_FAILURE;
	}
	
	problemReporter = [[[SimpleProblemReporter alloc] init] autorelease];
	
	result = [OOLegacyScriptToJavaScriptConverter convertMultipleScripts:scripts
																metadata:nil
														 problemReporter:problemReporter];
	
	if (result != nil)
	{
		for (scriptEnum = [result keyEnumerator]; (name = [scriptEnum nextObject]); )
		{
			printf("%s.js:\n\n%s\n-----\n", [name UTF8String], [[result objectForKey:name] UTF8String]);
		}
		return EXIT_SUCCESS;
	}
	else
	{
		printf("Conversion failed.\n");
		return EXIT_FAILURE;
	}
}


@implementation SimpleProblemReporter

- (void) addNoteIssueWithKey:(NSString *)key format:(NSString *)format, ...
{
	NSString			*message = nil;
	va_list				args;
	
	va_start(args, format);
	message = [[NSString alloc] initWithFormat:format arguments:args];
	va_end(args);
	
	if (_highest < kOOProblemSeverityNote)  _highest = kOOProblemSeverityNote;
	printf("Note: %s\n", [message UTF8String]);
	[message release];
}


- (void) addWarningIssueWithKey:(NSString *)key format:(NSString *)format, ...
{
	NSString			*message = nil;
	va_list				args;
	
	va_start(args, format);
	message = [[NSString alloc] initWithFormat:format arguments:args];
	va_end(args);
	
	if (_highest < kOOProblemSeverityWarning)  _highest = kOOProblemSeverityWarning;
	printf("Warning: %s\n", [message UTF8String]);
	[message release];
}


- (void) addStopIssueWithKey:(NSString *)key format:(NSString *)format, ...
{
	NSString			*message = nil;
	va_list				args;
	
	va_start(args, format);
	message = [[NSString alloc] initWithFormat:format arguments:args];
	va_end(args);
	
	if (_highest < kOOProblemSeverityStop)  _highest = kOOProblemSeverityStop;
	printf("Error: %s\n", [message UTF8String]);
	[message release];
}


- (void) addBugIssueWithKey:(NSString *)key format:(NSString *)format, ...
{
	NSString			*message = nil;
	va_list				args;
	
	va_start(args, format);
	message = [[NSString alloc] initWithFormat:format arguments:args];
	va_end(args);
	
	if (_highest < kOOProblemSeverityBug)  _highest = kOOProblemSeverityBug;
	printf("Bug: %s\n", [message UTF8String]);
	[message release];
}


- (OOProblemSeverity) highestSeverity
{
	return _highest;
}

@end
