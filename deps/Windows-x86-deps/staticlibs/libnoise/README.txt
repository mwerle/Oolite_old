The files in this folder must be used in conjunction with the libnoise source files.
The steps to create Oolite's version of libnoise (including the Obj-C to C++ bridging code) are:

1. Download libnoise source.
2. Compile libnoise .cpp files to object form using g++, including noiseutils.cpp.
3. Copy the libnoise and noiseutil headers somewhere appropriate.
4. Compile ptg.cpp to object form using g++.
5. Copy the ptg.h file to the same place as the libnoise headers.
6. Copy the libnoise, noiseutil, and ptg object files to a single directory.
7. Create libnoise.a with the command "ar cru libnoise.a *.o".
8. Copy libnoise.a somewhere appropriate.

I use /c/GNUstep/Local/include for header files and /c/GNUstep/Local/lib for the .a file.
