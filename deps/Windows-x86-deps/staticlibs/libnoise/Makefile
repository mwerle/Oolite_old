
CXXFLAGS = -ansi -O3 -fno-nonansi-builtins -fno-rtti -Wall
VPATH = src;src/model;src/module

OBJS = latlon.o noisegen.o cylinder.o line.o plane.o sphere.o abs.o add.o billow.o blend.o cache.o checkerboard.o clamp.o const.o curve.o cylinders.o displace.o exponent.o invert.o max.o min.o modulebase.o multiply.o perlin.o power.o ridgedmulti.o rotatepoint.o scalebias.o scalepoint.o select.o spheres.o terrace.o translatepoint.o turbulence.o voronoi.o noiseutils.o ptg.o
DLL_OBJS = latlon.o noisegen.o cylinder.o line.o plane.o sphere.o abs.o add.o billow.o blend.o cache.o checkerboard.o clamp.o const.o curve.o cylinders.o displace.o exponent.o invert.o max.o min.o modulebase.o multiply.o perlin.o power.o ridgedmulti.o rotatepoint.o scalebias.o scalepoint.o select.o spheres.o terrace.o translatepoint.o turbulence.o voronoi.o noiseutils.o

# This target makes a static library
libnoise.a: $(OBJS)
	ar cru $@ $(OBJS)
	ranlib $@
	rm *.o

# This target makes a DLL and a libnoise.a suitable for using that DLL. This is a very different
# libnoise.a to the one generated in the above target.
noise.dll: $(DLL_OBJS)
	gcc -shared -o noise.dll -Wl,--out-implib,libnoise.a $(DLL_OBJS) --strip-debug -lstdc++
