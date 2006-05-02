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

#import "DOOFetch.h"

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
   
- (id) initWithURL: (NSURL *)url savePath: (NSString *)path
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

- (NSArray *) requestOXPs
{
   HTTP_Response hResponse;
   NSMutableArray *downloaded=[[NSMutableArray alloc] init];
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

   //NSLog(@"debug: Postdata contains: %@", postdata);
   hExtra.PostData=(char *)[postdata UTF8String];
   hExtra.PostLen=strlen(hExtra.PostData);

   // Make the request.
   hResponse=http_request((char *)[[baseurl absoluteString] UTF8String], 
                        &hExtra, kHMethodPost, HFLAG_NONE);

   // Debugging stuff - let us see in real time what we got back
   //NSLog(@"debug: lSize: %ld iError: %d", hResponse.lSize, hResponse.iError);
   //NSLog(@"debug: pError: %s", hResponse.pError);
   //NSLog(@"debug: szHCode: %s", hResponse.szHCode);
   //NSLog(@"debug: szHMsg: %s", hResponse.szHMsg);
   if(hResponse.lSize > 0 && !hResponse.iError && 
         !strcmp(hResponse.szHCode, "200"))
   {
      NSString *ret=[NSString stringWithFormat: @"%s", hResponse.pData];
      if(hResponse.pData)
      {
         NSArray *fetchList=[ret componentsSeparatedByString: @","];
         free(hResponse.pData);

         NSLog(@"debug: Fetchlist: %@", fetchList);      
         if(fetchList)
         {
            int i;
            for(i=0; i < [fetchList count]; i++)
            {
               // simple way of validating the strings we got back - put
               // them in an NSURL.
               NSString *urlstring=[fetchList objectAtIndex: i];
               NSURL *url=[NSURL URLWithString: urlstring];
               if(url)
               {
                  NSString *pathToOXP=[self downloadOXP: url];
                  if(pathToOXP)
                  {
                     [downloaded addObject: pathToOXP];
                  }
               }
               else
                  NSLog(@"%@ could not be turned into an URL", urlstring);

            }
         }
      }
   }
   else
   {
      NSLog(@"debug: oops, server didn't send any data back");
   }

   return downloaded;
}

- (NSString *) downloadOXP: (NSURL *)url
{
   NSString *signfile=
         [NSString stringWithFormat: @"%@.sign", [url absoluteString]];

   NSString *filename=[[url path] lastPathComponent];
   if(![filename hasSuffix: @".oxp.zip"])
   {
      NSLog(@"%@ is apparently not an OXP", [url path]);
      return nil;
   }

   HTTP_Response hResponse=http_request
      ((char *)[[url absoluteString] UTF8String], NULL,
               kHMethodGet, HFLAG_NONE);
   NSLog(@"debug: Tried to get %@", url);
   NSLog(@"debug: lsize=%ld iError=%d", 
         hResponse.lSize, hResponse.iError);
   NSLog(@"debug: pError: %s", hResponse.pError);
   NSLog(@"debug: szHError: %s", hResponse.szHCode);
   NSLog(@"debug: szHMsg: %s", hResponse.szHMsg);
   
   if(hResponse.lSize > 0 && !hResponse.iError && hResponse.pData
         && !strcmp(hResponse.szHCode, "200"))
   {
      NSData *oxp=[NSData dataWithBytes: hResponse.pData 
                                 length: hResponse.lSize];
      NSString *destination=[savePath stringByAppendingPathComponent: filename];
      BOOL rc=[[NSFileManager defaultManager]
                  createFileAtPath: destination
                  contents: oxp
                  attributes: nil];
      if(!rc)
      {
         NSLog(@"Unable to write %@", destination);
      }
      free(hResponse.pData);
      return destination;
   }
   return nil;
}

@end
