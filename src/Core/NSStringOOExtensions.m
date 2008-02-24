/*

NSStringOOExtensions.m

Oolite
Copyright (C) 2004-2008 Giles C Williams and contributors

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
MA 02110-1301, USA.

*/

#import "NSStringOOExtensions.h"


@implementation NSString (OOExtensions)

+ (id)stringWithContentsOfUnicodeFile:(NSString *)path
{
	id				result = nil;
	BOOL			OK = YES;
	NSData			*data = nil;
	const uint8_t	*bytes = NULL;
	size_t			length = 0;
	const uint8_t	*effectiveBytes = NULL;
	size_t			effectiveLength = 0;
	
	data = [[NSData alloc] initWithContentsOfFile:path];
	if (data == nil) OK = NO;
	
	if (OK)
	{
		length = [data length];
		bytes = [data bytes];
	}
	
	if (OK && 2 <= length && (length % sizeof(unichar)) == 0)
	{
		// Could be UTF-16
		unichar firstChar = bytes[0];
		firstChar = (firstChar << 8) | bytes[1];	// Endianism doesn't matter, because we test both orders of BOM.
		if (firstChar == 0xFFFE || firstChar == 0xFEFF)
		{
			// Consider it to be UTF-16.
			result = [NSString stringWithCharacters:(unichar *)(bytes + sizeof(unichar)) length:(length / sizeof(unichar)) - 1];
			if (result == nil) OK = NO;
		}
	}
	
	if (OK && result == nil)
	{
		// Not UTF-16. Try UTF-8.
		if (3 <= length && bytes[0] == 0xEF && bytes[1] == 0xBB && bytes[2] == 0xBF)
		{
			// File starts with UTF-8 BOM; skip it.
			effectiveBytes = bytes + 3;
			effectiveLength = length + 3;
		}
		else
		{
			effectiveBytes = bytes;
			effectiveLength = length;
		}
		
		// Attempt to interpret as UTF-8
		result = [[[NSString alloc] initWithBytes:effectiveBytes length:effectiveLength encoding:NSUTF8StringEncoding] autorelease];
	}
	
	if (OK && result == nil)
	{
		// Not UTF-16 or UTF-8. Use ISO-Latin-1 (which should work for any byte sequence).
		result = [[[NSString alloc] initWithBytes:effectiveBytes length:effectiveLength encoding:NSISOLatin1StringEncoding] autorelease];
	}
	
	[data release];
	return result;
}


+ (id)stringWithUTF16String:(const unichar *)chars
{
	size_t			length;
	const unichar	*end;
	
	if (chars == NULL) return nil;
	
	// Find length of string.
	end = chars;
	while (*end++) {}
	length = end - chars - 1;
	
	return [NSString stringWithCharacters:chars length:length];
}


- (NSData *)utf16DataWithBOM:(BOOL)includeByteOrderMark
{
	size_t			lengthInChars;
	size_t			lengthInBytes;
	unichar			*buffer = NULL;
	unichar			*characters = NULL;
	
	// Calculate sizes
	lengthInChars = [self length];
	lengthInBytes = lengthInChars * sizeof(unichar);
	if (includeByteOrderMark) lengthInBytes += sizeof(unichar);
	
	// Allocate buffer
	buffer = malloc(lengthInBytes);
	if (buffer == NULL) return nil;
	
	// write BOM (native-endian) if desired
	characters = buffer;
	if (includeByteOrderMark)
	{
		*characters++ = 0xFEFF;
	}
	
	// Get the contents
	[self getCharacters:characters];
	
	// NSData takes ownership of the buffer.
	return [NSData dataWithBytesNoCopy:buffer length:lengthInBytes freeWhenDone:YES];
}

@end
