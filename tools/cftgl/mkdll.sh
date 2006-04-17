g++ textutil.cpp -c -DBUILD_DLL `freetype-config --cflags` -I$GNUSTEP_LOCAL_ROOT/include/FTGL
g++ -shared -o cftgl.dll -Wl,--out-implib,libcftgl.a textutil.o -L$GNUSTEP_LOCAL_ROOT/lib -lftgl -lglu32 -lopengl32 -lmingw32 `freetype-config --libs` #-lmpr -lm
cp cftgl.dll $GNUSTEP_LOCAL_ROOT/bin
cp libcftgl.a $GNUSTEP_LOCAL_ROOT/lib
cp cftgl.h $GNUSTEP_LOCAL_ROOT/include
