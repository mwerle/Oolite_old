/*

oolite-script-test-rig.js

Driver for JavaScript tests.
 

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


this.name			= "oolite-script-test-rig";
this.author			= "Jens Ayton";
this.copyright		= "© 2010 the Oolite team.";
this.description	= "Driver for JavaScript coverage tests.";
this.version		= "1.75";


this.$tests = [];
this.$postLaunchTests = [];


// API for test implementation scripts.

this.$registerTest = function registerTest(name, test)
{
	$tests.push({ name: name, test: test });
}


this.$registerPostLaunchTest = function registerPostLaunchTest(name, test)
{
	$postLaunchTests.push({ name: name, test: test });
}


this.$require =
{
	// $require.defined(): require that value not undefined or null.
	defined: function requireDefined(name, value)
	{
		if (value === undefined || value === null)  throw "Expected " + name + " to have a value.";
	},
	
	// $require.instance(): require that value is an instance of proto.
	instance: function requireInstance(name, value, proto)
	{
		if (proto === undefined)  throw "Usage error: $require.instance proto parameter is undefined.";
		if (!(value instanceof proto))  throw "Expected " + name + " to be an instance of " + proto + ".";
	},
	
	// $require.value(): require an exact == match to a primitive value.
	value: function requireValue(name, actual, expected)
	{
		if (actual != expected)  throw "Expected " + name + " to be " + expected + ", got " + actual + ".";
	},
	
	// $require.near(): like value, but allows an error range. Intended for floating-point tests.
	near: function requireNear(name, actual, expected, epsilon)
	{
		if (Math.abs(actual - expected) > epsilon)  throw "Expected " + name + " to be within " + epsilon + " of " + expected + ", got " + actual;
	},
	
	// $require.property(): require that a property has a specific (exact) value.
	property: function requireProperty(targetName, target, propName, expected)
	{
		var actual = target[propName];
		this.value(targetName + "." + propName, actual, expected);
	//	if (actual != expected)  throw "Expected " + targetName + "." + propName + " to be " + expected + ", got " + actual;
	},
	
	// $require.propertyNear(): require that a property has a specific value, within epsilon.
	propertyNear: function requirePropertyNear(targetName, target, propName, expected, epsilon)
	{
		var actual = target[propName];
		this.near(targetName + "." + propName, actual, expected, epsilon);
//		if (Math.abs(actual - expected) > epsilon)  throw "Expected " + targetName + "." + propName + " to be within " + epsilon " of " + expected + ", got " + actual;
	}
}

// End of API



this.startUp = function startUp()
{
	if (global.consoleMessage === undefined)
	{
		this.consoleMessage = function(colorCode, message)  { log(message); }
	}
}


this.$runTest = function runTest(testInfo)
{
	try
	{
		var success = testInfo.test();
		if (success)
		{
			consoleMessage("command-result", "Pass: " + testInfo.name);
			return true;
		}
		else
		{
			consoleMessage("error", "FAIL: " + testInfo.name, 0, 4);
			return false;
		}
	}
	catch (e)
	{
		consoleMessage("error", "FAIL WITH EXCEPTION: " + testInfo.name + " -- " + e, 0, 4);
		return false;
	}
}


this.$runTestSeries = function runTestSeries(series)
{
	try
	{
		var i, count = series.length, failedCount = 0;
		
		for (i = 0; i < count; i++)
		{
			if (!$runTest(series[i]))  failedCount++;
		}
		
		if (failedCount)
		{
			consoleMessage("error", "***** " + failedCount + " of " + count + " tests FAILED", 0, 5);
		}
		else
		{
			consoleMessage("command-result", "All " + count + " tests passed.");
		}
	}
	catch (e)
	{
		consoleMessage("error", "EXCEPTION IN TEST RIG: " + e, 0, 21);
		throw e;
	}
}


global.ooRunTests = function ooRunTests()
{
	if (!player.ship.docked)
	{
		consoleMessage("command-error", "ooRunTests() must be called while docked.");
		return;
	}
	
	log("Running docked tests...");
	$runTestSeries($tests);
	
	if ($postLaunchTests.length != 0)
	{
		if (!this.shipLaunchedFromStation)
		{
			this.shipLaunchedFromStation = function ()
			{
				log("Running post-launch tests...");
				$runTestSeries($postLaunchTests);
				delete this.shipLaunchedFromStation;
			}
		}
		
		player.ship.launch();
	}
}
