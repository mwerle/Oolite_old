/*

GetMetadataForFile.m

Spotlight metadata importer for Oolite
Copyright (C) 2005 Jens Ayton

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

#include <CoreFoundation/CoreFoundation.h>
#include <CoreServices/CoreServices.h>
#include <Foundation/Foundation.h>
#include <stdarg.h>

#define kShipIDs			@"org_aegidian_oolite_shipids"
#define kShipClassNames		@"org_aegidian_oolite_shipclassnames"
#define kShipRoles			@"org_aegidian_oolite_shiproles"
#define kShipModels			@"org_aegidian_oolite_shipmodels"
#define kCombatRating		@"org_aegidian_oolite_combatrating"
#define kMinVersion			@"org_aegidian_oolite_minversion"

static BOOL GetMetadataForSaveFile(void* thisInterface, NSMutableDictionary *attributes, NSString *pathToFile);
static BOOL GetMetadataForOXP(void* thisInterface, NSMutableDictionary *attributes, NSString *pathToFile);

static id GetBundlePropertyList(NSString *inPListName);


/*
	NOTE: this prototype differs from the one declared in main.c (which is mostly unmodified
	Apple boilerplate code), but the types are entirely compatible.
*/
BOOL GetMetadataForFile(void* thisInterface, 
			   NSMutableDictionary *attributes, 
			   NSString *contentTypeUTI,
			   NSString *pathToFile)
{
	NSAutoreleasePool		*pool;
	BOOL					result = NO;
	
	pool = [[NSAutoreleasePool alloc] init];
	
	@try
	{
		if ([contentTypeUTI isEqual:@"org.aegidian.oolite.save"])
		{
			result = GetMetadataForSaveFile(thisInterface, attributes, pathToFile);
		}
		else if ([contentTypeUTI isEqual:@"org.aegidian.oolite.oxp"])
		{
			result = GetMetadataForOXP(thisInterface, attributes, pathToFile);
		}
	}
	@catch (id any) {}
	
	[pool release];
	return result;
}

static BOOL GetMetadataForSaveFile(void* thisInterface, NSMutableDictionary *attributes, NSString *pathToFile)
{
	BOOL					ok = NO;
	NSDictionary			*content;
	id						value;
	
	content = [NSDictionary dictionaryWithContentsOfFile:pathToFile];			
	if (nil != content)
	{
		ok = YES;
		
		value = [content objectForKey:@"player_name"];
		if (nil != value)  [attributes setObject:value forKey:(NSString *)kMDItemTitle];
		
		value = [content objectForKey:@"ship_desc"];
		if (nil != value)  [attributes setObject:[NSArray arrayWithObject:value] forKey:kShipIDs];
		
		value = [content objectForKey:@"ship_name"];
		if (nil != value)  [attributes setObject:[NSArray arrayWithObject:value] forKey:kShipClassNames];
		
		value = [content objectForKey:@"comm_log"];
		if (0 != [value count])  [attributes setObject:[value componentsJoinedByString:@"\n"] forKey:(NSString *)kMDItemTextContent];
		
		value = [content objectForKey:@"ship_kills"];
		if (nil != value)
		{
			NSArray					*ratings;
			int						ship_kills, rating = 0;
			int						kills[8] = { 0x0008,  0x0010,  0x0020,  0x0040,  0x0080,  0x0200,  0x0A00,  0x1900 };
			
			ratings = [GetBundlePropertyList(@"Values") objectForKey:@"ratings"];
			if (nil != ratings)
			{
				ship_kills = [value intValue];
				
				while ((rating < 8)&&(kills[rating] <= ship_kills))
				{
					rating ++;
				}
				
				[attributes setObject:[ratings objectAtIndex:rating] forKey:kCombatRating];
			}
		}
	}
	
	return ok;
}


static BOOL GetMetadataForOXP(void* thisInterface, NSMutableDictionary *attributes, NSString *pathToFile)
{
	BOOL					ok = NO;
	NSString				*subPath;
	NSDictionary			*content;
	NSEnumerator			*shipEnum;
	NSDictionary			*ship;
	NSString				*string;
	NSArray					*roleArray;
	NSMutableSet			*names, *models, *roles;
	CFIndex					count;
	
	subPath = [pathToFile stringByAppendingString:@"/requires.plist"];
	content = [NSDictionary dictionaryWithContentsOfFile:subPath];
	if (nil != content)
	{
		string = [content objectForKey:@"version"];
		if (nil != string) [attributes setObject:string forKey:kMinVersion];
	}
	
	subPath = [pathToFile stringByAppendingString:@"/Config/shipdata.plist"];
	content = [NSDictionary dictionaryWithContentsOfFile:subPath];
	count = [content count];
	
	if (0 != count)
	{
		names = [NSMutableSet setWithCapacity:count];
		models = [NSMutableSet setWithCapacity:count];
		roles = [NSMutableSet set];
		
		[attributes setObject:[content allKeys] forKey:kShipIDs];
		
		for (shipEnum = [content objectEnumerator]; ship = [shipEnum nextObject]; )
		{
			string = [ship objectForKey:@"name"];
			if (nil != string)  [names addObject:string];
			
			string = [ship objectForKey:@"model"];
			if (nil != string)  [models addObject:string];
			
			string = [ship objectForKey:@"roles"];
			if (nil != string)
			{
				roleArray = [string componentsSeparatedByString:@" "];
				[roles addObjectsFromArray:roleArray];
			}
		}
		
		if (0 != [names count]) [attributes setObject:[names allObjects] forKey:kShipClassNames];
		if (0 != [models count]) [attributes setObject:[models allObjects] forKey:kShipModels];
		if (0 != [roles count]) [attributes setObject:[roles allObjects] forKey:kShipRoles];
		
		ok = YES;
	}
	
	return ok;
}


static id GetBundlePropertyList(NSString *inPListName)
{
	NSBundle				*bundle;
	NSString				*path;
	NSData					*data;
	
	bundle = [NSBundle bundleWithIdentifier:@"org.aegidian.oolite.md-importer"];
	path = [bundle pathForResource:inPListName ofType:@"plist"];
	data = [NSData dataWithContentsOfFile:path];
	return [NSPropertyListSerialization propertyListFromData:data mutabilityOption:NSPropertyListImmutable format:NULL errorDescription:NULL];
}
