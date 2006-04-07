/*
	OODATLexer.m
	Adapted from Dry Dock for Oolite
	
	Copyright © 2006 Jens Ayton
	
	This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike License.
	To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/2.0/
	or send a letter to Creative Commons, 559 Nathan Abbott Way, Stanford, California 94305, USA.
	
	You are free:
	
	•	to copy, distribute, display, and perform the work
	•	to make derivative works
	
	Under the following conditions:
	
	•	Attribution. You must give the original author credit.
	
	•	Share Alike. If you alter, transform, or build upon this work,
	you may distribute the resulting work only under a license identical to this one.
	
	For any reuse or distribution, you must make clear to others the license terms of this work.
	
	Any of these conditions can be waived if you get permission from the copyright holder.
	
	Your fair use and other rights are in no way affected by the above.
*/

#define ENABLE_TRACE 0

#import "OODATLexer.h"
#import "OOErrorDescription.h"

OODATLexer			*sOODATLexerActive = nil;

static NSString *DescribeTokenType(int inToken);

#if ENABLE_TRACE
static const char *TokenString(int inToken);
#endif


@interface OODATLexer (Private)

- (void)advance;
- (NSString *)describeToken;

@end


@implementation OODATLexer


- (id)initWithPath:(NSString *)inPath
{
	if (nil != sOODATLexerActive) [NSException raise:NSInternalInconsistencyException format:@"Only one OODATLexer may be active at a time."];
	
	self = [super init];
	if (nil != self)
	{
		_fileName = [[inPath lastPathComponent] retain];
		_file = fopen([inPath fileSystemRepresentation], "rb");
		if (NULL != _file)
		{
			OoliteDAT_SetInputFile(_file);
			[self advance];
			sOODATLexerActive = self;
		}
		else
		{
			NSLog(@"DAT lexer: failed to open file (errno = %@)", ErrnoAsNSString());
			[self release];
			self = nil;
		}
	}
	
	return self;
}


- (void)dealloc
{
	[_fileName release];
	if (NULL != _file) fclose(_file);
	if (sOODATLexerActive == self) sOODATLexerActive = nil;
	
	[super dealloc];
}


- (void)advance
{
	#if ENABLE_TRACE
	NSLog(@"  DAT lexer: got token %s (%@).", TokenString(_nextToken), [self describeToken]);
	#endif
	
	_nextToken = OoliteDAT_yylex();
}


- (int)nextToken:(NSString **)outToken
{
	int result = _nextToken;
	if (NULL != outToken) *outToken = [NSString stringWithUTF8String:OoliteDAT_yytext];
	[self advance];
	return result;
}


- (int)nextTokenDesc:(NSString **)outToken
{
	int result = _nextToken;
	if (NULL != outToken) *outToken = [self describeToken];
	[self advance];
	return result;
}


- (int)lineCount
{
	return OoliteDAT_LineNumber();
}


- (void)skipLineBreaks
{
	while (kOoliteDatToken_EOL == _nextToken) [self advance];
}


- (BOOL)passAtLeastOneLineBreak
{
	if (kOoliteDatToken_EOL != _nextToken)
	{
		NSLog(@"DAT lexer: Parse error in %@ (line %u): expected %@, got %@", [_fileName lastPathComponent], OoliteDAT_LineNumber(), @"end of line", [self describeToken]);
		return NO;
	}
	do
	{
		[self advance];
	} while (kOoliteDatToken_EOL == _nextToken);
	return YES;
}


- (BOOL)passRequiredToken:(int)inToken
{
	if (inToken == _nextToken)
	{
		[self advance];
		return YES;
	}
	else
	{
		NSLog(@"DAT lexer: Parse error in %@ (line %u): expected %@, got %@", [_fileName lastPathComponent], OoliteDAT_LineNumber(), DescribeTokenType(inToken), [self describeToken]);
		return NO;
	}
}


- (BOOL)readInteger:(unsigned *)outInt
{
	if (kOoliteDatToken_INTEGER == _nextToken)
	{
		// Note that the lexer only recognises unsigned integers
		if (NULL != outInt) *outInt = atoi(OoliteDAT_yytext);
		[self advance];
		return YES;
	}
	else
	{
		if (NULL != outInt) *outInt = 0;
		NSLog(@"DAT lexer: Parse error in %@ (line %u): expected %@, got %@", [_fileName lastPathComponent], OoliteDAT_LineNumber(), @"integer", [self describeToken]);
		return NO;
	}
}


