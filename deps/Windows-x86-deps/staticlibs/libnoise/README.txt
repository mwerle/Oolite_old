This directory contains a copy of the libnoise sources modified to produce no warnings, plus the
bridge code used by Oolite to use the libnoise objects.

A Makefile is also included that can create libnoise.a. To make and install OOlite's libnoise:

1. Type "make"
2. Copy the libnoise and noiseutil headers somewhere appropriate.
3. Copy libnoise.a somewhere appropriate.

I use /c/GNUstep/Local/include for header files and /c/GNUstep/Local/lib for the .a file.

The mklib.sh script does all the above.
