cd oolite.app/Contents/Resources
rm -rf .svn
rm -rf AIs/.svn
rm -rf Config/.svn
rm -rf Images/.svn
rm -rf Models/.svn
rm -rf Music/.svn
rm -rf Sounds/.svn
rm -rf Textures/.svn
cd ../../..

rm -rf $HOME/oolite-installer
mkdir -p $HOME/oolite-installer
tar cvf ~/oolite-installer/oolite-app.tar oolite.app

cd SelfContainedInstaller
cp install README.TXT PLAYING.TXT oolite ~/oolite-installer
tar cvf ~/oolite-installer/oolite-deps.tar oolite-deps

cd ~/
tar zcvf oolite-x86-installer-`date +%Y%m%d`.tar.gz oolite-installer

