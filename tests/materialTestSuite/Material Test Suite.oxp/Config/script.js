/*

oolite-material-test-suite.js

Test suite for Oolite's material model and default shader.


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


this.name			= "oolite-material-test-suite";
this.version		= "0.5";
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
		log("materialTest.error.consoleRequired", "The material test suite requires the debug console to be active.");
		return;
	}
	
	
	this.shadyTestCount = 16;
	this.nonShadyTestCount = 7;
	
	
	// User-callable initiation function.
	var scriptName = this.name;
	debugConsole.script.runMaterialTestSuite = function ()
	{
		worldScripts[scriptName].runMaterialTestSuite();
	}
	this.runMaterialTestSuite = function ()
	{
		if (!player.ship.docked)
		{
			debugConsole.consoleMessage("command-error", "You must be docked to run the material test suite.");
			return;
		}
		
		// Show instruction/confirmation screen.
		var substitutions = { shady_count :this.shadyTestCount, non_shady_count: this.nonShadyTestCount };
		substitutions.count_string = expandMissionText("oolite_material_test_count_" + debugConsole.maximumShaderMode, substitutions);
		var introText = expandMissionText("oolite_material_test_confirmation", substitutions);
		
		if (substitutions.count_string === null)
		{
			log("materialTest.error.unknownMode", "Shader test suite cannot run because maximum shader mode \"" + debugConsole.maximumShaderMode + "\" is not recognised.");
			return;
		}
		
		if (!Mission.runScreen({ title: "Shader test suite", message: introText, choicesKey: "oolite_material_test_confirmation_choices" }, this.startTest, this))
		{
			log("materialTest.error.missionScreenFailed", "The material test suite failed to run a mission screen.");
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
		
		this.shipLaunchedFromStation = function () { log("materialTest.cancelled", "Shader test suite cancelled by exiting station."); this.performCleanUp(); }
		
		var supportString;
		switch (debugConsole.maximumShaderMode)
		{
			case "SHADERS_NOT_SUPPORTED":
				supportString = "not supported";
				this.maxPassID = 1;
				break;
				
			case "SHADERS_SIMPLE":
				supportString = "supported in simple mode only";
				this.maxPassID = 2;
				break;
				
			case "SHADERS_FULL":
				supportString = "fully supported";
				this.maxPassID = 3;
				break;
				
			default:
				log("materialTest.error.unknownMode", "Shader test suite cannot run because maximum shader mode \"" + debugConsole.maximumShaderMode + "\" is not recognised.");
				this.performCleanUp();
				return;
		}
		
		debugConsole.writeLogMarker();
		log("materialTest.start", "Starting material test suite " + this.version + " under Oolite " + oolite.versionString + " and " + debugConsole.platformDescription + " with OpenGL renderer \"" + debugConsole.glRendererString + "\", vendor \"" + debugConsole.glVendorString + "\"; shaders are " + supportString + ".");
		
		this.runNextTest();
	}
	
	
	this.performCleanUp = function ()
	{
		debugConsole.shaderMode = this.originalShaderMode;
		debugConsole.displayFPS = this.originalDisplayFPS;
		debugConsole.debugFlags = this.originalDebugFlags;
		
		delete this.passID;
		delete this.maxPassID;
		delete this.nextTestIndex;
		delete this.originalShaderMode;
		delete this.originalDisplayFPS;
		delete this.originalDebugFlags;
		delete this.shipLaunchedFromStation;
	}
	
	
	this.settingsByPass =
	[
		{},
		{
			passName: "fixed-function",
			shaderMode: "SHADERS_OFF",
			maxIndex: this.nonShadyTestCount,
			rolePrefix: "oolite_non_shader_test_suite_"
		},
		{
			passName: "simple",
			shaderMode: "SHADERS_SIMPLE",
			maxIndex: this.shadyTestCount,
			rolePrefix: "oolite_shader_test_suite_"
		},
		{
			passName: "full",
			shaderMode: "SHADERS_FULL",
			maxIndex: this.shadyTestCount,
			rolePrefix: "oolite_shader_test_suite_"
		}
	];
	
	this.runNextTest = function ()
	{
		var testIndex = this.nextTestIndex++;
		
		if (testIndex > this.settingsByPass[this.passID].maxIndex)
		{
			if (this.passID < this.maxPassID)
			{
				// Switch to next pass.
				this.passID++;
				this.nextTestIndex = 2;
				testIndex = 1;
			}
			else
			{
				// All passes have run, we're done.
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
				log("materialTest.complete", "Shader test suite complete.");
				debugConsole.writeLogMarker();
				Mission.runScreen(config, function () {});
				return;
			}
		}
		
		var passData = this.settingsByPass[this.passID];
		
		// Create a dummy ship to extract its script_info.
		var modelName = passData.rolePrefix + testIndex;
		var ship = system.addShips(modelName, 1, system.sun.position, 10000)[0];
		var testDesc = ship.scriptInfo["oolite_material_test_suite_label"];
		ship.remove();
		
		// Ensure environment is what we need - each time in case user tries to be clever.
		debugConsole.shaderMode = passData.shaderMode;
		debugConsole.displayFPS = true;
		debugConsole.debugFlags |= debugConsole.DEBUG_NO_SHADER_FALLBACK | debugConsole.DEBUG_SHADER_VALIDATION;
		
		// Actually run the test.
		var passNames = ["", "fixed-function", "simple", "full"];
		var testLabel = passData.passName + ":" + testIndex;
		log("materialTest.runTest", "Running test " + testLabel + " (" + testDesc + ").");
		
		var config =
		{
			model: modelName,
			title: "",
			message: "\n\n\n" + testLabel + "\n" + testDesc
		};
		if (!Mission.runScreen(config, this.runNextTest, this))
		{
			log("materialTest.error.missionScreenFailed", "The material test suite failed to run a mission screen.");
			this.performCleanUp();
			return;
		}
	}
	
	
	log("materialTest.loaded", "Material test suite is installed. To run the material test, type \"runMaterialTestSuite()\" in the debug console.");
};
