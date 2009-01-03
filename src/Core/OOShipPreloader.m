/*

OOShipPreloader.h

Class to manage asynchronous preloading of ship meshes.
 

Oolite
Copyright (C) 2004-2009 Giles C Williams and contributors

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


This file may also be distributed under the MIT/X11 license:

Copyright (C) 2008-2009 Jens Ayton

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

*/

#import "OOShipPreloader.h"
#import "OOAsyncQueue.h"
#import "OOCPUInfo.h"
#import "OOCollectionExtractors.h"
#import "ResourceManager.h"
#import "OOPreloadModelLoadingController.h"
#import "NSThreadOOExtensions.h"


@interface OOShipPreloader (Private)

- (void) queueTask:(NSNumber *)threadNumber;
- (void) reportDiagnostics:(NSArray *)diagnostics;
- (void) killThreads;
- (void) updateDelegate;

@end


@implementation OOShipPreloader

- (id) initWithExpectedMeshCount:(OOUInteger)count
{
	if ((self = [super init]))
	{
		_uniquedEntries = [[NSMutableSet alloc] init];
		_badNames = [[NSMutableSet alloc] init];
		_workQueue = [[OOAsyncQueue alloc] init];
		_completionQueue = [[OOAsyncQueue alloc] init];
		
		// Set up threads
		_threadCount = MIN(OOCPUCount(), count);
		// For debugging:
		_threadCount = 4;
		OOUInteger i;
		for (i = 0; i < _threadCount; i++)
		{
			[NSThread detachNewThreadSelector:@selector(queueTask:) toTarget:self withObject:[NSNumber numberWithInt:i + 1]];
		}
		
		_totalCount = count;
	}
	
	return self;
}


- (void) setDelegate:(id)delegate
{
	// Delegates are not owned.
	_delegate = delegate;
}


- (void) dealloc
{
	[self killThreads];
	
	[_uniquedEntries release];
	[_badNames release];
	[_workQueue release];
	[_completionQueue release];
	
	[super dealloc];
}


- (void) preloadMeshNamed:(NSString *)name smoothed:(BOOL)smoothed
{
	NSString *key = [NSString stringWithFormat:@"%@ smooth:%@", name, smoothed ? @"YES" : @"NO"];
	if ([_uniquedEntries containsObject:key])
	{
		_doneCount++;
		[self updateDelegate];
		return;	// Avoid duplicate work
	}
	[_uniquedEntries addObject:key];
	
	// +[ResourceManager pathForFileNamed:inFolder:] is not reentrant
	NSString *path = [ResourceManager pathForFileNamed:name inFolder:@"Models"];
	
	[_workQueue enqueue:[NSDictionary dictionaryWithObjectsAndKeys:
						 @"load", @"message",
						 name, @"name",
						 path, @"path",
						 [NSNumber numberWithBool:smoothed], @"smoothed",
						 nil]];
	_inFlightCount++;
}


- (void) waitUntilDone
{
	NSDictionary			*message = nil;
	NSString				*messageType = nil;
	NSArray					*diagnostics = nil;
	
	while (_inFlightCount != 0)
	{
		message = [_completionQueue dequeue];
		_inFlightCount--;
		
		messageType = [message stringForKey:@"message"];
		diagnostics = [message arrayForKey:@"diagnostics"];
		
		if ([messageType isEqualToString:@"ok"])
		{
			++_doneCount;
			[self updateDelegate];
		}
		else if ([messageType isEqualToString:@"error"])
		{
			[_badNames addObject:[message stringForKey:@"name"]];
			
			++_doneCount;
			[self updateDelegate];
		}
		else if ([messageType isEqualToString:@"finished"] )
		{
			_threadCount--;
		}
		
		if (diagnostics != nil)
		{
			[self reportDiagnostics:diagnostics];
		}
	}
}


- (NSSet *) badMeshNames
{
	NSSet *result = nil;
	
	result = [[_badNames copy] autorelease];
	[_badNames removeAllObjects];
	
	return result;
}

