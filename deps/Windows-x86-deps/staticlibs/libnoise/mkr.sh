g++ -c -I../../include -I../../include/SDL -I/c/GNUstep/System/Library/Headers prender.m
g++ prender.o -Lc:/GNUstep/Local/lib -lmingw32 -lnoise -lglu32 -lopengl32 -lSDLmain -lSDL -lSDL_image
