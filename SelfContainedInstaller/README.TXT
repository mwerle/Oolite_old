Oolite Binary Release
=====================

Firstly, to head off the inevitable question 'how do you make it go full
screen?', press F12!

To run Oolite, you need the following pre-requisites:

- A decent, working hardware accelerated OpenGL installation.

If you can play other games such as TuxRacer (which comes with many Linux
distros by default), or Enemy Territory or Doom3 at a reasonable frame
rate, you have that dependency satisfied.

If you have an nVidia graphics card or newer ATi graphics card, and have not
used any OpenGL applications yet, you may need to install the driver.
See the driver downloads page for your card manufacturer - both nVidia
and ATi provide Linux drivers for their hardware.

Other 3D hardware is often supported by open source drivers as part of
x.org/XFree86. Older ATi cards are supported by these drivers.

Now assuming you have that satisfied, you need to install Oolite-Linux.

You can either install it in your home directory as whatever user you're
logged in as now, or you can log in as root (or su to root) and install
it system-wide in /usr/local.

To install systemwide, type:

./install systemwide

To install in your home directory, type:

./install homedir

For a systemwide install, the dependencies package is copied to
/usr/local/oolite-deps, and the game itself is copied to
/usr/local/oolite.app. A script to run the game is copied to /usr/local/bin.
To run, just type 'oolite' in a Terminal or in the Run window (assuming
/usr/local/bin is in your path) - or type /usr/local/bin/oolite if it isn't.

For a home directory install, the dependencies are copied to oolite-deps
in your homedir, and the game to oolite.app. The oolite script is
copied to your home directory. To run, type ./oolite in your home directory.

You can also create a desktop shortcut icon to this script.

Things that get created
=======================
When you run oolite for the first time, wherever you installed it, a GNUstep
directory will be copied into your home directory. The GNUstep backend needs
this. Additionally, an oolite-saves directory is created when you save
a commander for the first time.

Saved games
===========
Saved games currently are all saved in oolite-saves in your home directory.
You can copy any existing .oolite-save files (for example, from a Macintosh)
into this directory, and they will appear in the 'Load Commander' screen
in the game.

What are the dependencies that are packaged?
============================================
So far, I've tested the dependencies on a fresh install of Ubuntu with
just the normal beginner's installation (i.e. accepting all the defaults
for the Ubuntu Linux install). It should work on any Linux distribution
of the same vintage of Ubuntu 5.04, right the way back to Fedora Core 2
(the dependencies were built on an FC2 workstation). An old libc can
scupper you; it won't run on RedHat 8 for instance because libc is just
too old. It will also run on Knoppix (if you have somewhere writeable
to install it). Please let me know what distro you're using and whether
it worked or not via the oolite-linux forum (see the link below under
'If it's borked').

The dependencies in the deps package are:

A very minimal GNUstep 0.10 - the shared libaries and a pared-down GNUstep
system tree. This was compiled from GNU startup 0.10.
SDL (Simple Directmedia Layer)
SDL_gfx
SDL_mixer
SDL_image
libtiff
libungif

You can download the source tarballs used to build these libraries from
ftp://ftp.alioth.net/oolite-depends-source.

I've not yet written a script to automate building these and copying the
required parts to the dependencies package; this was assembled by hand
(and since it will only rarely be updated, I probably won't bother either).
If you're constructing a package for a non-x86 or non-Linux platform, 
take a look in oolite-deps/lib for the libraries you'll need to copy there.
All of these dependencies I found straightforward to compile.

If it's borked
==============
Please report it in the oolite-linux forum. Please include screen
shots for graphics weirdness, and clear descriptions of sound
weirdness. Include any logs in the terminal window. If you launched Oolite
from an icon, you may need to start a Terminal and run it from there
so you can see the messages. The forum is here:

http://aegidian.org/bb/viewforum.php?f=9

NOTE: "Validation failed!" messages are expected when processing the
XML plists (property lists). The property list is still getting loaded;
it's not the cause of any troubles you may be having.

Talking about it, reporting bugs etc.
=====================================

The oolite forums can be found here:

http://aegidian.org/bb

Credits
=======
Original OS X game: Giles Williams
Linux port: David Taylor, Giles Williams and Dylan Smith