@end


@implementation OOShipPreloader (Private)

- (void) queueTask:(NSNumber *)threadNumber
{
	NSAutoreleasePool		*rootPool, *pool = nil;
	NSDictionary			*message = nil;
	NSDictionary			*okMessage = nil;
	NSString				*messageType = nil;
	NSString				*name = nil;
	BOOL					die = NO;
	OOPreloadModelLoadingController *controller = nil;
	OOMesh					*mesh = nil;
	BOOL					failed;
	NSArray					*diagnostics = nil;
	
	rootPool = [[NSAutoreleasePool alloc] init];
	[NSThread ooSetCurrentThreadName:[NSString stringWithFormat:@"OOShipPreloader loader thread %@", threadNumber]];
	
	controller = [[[OOPreloadModelLoadingController alloc] init] autorelease];
	okMessage = [NSDictionary dictionaryWithObject:@"ok" forKey:@"message"];
	
	while (!die)
	{
		pool = [[NSAutoreleasePool alloc] init];
		
		if (_killFlag)
		{
			die = YES;
		}
		else
		{
			message = [_workQueue dequeue];
			messageType = [message objectForKey:@"message"];
			if ([messageType isEqualToString:@"load"])
			{
				name = [message stringForKey:@"name"];
				[controller startFileNamed:[message stringForKey:@"name"]
									  path:[message stringForKey:@"path"]
									smooth:[message boolForKey:@"smoothed"]];
				mesh = [[OOMesh alloc] initWithLoadingController:controller fileName:name];
				// Ideally we'de make the mesh generate and cache its octree,
				// but that's not thread-safe.
				failed = (mesh == nil) || [controller failed];
				[mesh release];
				
				diagnostics = [controller diagnostics];
				
				if (!failed)
				{
					if ([diagnostics count] == 0)
					{
						message = okMessage;
					}
					else
					{
						message = [NSDictionary dictionaryWithObjectsAndKeys:
								   @"ok", @"message",
								   diagnostics, @"diagnostics",
								   nil];
					}
				}
				else
				{
					message = [NSDictionary dictionaryWithObjectsAndKeys:
							   @"error", @"message",
							   diagnostics, @"diagnostics",
							   name, @"name",
							   nil];
				}
				[_completionQueue enqueue:message];
			}
			else if ([messageType isEqualToString:@"die"])
			{
				/*	This should never happen - _killFlag will be set and the message
					is only sent to wake the thread up to notice. Still, it's bad
					practice to ignore messages.
				*/
				die = YES;
			}
		}
		
		[pool release];
	}
	
	[_completionQueue enqueue:[NSDictionary dictionaryWithObject:@"finished" forKey:@"message"]];
	[rootPool release];
}


- (void) reportDiagnostics:(NSArray *)diagnostics
{
	/*	Log diagnostics collected in work thread.
		This is seralized so multiple diagnostics for one file are grouped together.
	*/
	
	NSEnumerator			*itemEnum = nil;
	NSArray					*item = nil;
	
	for (itemEnum = [diagnostics objectEnumerator]; (item = [itemEnum nextObject]); )
	{
		OOLogWithFunctionFileAndLine([item stringAtIndex:0], NULL, NULL, 0, @"%@", [item stringAtIndex:1]);
	}
}


- (void) killThreads
{
	OOUInteger				i;
	NSDictionary			*message = nil;
	
	// Ask threads to die
	_killFlag = YES;
	message = [NSDictionary dictionaryWithObject:@"die" forKey:@"message"];
	for (i = 0; i < _threadCount; i++)
	{
		[_workQueue enqueue:message];
	}
	
	// Wait for them to comply
	while (_threadCount != 0)
	{
		message = [_completionQueue dequeue];
		if ([[message objectForKey:@"message"] isEqualToString:@"finished"])  _threadCount--;
		// Ignore other messages
	}
}


- (void) updateDelegate
{
	[_delegate shipPreloader:self processedCount:_doneCount ofTotal:_totalCount];
}

@end
