#import "GL/gl.h"

#include <stdio.h>

#include "FTGLExtrdFont.h"
#include "FTGLOutlineFont.h"
#include "FTGLPolygonFont.h"
#include "FTGLTextureFont.h"
#include "FTGLPixmapFont.h"
#include "FTGLBitmapFont.h"

#include "cftgl.h"

FTFont *zLoadFont(const char *fontfile, int facesize);
void zUnloadFont(FTFont *font);
void zGetBoundingBox(FTFont *font, const wchar_t *str, float *lx, float *ly, float *tx, float *ty);
void zDrawString(FTFont *font, double x, double y, double z, const wchar_t *str);

extern "C" {

EXPORT void *loadFont(const char *fontfile, int facesize) {
	void *font = zLoadFont(fontfile, facesize);
	fprintf(stderr, "loadFont: font = %08x\n", font);
	return font;
}

EXPORT void unloadFont(void *font) {
    zUnloadFont((FTFont *)font);
}

EXPORT void getBoundingBox(void *font, const unsigned short *str, float *lx, float *ly, float *tx, float *ty) {
	zGetBoundingBox((FTFont *)font, (const wchar_t *)str, lx, ly, tx, ty);
}

EXPORT void drawUnicodeString(void *font, double x, double y, double z, const unsigned short *str) {
	zDrawString((FTFont *)font, x, y, z, (const wchar_t *)str);
}

EXPORT void printXXX(const char *text) {
	printf("%s\b", text);
}

} // extern "C"

FTFont *zLoadFont(const char *fontfile, int facesize) {
	FTFont *font = new FTGLTextureFont(fontfile);
	if( !font->FaceSize(facesize))
	{
		fprintf(stderr, "loadFont: failed to set size");
		exit(1);
	}

	font->CharMap(ft_encoding_unicode);
	//font->UseDisplayList(true);
	fprintf(stderr, "zLoadFont: font = %08x\n", font);
	return font;
}

void zUnloadFont(FTFont *font) {
    fprintf(stderr, "deleting font: %08x... ", font);
    delete font;
    fprintf(stderr, "ok\n");    
}

void zGetBoundingBox(FTFont *font, const wchar_t *str, float *lx, float *ly, float *tx, float *ty) {
	float x1, y1, z1, x2, y2, z2;
	font->BBox(str, x1, y1, z1, x2, y2, z2);
	*lx = x1;
	*ly = y1;
	*tx = x2;
	*ty = y2;
}

void zDrawString(FTFont *font, double x, double y, double z, const wchar_t *str) {
    //glLoadIdentity();
	//glTranslatef(x, y, z);

	//glNormal3f( 0.0, 0.0, -1.0);
	font->Render(str);
}

