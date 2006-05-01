/***************************************************************************
 *
 *     Program: hget
 *
 * Description: call http_request to process a GET request over http
 *
 ***************************************************************************
 *
 * hget.c
 *
 * Copyright (C) 2001 by Alan DuBoff <aland@SoftOrchestra.com>
 *
 * Last change: 9/2/2001
 * 
 * The right to use, modify and redistribute this code is allowed
 * provided the above copyright notice and the below disclaimer appear
 * on all copies.
 *
 * This file is provided AS IS with no warranties of any kind.  The author
 * shall have no liability with respect to the infringement of copyrights,
 * trade secrets or any patents by this file or any part thereof.  In no
 * event will the author be liable for any lost revenue or profits or
 * other special, indirect and consequential damages.
 *
 ***************************************************************************/
                                 
#include "http.h"

int main( int argc, char** argv );

int main( int argc, char** argv )
{
    int     iRet = 0;
    int     outFile = 0;
    HTTP_Response hResponse;
    HTTP_Extra  hExtra;

    if( argc < 2 )
    {
        fprintf( stderr, "\n           Usage = hget URL <output.file> <extra-entities>\n\n");
        
        fprintf( stderr, "             URL = any valid http scheme\n");
        fprintf( stderr, "   <output.file> = OPTIONAL, default file is ./temp.out\n" );
        fprintf( stderr, "<extra-entities> = OPTIONAL, additional header entities\n");
        fprintf( stderr, "                             do not add a final newline\n");
        fprintf( stderr, "                             only add newlines between\n");
        fprintf( stderr, "                             each entity.\n\n");
        fprintf( stderr, "                             <output.file> required when specifying <extra-entities>\n\n");

        fprintf( stderr, "    Example usage:\n\n" );

        fprintf( stderr, "    hget http://localhost/ ./index.html\n" );
        fprintf( stderr, "    hget http://www.SoftOrchestra.com/images/music.png ./music.png\n" );
        fprintf( stderr, "    hget http://localhost/ ./local.html \"If-Modified-Since: Mon, 18 Sep 2000 16:00:00 GMT\"\n" );
        fprintf( stderr, "    hget http://localhost/ ./local.html \"If-Match: \\\"xxx\\\"\\nIf-Modified-Since: Mon, 18 Sep 2000 16:00:00 GMT\"\n\n" );
        exit( 1 );
    }

    /* Additional HTTP header go there */
    memset(&hExtra, '\0', sizeof(hExtra));
    if(argc > 3)
      hExtra.Headers = argv[3];
                                            //  method enums defined in http.h
    hResponse = http_request( argv[1], &hExtra, kHMethodGet, HFLAG_NONE );

    fprintf( stderr, "   HTTP_Response.lSize: %ld\n", hResponse.lSize );
    fprintf( stderr, "  HTTP_Response.iError: %d\n", hResponse.iError );
    if( hResponse.pError )
        fprintf( stderr, "  HTTP_Response.pError: %s\n", hResponse.pError );
    fprintf( stderr, "HTTP_Response.szHError: %s\n", hResponse.szHCode );
    fprintf( stderr, "  HTTP_Response.szHMsg: %s\n", hResponse.szHMsg );

    if( (hResponse.lSize > 0) && (hResponse.iError == 0) )
    {
        if( (outFile = open( (argc > 2) ? argv[2] : "./temp.out" ,
                            O_WRONLY | O_TRUNC | O_CREAT,
                            S_IRUSR|S_IWUSR|S_IRGRP|S_IROTH )) != -1 )
        {
            iRet = write( outFile, hResponse.pData, (size_t)hResponse.lSize );
            if( iRet == -1 )
                fprintf( stderr, "ERROR writing file: %d - %s\n", errno, strerror( errno ) );
            close( outFile );
        }
        if( hResponse.pData ) free( hResponse.pData );
        iRet = 0;
    }
    else
    {
        fprintf( stderr, "ERROR: No data transfered\n" );
        if( hResponse.pError )
            fprintf( stderr, "Error text: %s\n", hResponse.pError );
        iRet = 1;
    }
    exit( iRet );
}

