Oolite Binary Release
=====================

To run Oolite, you need the following pre-requisites:

- Your distro must support SDL (Simple DirectMedia Layer), or if it
doesn't you need to install the SDL shared libaries. I would imagine
all desktop distros have SDL by now. Currently, SDL is only used for
sound and music. (Graphics and input will be moved to SDL eventually,
but that's a big job).

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

Dependencies
============
Requires:
GNUstep - Foundation and AppKit. (Get the GNUstep starter from
http://www.gnustep.org, or from your distro's packages). Sadly, RedHattish
types of distros don't have GNUstep packages, but it's easy to build from
source. Just make sure you 'up2date -i gcc-objc' first.

SDL - Most distros will have SDL by default. However...
SDL_gfx - Some distros don't have it by default. On a RedHattish or
Fedora-like system, 'up2date -i SDL_gfx'. If you want to build oolite
from source, also 'up2date -i SDL_gfx-devel'. RPMs are available 
at http://dag.wieers.com/packages/SDL_gfx/ if that gives you no joy.

Talking about it, reporting bugs etc.
=====================================

The oolite forums can be found here:

http://aegidean.org/bb

