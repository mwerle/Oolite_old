#!/bin/sh
if [ ! $1 ]
then
   echo "Usage: makebinpkg.sh <releasename>"
   echo
   exit
fi

rm -rf $HOME/oolite-installer
mkdir -p $HOME/oolite-installer
tar cvf ~/oolite-installer/oolite-app.tar oolite.app --exclude .svn

cd SelfContainedInstaller
cp install oolite-update README.TXT PLAYING.TXT FAQ.TXT oolite ~/oolite-installer
tar cvf ~/oolite-installer/oolite-deps.tar oolite-deps --exclude .svn
echo $1 >~/oolite-installer/release.txt

cd ~/
tar zcvf oolite-x86-installer-$1.tar.gz oolite-installer

