/* 
 * Tester: A simple main() to test the various parts of Dynamic Oolite
 */

#import <Foundation/Foundation.h>
#import "DOOFetch.h"

int main(int argc, char **argv)
{
   NSAutoreleasePool *pool=[[NSAutoreleasePool alloc] init];
   NSDictionary *vars=[NSDictionary dictionaryWithObjectsAndKeys:
      @"baz", @"net.alioth.test.foo",
      @"bar", @"net.alioth.test.bar",
      @"yes", @"net.alioth.test.baz", nil];
   NSDictionary *vers=[NSDictionary dictionaryWithObjectsAndKeys:
      @"42", @"net.alioth.test", nil];
   BOOL rc;

   DOOFetch *fetcher=[[DOOFetch alloc] initWithURL: 
      @"http://www.alioth.net/cgi-bin/dtest.pl"
      savePath: @"."];
   [fetcher importOXPVariables: vars OXPVersions: vers];
   rc=[fetcher requestOXPs];
   NSLog(@"Fetcher complete: rc=%d", rc);
   
   [pool release];
   exit(0);
}

