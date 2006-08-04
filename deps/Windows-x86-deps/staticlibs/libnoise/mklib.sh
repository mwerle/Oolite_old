set -x
I=/c/GNUstep/Local/include
L=/c/GNUstep/Local/lib

make
# I know, cp -R would have been good, but it doesn't seem to work on GNUstep for Windows
cd src
find . -name '*.h' -exec cp --parents -v {} ${I}/noise \;
cd ..
cp libnoise.a ${L}
rm libnoise.a
