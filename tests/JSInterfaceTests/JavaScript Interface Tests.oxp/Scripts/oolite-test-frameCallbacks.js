/*

oolite-test-frameCallbacks.js
 

Oolite
Copyright © 2004-2011 Giles C Williams and contributors

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


this.name			= "oolite-test-frameCallbacks";
this.author			= "Jens Ayton";
this.copyright		= "© 2011 the Oolite team.";
this.description	= "Test cases for addFrameCallback()/removeFrameCallback.";
this.version		= "1.75";


this.startUp = function ()
{
	"use strict";
	
	var testRig = worldScripts["oolite-script-test-rig"];
	var require = testRig.$require;
	
	testRig.$registerTest("Frame callbacks", function ()
	{
		const testTime = 2.5;
		
		var sum = 0;
		var fcb = addFrameCallback(function (delta)
		{
			sum += delta;
		});
		
		require(isValidFrameCallback(fcb), "addFrameCallback() should return a valid tracking ID.");
		
		var deferredRef = testRig.$deferResult(testTime * 2);
		
		var testTimer = new Timer(this, function ()
		{
			/*
				Use a second, zero-delay one-shot timer for final report,
				because frame callbacks fire after timers. (If we did the
				test in the first timer, we’d expect sum to be one frame
				less than testTime.)
			*/
			
			testTimer = new Timer(this, function ()
			{
				removeFrameCallback(fcb);
				
				/*
					Check that sum is within a reasonable slop of testTime.
					0.2 should work at framerates above 5.
				*/
				if (Math.abs(sum - testTime) < 0.2)
				{
					deferredRef.reportSuccess();
				}
				else
				{
					deferredRef.reportFailure("Expected sum of frame deltas over " + testTime + " seconds to be near " + testTime + ", got " + sum + ".");
				}
			}, 0);
		}, testTime);
	});
	
	testRig.$registerTest("Nested frame callbacks", function ()
	{
		var fcb1hitCount = 0;
		var fcb2hitCount = 0;
		var fcb2;
		
		var fcb1 = addFrameCallback(function (delta)
		{
			if (fcb1hitCount == 0)
			{
				/*
					The outer FCB will be called twice, because (regardless
					of order of execution) the inner one will be added the
					first time, but first fire on the second frame, when it
					will cause both FCBs to be removed after the FCB
					execution phase.
				*/
				
				fcb2 = addFrameCallback(function (delta)
				{
					removeFrameCallback(fcb1);
					removeFrameCallback(fcb2);
					fcb2hitCount++;
				});
			}
			fcb1hitCount++;
		});
		
		require(isValidFrameCallback(fcb1), "addFrameCallback() should return a valid tracking ID.");
		
		var deferredRef = testRig.$deferResult(2);
		
		var testTimer = new Timer(this, function ()
		{
			if (isValidFrameCallback(fcb1))  deferredRef.reportFailure("Frame callback 1 is still valid.");
			else if (isValidFrameCallback(fcb2))  deferredRef.reportFailure("Frame callback 2 is still valid.");
			if (fcb1hitCount != 2)  deferredRef.reportFailure("Frame callback 1 hit count should be 2, got " + fcb1hitCount + ".");
			if (fcb2hitCount != 1)  deferredRef.reportFailure("Frame callback 2 hit count should be 1, got " + fcb2hitCount + ".");
			deferredRef.reportSuccess();
		}, 1);
	});
}
