Oolite Binary Release
=====================

To run Oolite, you need the following pre-requisites:

- Your distro must support ALSA (Advanced Linux Sound Architecture).
ALSA is the mainstream 2.6.x sound implementation, so all modern
distros should support it. You may or may not be lucky with a 2.4.x
based system.

- You must have GNUstep installed. You don't have to run a GNUstep
desktop (I don't, I never have). I recommend using the latest
GNUstep from http://www.gnustep.org (if installing from source
it's best to use the latest version of GNUstep Startup which
has everything you need).
The OpenGL stuff I think is a fairly recent addition to GNUstep,
so even slightly-old binary packages might not have it. If you get
OpenGL-based wierdness, try building the latest GNUstep.

- Decent, working OpenGL.

I only have limited resources to test the builds. My test machines
are a 2.0 GHz Pentium 4 with a GeForce 4ti with 128MB RAM, and
an older Compaq laptop with a 733 MHz Pentium 3 and integrated
ATi Radeon Mobility. It runs fine on both machines with no graphics
glitches or other weirdness.

To start it
===========
Run:

openapp oolite

at the command line (or create a desktop shortcut that does it)

If it's borked
==============
Please report it in the oolite-linux forum. Please include screen
shots for graphics weirdness, and clear descriptions of sound
weirdness. Include any logs in the terminal window.

NOTE: "Validation failed!" messages are expected when processing the
XML plists (property lists). The property list is still getting loaded;
it's not the cause of any troubles you may be having.
There are also a couple of X-Windows errors on startup (this is almost
certainly why the splash screen doesn't show) - this doesn't affect
game play. It doesn't cause textures not to load, fonts not to display
or your dog to vomit on the carpet.

The oolite forums can be found here:

http://aegidean.org/bb

