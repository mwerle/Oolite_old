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
	
	function degToRad(value)
	{
		return Math.PI * value / 180;
	}
	
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
		
		require.property("v", v, "x", 1);
		require.property("v", v, "y", 2);
		require.property("v", v, "z", 3);
		
		v.x = 4;
		v.y = 5;
		v.z = 6;
		
		require.property("v", v, "x", 4);
		require.property("v", v, "y", 5);
		require.property("v", v, "z", 6);
		
		return true;
	});
	
	testRig.$registerTest("Vector3D.add", function ()
	{
		var v = new Vector3D(1, 2, 3);
		var u = new Vector3D(4, 5, 6);
		
		var sum = v.add(u);
		require.property("sum", sum, "x", 5);
		require.property("sum", sum, "y", 7);
		require.property("sum", sum, "z", 9);
		
		var sum2 = u.add(v);
		require.property("sum2", sum2, "x", 5);
		require.property("sum2", sum2, "y", 7);
		require.property("sum2", sum2, "z", 9);
		
		var sumCastFromArray = v.add([1, 1, 1]);
		require.property("sumCastFromArray", sumCastFromArray, "x", 2);
		require.property("sumCastFromArray", sumCastFromArray, "y", 3);
		require.property("sumCastFromArray", sumCastFromArray, "z", 4);
		
		return true;
	});
	
	testRig.$registerTest("Vector3D.subtract", function ()
	{
		var v = new Vector3D(1, 2, 3);
		var u = new Vector3D(4, 5, 6);
		
		var diff = v.subtract(u);
		require.property("diff", diff, "x", -3);
		require.property("diff", diff, "y", -3);
		require.property("diff", diff, "z", -3);
		
		var diff2 = u.subtract(v);
		require.property("diff2", diff2, "x", 3);
		require.property("diff2", diff2, "y", 3);
		require.property("diff2", diff2, "z", 3);
		
		var diffCastFromArray = v.subtract([1, 1, 1]);
		require.property("diffCastFromArray", diffCastFromArray, "x", 0);
		require.property("diffCastFromArray", diffCastFromArray, "y", 1);
		require.property("diffCastFromArray", diffCastFromArray, "z", 2);
		
		return true;
	});
	
	testRig.$registerTest("Vector3D.angleTo", function ()
	{
		var v = new Vector3D(0, 1, 0);
		
		var ninetyDegrees = new Vector3D(1, 0, 0);
		require.near("ninetyDegrees", ninetyDegrees, degToRad(90), 1e-6);
		
		var fortyfiveDegrees = new Vector3D(0, 100, 100);
		require.near("fortyfiveDegrees", fortyfiveDegrees, degToRad(45), 1e-6);
		
		var opposite = Vector3D(0, 0, 0).subtract(v).angleTo(v);
		require.near("opposite", opposite, Math.PI, 1e-6);
		
		return true;
	});
	
	testRig.$registerTest("Vector3D.cross", function ()
	{
		var v = new Vector3D(1, 0, 0);
		var u = new Vector3D(0, 1, 0);
		
		var cross = v.cross(u);
		require.propertyNear("cross", cross, "x", 0, 1e-6);
		require.propertyNear("cross", cross, "y", 0, 1e-6);
		require.propertyNear("cross", cross, "z", 1, 1e-6);
		
		return true;
	});
}
