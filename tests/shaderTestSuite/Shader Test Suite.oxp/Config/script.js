/*

oolite-shader-test-suite.js

Test suite for Oolite's default shader.


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


this.name			= "oolite-shader-test-suite";
this.version		= "0.3";
this.author			= "Jens Ayton";
this.copyright		= "© 2010 the Oolite team.";


this.startUp = function()
{
	delete this.startUp;
	try
	{
		var console = debugConsole;
	}
	catch (e)
	{
		log("shaderTest.error.consoleRequired", "The shader test suite requires the debug console to be active.");
		return;
	}
	
	if (debugConsole.shaderMode == "SHADERS_NOT_SUPPORTED")
	{
		log("shaderTest.error.shadersNotSupported", "The shader test suite cannot be used because shaders are not supported.");
		return;
	}
	
	
	this.testCount = 16;
	
	// User-callable initiation function.
	var scriptName = this.name;
	debugConsole.script.runShaderTestSuite = function ()
	{
		worldScripts[scriptName].runShaderTestSuite();
	}
	this.runShaderTestSuite = function ()
	{
		if (!player.ship.docked)
		{
			debugConsole.consoleMessage("command-error", "You must be docked to run the shader test suite.");
			return;
		}
		
		// Show instruction/confirmation screen.
		if (!Mission.runScreen({ title: "Shader test suite", messageKey: "oolite_shader_test_confirmation", choicesKey: "oolite_shader_test_confirmation_choices" }, this.startTest, this))
		{
			log("shaderTest.error.missionScreenFailed", "The shader test suite failed to run a mission screen.");
			return;
		}
	}
	
	
	// Confirmation screen result callback.
	this.startTest = function (resonse)
	{
		if (resonse != "A_CONTINUE")  return;
		
		this.originalShaderMode = debugConsole.shaderMode;
		this.originalDisplayFPS = debugConsole.displayFPS;
		this.originalDebugFlags = debugConsole.debugFlags;
		this.passID = 1;
		this.nextTestIndex = 1;
		
		this.shipLaunchedFromStation = function () { log("shaderTest.cancelled", "Shader test suite cancelled by exiting station."); this.performCleanUp(); }
		
		debugConsole.writeLogMarker();
		log("shaderTest.start", "Starting shader test suite " + this.version + " under Oolite " + oolite.versionString + " and " + debugConsole.platformDescription + " with OpenGL renderer \"" + debugConsole.glRendererString + "\", vendor \"" + debugConsole.glVendorString + "\".");
		
		this.runNextTest();
	}
	
	
	this.performCleanUp = function ()
	{
		debugConsole.shaderMode = this.originalShaderMode;
		debugConsole.displayFPS = this.originalDisplayFPS;
		debugConsole.debugFlags = this.originalDebugFlags;
		
		delete this.passID;
		delete this.nextTestIndex;
		delete this.originalShaderMode;
		delete this.originalDisplayFPS;
		delete this.originalDebugFlags;
		delete this.shipLaunchedFromStation;
	}
	
	
	this.runNextTest = function ()
	{
		var testIndex = this.nextTestIndex++;
		
		if (testIndex > this.testCount)
		{
			if (this.passID == 1)
			{
				// Switch to next pass (full shader mode).
				this.passID = 2;
				this.nextTestIndex = 2;
				testIndex = 1;
			}
			else
			{
				// Both passes have run, we're done.
				this.performCleanUp();
				var config =
				{
					title: "Shader test suite",
					message: "The test suite is complete.\n\n\n" +
					"Your OpenGL renderer information is:\n" +
					"Vendor: “" + debugConsole.glVendorString + "”\n" +
					"Renderer: “" + debugConsole.glRendererString + "”\n\n" +
					"This information can also be found in the Oolite log."
				};
				log("shaderTest.complete", "Shader test suite complete.");
				debugConsole.writeLogMarker();
				Mission.runScreen(config, function () {});
				return;
			}
		}
		
		// Create a dummy ship to extract its script_info.
		var modelName = "oolite_shader_test_suite_" + testIndex;
		var ship = system.addShips(modelName, 1, system.sun.position, 10000)[0];
		var testDesc = ship.scriptInfo["oolite_shader_test_suite_label"];
		ship.remove();
		
		// Ensure environment is what we need - each time in case user tries to be clever.
		debugConsole.shaderMode = this.passID == 1 ? "SHADERS_SIMPLE" : "SHADERS_FULL";
		debugConsole.displayFPS = true;
		debugConsole.debugFlags |= debugConsole.DEBUG_NO_SHADER_FALLBACK;
		
		// Actually run the test.
		var testLabel = (this.passID == 1 ? "simple" : "full") + "-" + testIndex;
		log("shaderTest.runTest", "Running test " + testLabel + " (" + testDesc + ").");
		
		var config =
		{
			model: modelName,
			title: "",
			message: "\n\n\n" + testLabel + "\n" + testDesc
		};
		if (!Mission.runScreen(config, this.runNextTest, this))
		{
			log("shaderTest.error.missionScreenFailed", "The shader test suite failed to run a mission screen.");
			this.performCleanUp();
			return;
		}
	}
	
	
	log("shaderTest.loaded", "Shader test OXP is installed. To run the shader test, type \"runShaderTestSuite()\" in the debug console.");
};
