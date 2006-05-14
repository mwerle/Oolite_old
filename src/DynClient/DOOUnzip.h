#ifndef DOOUNZIP_H
#define DOOUNZIP_H
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

DOOFetch.h - Created 2006-05-14: Dylan Smith
 
*/

#define UNZ_ARGV0 "unzip"
#define UNZ_ARGV1 "-o"
#define UNZ_ARGV2 "-d"
#define UNZ_NUMARGS 5   // 'unzip -o -d <dest> <src>'

#import <Foundation/Foundation.h>

@interface DOOUnzip : NSObject
{
   @protected
      NSMutableArray *fileList;
      NSString *srcPath;
      NSString *destPath;
}

- (id) initWithSrcPath: (NSString *)spath destPath: (NSString *)dpath;

// setFileList and unpackFileList are separate so that the file list
// can be set at any time, but the (CPU and disk) intensive task of unpacking
// can be left until an appropriate time where it won't impact frame rates.
- (void) setFileList: (NSArray *)list;
- (void) addToFileList: (NSArray *)list;
- (void) addFilesFromSrcPath;
- (NSArray *) unpackFileList;

- (void) dealloc;

@end
#endif

