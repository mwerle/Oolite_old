/*

oolite-class-test-Timer.js
 

Oolite
Copyright © 2004-2010 Giles C Williams and contributors

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


this.name			= "oolite-class-test-Timer";
this.author			= "Jens Ayton";
this.copyright		= "© 2010 the Oolite team.";
this.description	= "Test cases for Timer.";
this.version		= "1.75";


this.startUp = function ()
{
	var testRig = worldScripts["oolite-script-test-rig"];
	var require = testRig.$require;
	var testTimer;
	
	testRig.$registerTest("Timer constructor", function ()
	{
		var deferedRef = testRig.$deferResult();
		
		var hitCount = 0;
		testTimer = new Timer(this, function ()
		{
			if (hitCount++ == 3)
			{
				testTimer.stop();
				delete testTimer;
				
				deferedRef.reportSuccess();
			}
		}, 0.25, 0.3);
	});
	
	testRig.$registerTest("Timer properties", function ()
	{
		require.property("testTimer", testTimer, "isRunning", true);
		require.propertyNear("testTimer", testTimer, "interval", 0.3);
		
		var nextTime = testTimer.nextTime;
		require.near("nextTime", nextTime, clock.absoluteSeconds + 0.25);
	});
	
	testRig.$registerTest("Timer.stop", function ()
	{
		testTimer.stop();
		require.property("testTimer", testTimer, "isRunning", false);
	});
	
	testRig.$registerTest("Timer.start", function ()
	{
		testTimer.start();
		require.property("testTimer", testTimer, "isRunning", true);
	});
}