- (BOOL)readReal:(float *)outReal
{
	if (kOoliteDatToken_REAL == _nextToken || kOoliteDatToken_INTEGER == _nextToken)
	{
		if (NULL != outReal) *outReal = atof(OoliteDAT_yytext);
		[self advance];
		return YES;
	}
	else
	{
		if (NULL != outReal) *outReal = 0.0;
		NSLog(@"DAT lexer: Parse error in %@ (line %u): expected %@, got %@", [_fileName lastPathComponent], OoliteDAT_LineNumber(), @"number", [self describeToken]);
		return NO;
	}
}


- (BOOL)readVector:(Vector *)outVector
{
	Vector				placeholder;
	
	// So we can skip vectors… not actually used, but good practice for robustness.
	if (NULL == outVector) outVector = &placeholder;
	
	return [self readReal:&outVector->x] && [self readReal:&outVector->y] && [self readReal:&outVector->z];
}


- (BOOL)readString:(NSString **)outString
{
	if (kOoliteDatToken_NVERTS <= _nextToken && _nextToken <= kOoliteDatToken_STRING)
	{
		if (NULL != outString) *outString = [NSString stringWithUTF8String:OoliteDAT_yytext];
		[self advance];
		return YES;
	}
	else
	{
		if (NULL != outString) *outString = nil;
		NSLog(@"DAT lexer: Parse error in %@ (line %u): expected %@, got %@", [_fileName lastPathComponent], OoliteDAT_LineNumber(), @"string", [self describeToken]);
		return NO;
	}
}


- (NSString *)describeToken
{
	NSString		*stringToQuote = nil;
	
	switch (_nextToken)
	{
		case kOoliteDatToken_EOF:
			return NSLocalizedString(@"end of file", NULL);
		
		case kOoliteDatToken_EOL:
			return NSLocalizedString(@"end of line", NULL);
		
		case kOoliteDatToken_VERTEX_SECTION:
			stringToQuote = @"VERTEX";
			break;
		
		case kOoliteDatToken_FACES_SECTION:
			stringToQuote = @"FACES";
			break;
		
		case kOoliteDatToken_TEXTURES_SECTION:
			stringToQuote = @"TEXTURES";
			break;
		
		case kOoliteDatToken_END_SECTION:
			stringToQuote = @"END";
			break;
		
		case kOoliteDatToken_NVERTS:
			stringToQuote = @"NVERTS";
			break;
		
		case kOoliteDatToken_NFACES:
			stringToQuote = @"NFACES";
			break;
		
		default:
			stringToQuote = [NSString stringWithUTF8String:OoliteDAT_yytext];
	}
	
	if (nil == stringToQuote) stringToQuote = @"";
	else if (100 < [stringToQuote length])
	{
		stringToQuote = [NSString stringWithFormat:NSLocalizedString(@"%@...", NULL), [stringToQuote substringToIndex:100]];
	}
	
	return stringToQuote;//[NSString stringWithFormat:NSLocalizedString(@"\"%@\"", NULL), stringToQuote];
}


- (NSString *)description
{
	return [NSString stringWithFormat:@"<%s %p>{file = %p, next token = %@}", object_getClassName(self), self, _file, [self describeToken]];
}

@end


static NSString *DescribeTokenType(int inToken)
{
	switch (inToken)
	{
		case kOoliteDatToken_EOF:
			return @"end of file";
		
		case kOoliteDatToken_EOL:
			return @"end of line";
		
		case kOoliteDatToken_VERTEX_SECTION:
			return @"\"VERTEX\"";
		
		case kOoliteDatToken_FACES_SECTION:
			return @"\"FACES\"";
		
		case kOoliteDatToken_TEXTURES_SECTION:
			return @"\"TEXTURES\"";
		
		case kOoliteDatToken_END_SECTION:
			return @"\"END\"";
		
		case kOoliteDatToken_NVERTS:
			return @"\"NVERTS\"";
		
		case kOoliteDatToken_NFACES:
			return @"\"NFACES\"";
		
		case kOoliteDatToken_INTEGER:
			return @"integer";
		
		case kOoliteDatToken_REAL:
			return @"number";
		
		case kOoliteDatToken_STRING:
			return @"string";
		
		default: return [NSString stringWithFormat:@"unknown token (%i)", inToken];
	}
}


#if ENABLE_TRACE

static const char *TokenString(int inToken)
{
	#define CASE(foo) case kOoliteDatToken_ ## foo: return #foo;
	
	switch (inToken)
	{
		CASE(EOF);
		CASE(EOL);
		CASE(VERTEX_SECTION);
		CASE(FACES_SECTION);
		CASE(TEXTURES_SECTION);
		CASE(END_SECTION);
		CASE(NVERTS);
		CASE(NFACES);
		CASE(INTEGER);
		CASE(REAL);
		CASE(STRING);
		
		default: return "??";
	}
	
	#undef CASE
}

#endif
