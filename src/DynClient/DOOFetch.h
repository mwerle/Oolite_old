#ifndef DOOFETCH_H
#define DOOFETCH_H
/*
 *
 *  Oolite
 *
 *  Copyright (c) 2004 for aegidian.org. Some rights reserved.
 *

Oolite Copyright (c) 2004, Giles C Williams

This work is licensed under the Creative Commons Attribution-NonCommercial
ShareAlike License.

To view a copy of this license, visit 
http://creativecommons.org/licenses/by-nc-sa/2.0/

or send a letter to Creative Commons, 559 Nathan Abbott Way, 
Stanford, California 94305, USA.

You are free:
•	to copy, distribute, display, and perform the work
•	to make derivative works

Under the following conditions:
•	Attribution. You must give the original author credit.
•	Noncommercial. You may not use this work for commercial purposes.
•	Share Alike. If you alter, transform, or build upon this work,
you may distribute the resulting work only under a license identical 
to this one.

For any reuse or distribution, you must make clear to others the license 
terms of this work. Any of these conditions can be waived if you get 
permission from the copyright holder.

Your fair use and other rights are in no way affected by the above.

 * This file is provided AS IS with no warranties of any kind.  The author
 * shall have no liability with respect to the infringement of copyrights,
 * trade secrets or any patents by this file or any part thereof.  In no
 * event will the author be liable for any lost revenue or profits or
 * other special, indirect and consequential damages.

DOOFetch.h - Created 2006-05-01: Dylan Smith
 
*/

// Definitions.
#define HTTP_TIMEOUT 30 /* seconds */
#define COMMAND      @"cmd=requestoxp"

#include <http.h>
#import <Foundation/Foundation.h>

@class PlayerEntity;

@interface DOOFetch : NSObject
{
   @protected
      HTTP_Extra hExtra;
      NSURL *baseurl;
      NSString *savePath;
      
      NSDictionary *OXPvars;
      NSDictionary *OXPversions;

      int playerCredits;
      int playerKills;
      NSString *playerGuid;

}

+ (NSString *) dictToPostString: (NSDictionary *)dict withVar: (NSString *)var;
- (id) initWithURL: (NSURL *)url savePath: (NSString *)path;

- (void) setPlayerData: (NSString *)guid credits: (int)credits
                        kills: (int)kills;
- (void) importOXPVariables: (NSDictionary *)vars 
                OXPVersions: (NSDictionary *)vers;

- (NSArray *) requestOXPs;

// Used only internally.
- (NSString *) downloadOXP: (NSURL *)url;

@end

#endif

