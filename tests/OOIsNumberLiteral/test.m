#import <Foundation/Foundation.h>
#import "OOIsNumberLiteral.h"


static NSString *sValidStrings[] =
{
	@"0",
	@"1",
	@"-1",
	@"0.1",
	@"-0.1",
	@"1e1",
	@"1e10",
	@"1e-10",
	@"-1e10",
	@"-1e-10",
	@"0.01E3"
};


static NSString *sValidWithSpaceStrings[] =
{
	@"  1e1",
	@"1e1  ",
	@"  1e1  "
};


static NSString *sInvalidStrings[] =
{
	@"1 2",
	@"a",
	@"1a",
	@"1e",
	nil,
	@"",
	@" "
};


#define COUNT(x)	(sizeof x / sizeof *x)
#define FAIL(x)		do { failed = YES; NSLog(@"FAIL: %@", x); } while (0)


int main (int argc, const char * argv[])
{
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	
	BOOL failed = NO;
	int i;
	
	for (i = 0; i != COUNT(sValidStrings); ++i)
	{
		if (!OOIsNumberLiteral(sValidStrings[i], NO))
		{
			FAIL(sValidStrings[i]);
		}
	}
	
	for (i = 0; i != COUNT(sValidWithSpaceStrings); ++i)
	{
		if (!OOIsNumberLiteral(sValidWithSpaceStrings[i], YES))
		{
			FAIL(sValidWithSpaceStrings[i]);
		}
		if (OOIsNumberLiteral(sValidWithSpaceStrings[i], NO))
		{
			FAIL(sValidWithSpaceStrings[i]);
		}
	}
	
	for (i = 0; i != COUNT(sInvalidStrings); ++i)
	{
		if (OOIsNumberLiteral(sInvalidStrings[i], YES))
		{
			FAIL(sInvalidStrings[i]);
		}
	}
	
	if (!failed)  NSLog(@"All tests passed!");
	
    [pool drain];
    return 0;
}
