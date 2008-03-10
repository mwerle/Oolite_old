//
//  main.m
//  DisplayTest
//
//  Created by Jens Ayton on 2007-12-08.
//  Copyright Jens Ayton 2007. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "OOLogging.h"

int main(int argc, char *argv[])
{
	return NSApplicationMain(argc,  (const char **) argv);
}


/****** Shims *******
Everything beyond this point is stuff that's needed to link, but whose full
behaviour is not needed.
*/
#undef NSLogv
BOOL OOLogWillDisplayMessagesInClass(NSString *inMessageClass)
{
	return YES;
}

void OOLogWithFunctionFileAndLine(NSString *inMessageClass, const char *inFunction, const char *inFile, unsigned long inLine, NSString *inFormat, ...)
{
	va_list args;
	va_start(args, inFormat);
	NSLogv(inFormat, args);
	va_end(args);
}


void OOLogGenericSubclassResponsibilityForFunction(const char *inFunction)
{
	OOLog(@"", @"%s is a subclass responsibility.", inFunction);
}


NSString * const kOOLogUnconvertedNSLog = @"nslog";


@implementation NSObject (DescriptionComponents)

- (NSString *)descriptionComponents
{
	return nil;
}


- (NSString *)description
{
	NSString				*components = nil;
	
	components = [self descriptionComponents];
	if (components != nil)
	{
		return [NSString stringWithFormat:@"<%@ %p>{%@}", [self class], self, components];
	}
	else
	{
		return [NSString stringWithFormat:@"<%@ %p>", [self class], self];
	}
}

@end
