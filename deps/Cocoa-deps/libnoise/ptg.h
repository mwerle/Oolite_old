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

unsigned char* generatePlanet(int a, int b, int c, int d, int e, int f);
unsigned char* generateClouds(int a, int b, int c, int d, int e, int f);

#ifdef __cplusplus
}
#endif
