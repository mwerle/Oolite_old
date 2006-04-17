#ifdef BUILD_DLL
// the dll exports
#define EXPORT __declspec(dllexport)
#else
// the exe imports
#define EXPORT __declspec(dllimport)
#endif

#ifdef __cplusplus
extern "C" {
#endif

// function to be imported/exported
EXPORT void *loadFont(const char *fontfile, int facesize);
EXPORT void unloadFont(void *font);
EXPORT void getBoundingBox(void *font, const unsigned short *str, float *lx, float *ly, float *tx, float *ty);
EXPORT void drawUnicodeString(void *font, double x, double y, double z, const unsigned short *str);

#ifdef __cplusplus
}
#endif
