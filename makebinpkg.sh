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
tar zcvf ~/oolite-x86-binary-`date +%Y%m%d`.tar.gz oolite.app README-BINARY.TXT
