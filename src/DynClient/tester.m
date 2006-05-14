/* 
 * Tester: A simple main() to test the various parts of Dynamic Oolite
 */

#import <Foundation/Foundation.h>
#import "DOOFetch.h"
#import "DOOUnzip.h"

int main(int argc, char **argv)
{
   int i;
   NSAutoreleasePool *pool=[[NSAutoreleasePool alloc] init];
   /*
   NSMutableDictionary *massive=[[NSMutableDictionary alloc] init];
   for(i = 0; i < 9000; i++)
   {
      NSString *num=[NSString stringWithFormat: @"%d", i];
      NSString *akey=[NSString stringWithFormat: @"Variable%d", i];
      [massive setValue: num forKey: akey];
   }*/
   NSDictionary *massive=[NSDictionary dictionaryWithObjectsAndKeys:
      @"yes", @"net.alioth.test.foo", nil];
   NSDictionary *vers=[NSDictionary dictionaryWithObjectsAndKeys:
      @"42", @"net.alioth.test", nil];

   DOOFetch *fetcher=[[DOOFetch alloc] initWithURL: 
      [NSURL URLWithString: @"http://www.alioth.net/cgi-bin/dtest.pl"]
      savePath: @"."];
   [fetcher importOXPVariables: massive OXPVersions: vers];
   NSArray *downloaded=[fetcher requestOXPs];

   NSLog(@"Fetcher complete: rc=%@", downloaded);

   DOOUnzip *unzipper=[[DOOUnzip alloc] initWithSrcPath: @"."
                           destPath: @"unpack"];
   [unzipper setFileList: downloaded];
   [unzipper unpackFileList];
   
   [downloaded release];
   
   [pool release];
   exit(0);
}

