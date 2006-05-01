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

Intention: This is supposed to be a very simple class which deals with
sorting out the protocol details and getting values back -- and nothing
else. It is to be contained by a more complex class that has overall
control over the process. It essentially encapsulates the bits of libhttp
that we need (and can easily be replaced with an implementation that uses
the Mac OS X http stuff if required).
 
*/

#include <http.h>

// note to self: get more memory, install VMware Server and make a Windows
// test machine for builds
#ifndef WIN32
#include <signal.h>
#include <unistd.h>
#endif

#import "DOOFetch.h"

// libhttp signal handlers
static HTTP_Extra hExtra;
static void sigalarm_handler(int signum)
{
	signum = signum;
	/* Tell libhttp to give up */
	if(hExtra.Socket > 0)
	{
		fprintf( stderr, "Watchdog : canceling HTTP connection\n");
		close(hExtra.Socket);
	}
}

void sigalarm_handler_setup()
{
   struct sigaction sa;
   
   sigemptyset(&sa.sa_mask);
   sa.sa_flags=0;
   sa.sa_handler=&sigalarm_handler;
   sigaction(SIGALRM, &sa, NULL);
   alarm(HTTP_TIMEOUT);
}

@implementation DOOFetch

+ (NSString *) dictToPostString: (NSDictionary *)dict withVar: (NSString *)var
{
   NSMutableString *pstring=[[NSMutableString alloc] init];
   NSArray *keys=[dict allKeys];
   NSString *key;
   int i;
   if([keys count])
   {
      [pstring appendFormat: @"&%@=", var];
   }

   int count=[keys count];
   for(i = 0; i < count; i++)
   {
      key = [keys objectAtIndex: i];
     
      if(i < count-1)
      { 
         [pstring appendFormat: 
            @"%@:%@,", key, [dict objectForKey: key]];
      }
      else
      {
         [pstring appendFormat:
            @"%@:%@", key, [dict objectForKey: key]];
      }
   }
   return pstring;
}
   
- (id) initWithURL: (NSString *)url savePath: (NSString *)path
{
   baseurl=url;
   savePath=path;
}

- (void) importOXPVariables: (NSDictionary *)vars 
                OXPVersions: (NSDictionary *)vers
{
   OXPvars=vars;
   OXPversions=vers;
}

- (void) setPlayerData: (NSString *)guid credits:(int) credits 
                        kills: (int)kills
{
   playerGuid=guid;
   playerCredits=credits;
   playerKills=kills;
}

- (BOOL) requestOXPs
{
   HTTP_Response hResponse;
   NSMutableString *postdata=[NSMutableString stringWithFormat: COMMAND];

   memset(&hExtra, 0x00, sizeof(hExtra));

   // add the variables to the POST request
   [postdata appendString: 
      [DOOFetch dictToPostString: OXPvars withVar: @"vars"]];
   
   // add the OXP versions
   [postdata appendString:
      [DOOFetch dictToPostString: OXPversions withVar: @"oxps"]];

   // add player data
   [postdata appendFormat:
      @"&kills=%d&credits=%d&guid=%@", playerKills, playerCredits, playerGuid];

   NSLog(@"debug: Postdata contains: %@", postdata);
   hExtra.PostData=(char *)[postdata UTF8String];
   hExtra.PostLen=strlen(hExtra.PostData);

   // make the request. Will signal SIGALRM if the request times out.
   sigalarm_handler_setup();
   hResponse=http_request((char *)[baseurl UTF8String], &hExtra, 
                           kHMethodPost, HFLAG_NONE);

   // Complete; cancel alarm signal.
   alarm(0);
   
   // Debugging stuff - let us see in real time what we got back
   NSLog(@"debug: lSize: %ld iError: %d", hResponse.lSize, hResponse.iError);
   NSLog(@"debug: pError: %s", hResponse.pError);
   NSLog(@"debug: szHCode: %s", hResponse.szHCode);
   NSLog(@"debug: szHMsg: %s", hResponse.szHMsg);
   if(hResponse.lSize > 0 && hResponse.iError == 0)
   {
      // fd=1 = stderr
      NSLog(@"debug: DATA THAT CAME BACK:");
      write(1, hResponse.pData, (size_t)hResponse.lSize);
      NSLog(@"debug: End of data.");

      // cleanup
      if(hResponse.pData)
         free(hResponse.pData);
   }
   else
   {
      NSLog(@"debug: oops, server didn't send any data back");
      return NO;
   }
   return YES;
}

@end
