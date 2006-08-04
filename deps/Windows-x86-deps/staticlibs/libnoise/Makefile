
CXXFLAGS = -ansi -O3 -fno-nonansi-builtins -fno-rtti -Wall
VPATH = src;src/model;src/module

OBJS = latlon.o noisegen.o cylinder.o line.o plane.o sphere.o abs.o add.o billow.o blend.o cache.o checkerboard.o clamp.o const.o curve.o cylinders.o displace.o exponent.o invert.o max.o min.o modulebase.o multiply.o perlin.o power.o ridgedmulti.o rotatepoint.o scalebias.o scalepoint.o select.o spheres.o terrace.o translatepoint.o turbulence.o voronoi.o noiseutils.o ptg.o

libnoise.a: $(OBJS)
	ar cru $@ $(OBJS)
	ranlib $@
	rm *.o

