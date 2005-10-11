Oolite Binary Release
=====================

Important!
First up: if this is the first time you've run Oolite, here's some things
that will get you out of any video/OpenGL trouble and you need to know.

Keyboard shortcut F12 toggles full screen/windowed mode.
Keyboard shortcut F11 and Shift-F11 changes resolution.

(The F2 menu has the list of resolutions, and will save the mode you select
there to your user defaults for Oolite).

Some older OpenGL cards can't hack Oolite in higher resolutions and 
often results in text not rendering or rendering as blocks. 
Try a lower screen resolution if you have problems. Most newer cards 
(tested with nVidia GeForce 4ti circa 2003, ATi Radeon Mobility circa 
2000, Intel integrated video circa 2003) work just fine in all supported 
resolutions. 

Updating to new versions
========================
Now you have installed oolite, you can update it by running the
oolite-update script that is installed either in your homedir or in
/usr/bin depending on the type of installation you did. Running
this updater will be considerably faster than downloading a new package.
It uses rsync, and so can update from any version to any later
version - you don't need to have the immediately previous release
to update to a given package. When it completes, it will tell you
what version it was when it started, and what version you now have.

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
However, if you decide to install add ons, make sure if you buy an
add on ship you don't remove it, because your save game will stop working
if the ship it's based on doesn't exist!

Adding AddOns
=============
There's a whole heap of game add ons - missions, ships etc - on Oosat
http://capnhack.com/hosting/oolite/Oolite/OoSat.html
These are called 'OXPs'. Unpack them inside the AddOns directory (either
/usr/lib/Oolite/AddOns or in ~/.local/lib/Oolite/AddOns, depending on 
whether you chose to install system wide or in your home directory)

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

...and of course the GNUstep project and the SDL, SDL_mixer and SDL_gfx
people, without which the Linux and Win32 ports would not have been
possible.

