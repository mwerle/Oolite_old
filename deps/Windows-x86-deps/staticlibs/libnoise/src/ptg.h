#ifndef PTG_H
#define PTG_H

#ifdef TEST_MAIN
// compiling as an exe
#define EXPORT
#else
#ifdef BUILD_DLL
// the dll exports
#define EXPORT __declspec(dllexport)
#else
// the exe imports
#define EXPORT __declspec(dllimport)
#endif
#endif

#ifdef __cplusplus
extern "C" {
#endif

struct planet_info {
	int seed;
	int use_oolite_colours; // 0 = no, 1 = yes
	int texture_width;
	int texture_height;
	float land_colour[3];
	float sea_colour[3];
};

unsigned char* generatePlanet(struct planet_info* info);
unsigned char* generateClouds(struct planet_info* info);

#ifdef __cplusplus
}
#endif

#endif
