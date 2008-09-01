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

- (void) addIssueWithSeverity:(OOProblemSeverity)severity key:(NSString *)key description:(NSString *)description
{
	if (_highest < severity)  _highest = severity;
	
	static const char * const prefixes[] = { "Note", "Note", "Warning", "Unknown selector", "Error", "Bug" };
	if (severity > kOOProblemSeverityBug)  severity = kOOProblemSeverityBug;
	const char *prefix = prefixes[severity];
	
	printf("%s: %s\n", prefix, [description UTF8String]);
}

- (OOProblemSeverity) highestSeverity
{
	return _highest;
}

@end
