/*
	OODATLexer.h
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

#import <Foundation/Foundation.h>
#import <stdio.h>
#import "OoliteDATTokens.h"
#import "vector.h"


@interface OODATLexer: NSObject
{
	int						_nextToken;
	NSString				*_fileName;
	FILE					*_file;
}

- (id)initWithPath:(NSString *)inPath;

- (int)nextToken:(NSString **)outToken;		// Provides the literal string value of the token
- (int)nextTokenDesc:(NSString **)outToken;	// Provides a description of the token
- (void)skipLineBreaks;						// Skips zero or more EOL tokens
- (BOOL)passAtLeastOneLineBreak;			// Skips one or more EOL tokens

- (int)lineCount;

- (BOOL)passRequiredToken:(int)inToken;

- (BOOL)readInteger:(unsigned *)outInt;
- (BOOL)readReal:(float *)outReal;
- (BOOL)readVector:(Vector *)outVector;		// Three floats in a row
- (BOOL)readString:(NSString **)outString;

@end
