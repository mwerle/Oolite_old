#!/bin/sh
#
# This shell script simply makes a tarball of the current SVN extract,
# making sure only source and required files to build are put into the
# tarball (i.e. no .svn dirs, no oolite.app dir etc.)
#
rm -rf ~/oolite-snapshot
mkdir ~/oolite-snapshot
cp *.m *.c *.h *.png *.plist *.dat *.aiff GNU* README.TXT ~/oolite-snapshot
cd ~/
tar zcvf oolite-snapshot.tar.gz oolite-snapshot

