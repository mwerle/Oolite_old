/*

oolite-class-test-Vector3D.js
 

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


this.name			= "oolite-class-test-Vector3D";
this.author			= "Jens Ayton";
this.copyright		= "© 2010 the Oolite team.";
this.description	= "Test cases for Vector3D.";
this.version		= "1.75";


this.startUp = function ()
{
	var testRig = worldScripts["oolite-script-test-rig"];
	var require = testRig.$require;
	
	testRig.$registerTest("Vector3D constructor", function ()
	{
		var basic = new Vector3D(1, 2, 3);
		require.instance("basic", basic, Vector3D);
		
		var noNew = Vector3D(1, 2, 3);
		require.instance("noNew", noNew, Vector3D);
		
		var fromArray = Vector3D([1, 2, 3]);
		require.instance("fromArray", fromArray, Vector3D);
		
		return true;
	});
	
	testRig.$registerTest("Vector3D properties", function ()
	{
		var v = new Vector3D(1, 2, 3);
		
		require.property(v, "v", "x", 1);
		require.property(v, "v", "y", 2);
		require.property(v, "v", "z", 3);
		
		v.x = 4;
		v.y = 5;
		v.z = 6;
		
		require.property(v, "v", "x", 4);
		require.property(v, "v", "y", 5);
		require.property(v, "v", "z", 6);
		
		return true;
	});
}
