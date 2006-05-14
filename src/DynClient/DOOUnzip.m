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

DOOUnzip.m - Created 2006-05-14: Dylan Smith
 
*/

#import <unzip.h>
#import "DOOUnzip.h"

@implementation DOOUnzip

- (id) initWithSrcPath: (NSString *)spath destPath: (NSString *)dpath
{
   srcPath=spath;
   destPath=dpath;
   return self;
}

- (void) setFileList: (NSArray *)list
{
   if(fileList)
   {
      [fileList release];
   }

   // take a copy - we may want to modify this
   fileList=[[NSMutableArray alloc] init];
   [fileList addObjectsFromArray: list];
}

- (void) addToFileList: (NSArray *)list
{
   if(!fileList) fileList=[[NSMutableArray alloc] init];
   [fileList addObjectsFromArray: list];
}

- (void) addFilesFromSrcPath
{
   if(!fileList) fileList=[[NSMutableArray alloc] init];
   NSFileManager *filemgr=[NSFileManager defaultManager];

   NSArray *dirents=[filemgr directoryContentsAtPath: srcPath];
   int i;
   for(i=0; i < [dirents count]; i++)
   {
      NSString *file=[dirents objectAtIndex: i];
      if([file hasSuffix: @".oxp.zip"])
      {
         [fileList addObject: [srcPath stringByAppendingPathComponent: file]];
      }
   }
}

- (NSArray *) unpackFileList
{
   if(!fileList)
      return nil;
   
   NSMutableArray *successful=[[NSMutableArray alloc] init];

   // TODO: This method will check signatures prior to unpacking.
   char **unzargv;
   int unzargc=UNZ_NUMARGS;

   unzargv=(char **)malloc(sizeof(char *) * UNZ_NUMARGS);
   unzargv[0]=UNZ_ARGV0;
   unzargv[1]=UNZ_ARGV1;
   unzargv[2]=UNZ_ARGV2;
   unzargv[3]=(char *)[destPath UTF8String];

   int i;
   for(i=0; i < [fileList count]; i++)
   {
      // TODO: Sig check.
      NSString *zipfile=[fileList objectAtIndex: i];
      unzargv[4]=(char *)[zipfile UTF8String];
      int rc=UzpMain(UNZ_NUMARGS, unzargv);
      if(!rc)
      {
         // success
         [successful addObject: zipfile];
      }
      else
      {
         NSLog(@"Unzip of %@ failed: rc=%d", zipfile, rc);
      }
   }
   free(unzargv);

   [fileList release];
   fileList=nil;
   return successful;
}

- (void) dealloc
{
   if(fileList) [fileList release];
   [super dealloc];
}
   
@end
