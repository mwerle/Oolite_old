#ifndef INCLUDED_OOLITEDATTOKENS_h
#define INCLUDED_OOLITEDATTOKENS_h

enum
{
	kOoliteDatToken_EOF,
	kOoliteDatToken_EOL,
	kOoliteDatToken_VERTEX_SECTION,
	kOoliteDatToken_FACES_SECTION,
	kOoliteDatToken_TEXTURES_SECTION,
	kOoliteDatToken_END_SECTION,
	kOoliteDatToken_NVERTS,
	kOoliteDatToken_NFACES,
	kOoliteDatToken_INTEGER,
	kOoliteDatToken_REAL,
	kOoliteDatToken_STRING
};


#ifdef __cplusplus
extern "C" {
#endif

extern int OoliteDAT_yylex(void);
extern void OoliteDAT_SetInputFile(FILE *inFile);
extern int OoliteDAT_LineNumber(void);
extern char *OoliteDAT_yytext;

#ifdef __cplusplus
}
#endif

#endif	/* INCLUDED_OOLITEDATTOKENS_h */
