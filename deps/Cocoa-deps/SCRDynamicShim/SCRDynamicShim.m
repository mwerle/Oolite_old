/*

SCRDynamicShim.c

Implements SmartCrashReportsInstall interface by dynamically loading
SCRDynamicShim.dylib. This is required on PPC only because Oolite uses the
10.3 SDK but SmartCrashReportsInstall.o uses the 10.4 SDK.


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


This file may also be distributed under the MIT/X11 license:

Copyright (C) 2006 Jens Ayton

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

#if __ppc__ && OO_SMART_CRASH_REPORT_INSTALL

#import "SmartCrashReportsInstall.h"
#import <Carbon/Carbon.h>
#import "OOLogging.h"

#define DLOPEN_NO_WARN	// dlfcn is considered "legacy" in the 10.3 SDK, but undeprecated in the 10.4 SDK.
#import <dlfcn.h>


typedef Boolean (*SCR_CanInstallPtr)(Boolean* outOptionalAuthenticationWillBeRequired);
typedef OSStatus (*SCR_InstallPtr)(UInt32 inInstallFlags);

static BOOL				sAttemptedLoad = NO,
						sSuccessfulLoad = NO;

static SCR_CanInstallPtr	SCR_CanInstall;
static SCR_InstallPtr		SCR_Install;


static BOOL LoadSCR(void);


Boolean UnsanitySCR_CanInstall(Boolean* outOptionalAuthenticationWillBeRequired)
{
	if (!LoadSCR())  return NO;
	return SCR_CanInstall(outOptionalAuthenticationWillBeRequired);
}


OSStatus UnsanitySCR_Install(UInt32 inInstallFlags)
{
	if (!LoadSCR())  return kUnsanitySCR_Install_WillNotInstall;
	return SCR_Install(inInstallFlags);
}


static BOOL LoadSCR(void)
{
	long				sysVersion;
	OSStatus			err;
	NSString			*path = nil;
	void				*handle = NULL;
	
	if (!sAttemptedLoad)
	{
		sAttemptedLoad = YES;
		
		// Only load under Tiger.
		err = Gestalt(gestaltSystemVersion, &sysVersion);
		if (err == noErr && 0x1040 <= sysVersion)
		{
			path = [[NSBundle mainBundle] privateFrameworksPath];
			path = [path stringByAppendingPathComponent:@"SCRDynamicShim.dylib"];
			
			handle = dlopen([path fileSystemRepresentation], RTLD_NOW | RTLD_LOCAL);
			if (NULL != handle)
			{
				SCR_CanInstall = (SCR_CanInstallPtr)dlsym(handle, "UnsanitySCR_CanInstall");
				SCR_Install = (SCR_InstallPtr)dlsym(handle, "UnsanitySCR_Install");
				if (NULL != SCR_CanInstall && NULL != SCR_Install)
				{
					sSuccessfulLoad = YES;
				}
			}
		}
	}
	
	return sSuccessfulLoad;
}

#endif
