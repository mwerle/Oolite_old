I=/c/GNUstep/Local/include
L=/c/GNUstep/Local/lib

g++ -c -I${I} ptg.cpp
cp ptg.h ${I}/noise
cp ptg.o ${L}/noise
cd ${L}/noise
ar cru ../libnoise.a *.o
