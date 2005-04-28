#!/bin/sh
#
# This shell script simply makes a tarball of the current SVN extract,
# making sure only source and required files to build are put into the
# tarball (i.e. no .svn dirs, no oolite.app dir etc.)
#
rm -rf ~/oolite-snapshot
mkdir ~/oolite-snapshot
cp *.m *.c *.h GNU* README.TXT PORTING.TXT ~/oolite-snapshot

# we don't cp -r because then we'd get all the .svn stuff
# so do it a dir at a time and copy specific files
SRCDIR=Resources
RESDIR=~/oolite-snapshot/Resources
mkdir $RESDIR
mkdir $RESDIR/AIs
cp $SRCDIR/AIs/*.plist $RESDIR/AIs
mkdir $RESDIR/Config
cp $SRCDIR/Config/*.plist $RESDIR/Config
mkdir $RESDIR/Images
cp $SRCDIR/Images/*.png $RESDIR/Images
mkdir $RESDIR/Models
cp $SRCDIR/Models/*.dat $RESDIR/Models
mkdir $RESDIR/Music
# TODO: add music
mkdir $RESDIR/Sounds
cp $SRCDIR/Sounds/*.aiff $RESDIR/Sounds
mkdir $RESDIR/Textures
cp $SRCDIR/Textures/*.png $RESDIR/Textures
cp $SRCDIR/Info-Oolite.plist $RESDIR

cd ~/
tar zcvf oolite-snapshot.tar.gz oolite-snapshot

