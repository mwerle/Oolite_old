/*
	flex scanner for Oolite DAT 3D files.
	Convert to C using flex -s -8 -CFe -POoliteDAT_yy
*/

%option noyywrap


%{	
	#include "OoliteDATTokens.h"
	
	static unsigned sLine = 1;
%}


digit			[[:digit:]]
positive		{digit}+
integer			[+-]?{positive}
real			{integer}("."{positive})?("e"{integer})?
separator		[ \t,]*
comment			("//"|"#").*
lineBreak		("\r\n"|"\r"|"\n")
endOfLine		{separator}?{comment}?{lineBreak}
string			[[:alpha:]][^ \n\t,#]*


%%


{endOfLine}				{ ++sLine; return kOoliteDatToken_EOL; }

^"VERTEX"{endOfLine}	{ ++sLine; return kOoliteDatToken_VERTEX_SECTION; }
^"FACES"{endOfLine}		{ ++sLine; return kOoliteDatToken_FACES_SECTION; }
^"TEXTURES"{endOfLine}	{ ++sLine; return kOoliteDatToken_TEXTURES_SECTION; }
^"END"{endOfLine}		{ ++sLine; return kOoliteDatToken_END_SECTION; }

^"NVERTS"{separator}	{ return kOoliteDatToken_NVERTS; }
^"NFACES"{separator}	{ return kOoliteDatToken_NFACES; }

{separator}				
{comment}				

{positive}				{ return kOoliteDatToken_INTEGER; }
{real}					{ return kOoliteDatToken_REAL; }
{string}				{ return kOoliteDatToken_STRING; }

%%


extern void OoliteDAT_SetInputFile(FILE *inFile)
{
	yyin = inFile;
	if (NULL == yyout) yyout = fopen("/dev/null", "w");
	YY_FLUSH_BUFFER;
	sLine = 1;
}


extern int OoliteDAT_LineNumber(void)
{
	return sLine;
}


#ifdef LEX_TEST

int main(int argc, char **argv)
{
	int				tok, count = 0;
	
	if (argc < 2)
	{
		printf("No file name specified.");
		return 1;
	}
	OoliteDAT_SetInputFile(fopen(argv[1], "r"));
	
	do
	{
		tok = yylex();
		
		#if 0
			#define PRINT_TOK printf
		#else
			#define PRINT_TOK(...)
		#endif
		
		switch (tok)
		{
			case kOoliteDatToken_EOF:
				PRINT_TOK("EOF\n\n");
				break;
			
			case kOoliteDatToken_EOL:
				PRINT_TOK("EOL\n");
				break;
			
			case kOoliteDatToken_VERTEX_SECTION:
				PRINT_TOK("VERTEX ");
				break;
			
			case kOoliteDatToken_FACES_SECTION:
				PRINT_TOK("FACES ");
				break;
			
			case kOoliteDatToken_TEXTURES_SECTION:
				PRINT_TOK("TEXTURES ");
				break;
			
			case kOoliteDatToken_END_SECTION:
				PRINT_TOK("END ");
				break;
			
			case kOoliteDatToken_NVERTS:
				PRINT_TOK("NVERTS ");
				break;
			
			case kOoliteDatToken_NFACES:
				PRINT_TOK("NFACES ");
				break;
			
			case kOoliteDatToken_INTEGER:
				PRINT_TOK("INTEGER(%i) ", atoi(yytext));
				break;
			
			case kOoliteDatToken_REAL:
				PRINT_TOK("REAL(%g) ", atof(yytext));
				break;
			
			case kOoliteDatToken_STRING:
				PRINT_TOK("NAME(%s) ", yytext);
				break;
			
			default:
				printf("Unknown token %u! \n", tok);
		}
		
		++count;
	}
	while (tok);
	printf("%u tokens, %u lines.\n", count, sLine);
	
	return 0;
}

#endif
