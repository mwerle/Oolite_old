/***************************************************************************
 *
 *     Program: hpost
 *
 * Description: call http_request to process a POST request over http
 *
 ***************************************************************************
 *
 * hpost.c
 *
 * Copyright (C) 2001 by Alan DuBoff <aland@SoftOrchestra.com>
 *
 * Last change: 8/27/2001
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
#include <signal.h>
#include <unistd.h>

int main( int argc, char** argv );

static HTTP_Extra  hExtra;

static void sigalarm_handler(int signum)
{
	signum = signum;
	/* Tell libhttp to give up */
	if(hExtra.Socket > 0)
	{
		fprintf( stderr, "Watchdog : canceling HTTP connection\n");
		close(hExtra.Socket);
	}
}


int main( int argc, char** argv )
{
    int     iRet = 0;
    int     outFile = 0;
    HTTP_Response hResponse;
    struct sigaction	sa;

    if( argc < 3 )
    {

        fprintf( stderr, "\n           Usage = hpost URL POSTDATA <output.file> <extra-entities>\n\n");
        
        fprintf( stderr, "             URL = any valid http scheme\n");
        fprintf( stderr, "        POSTDATA = data of the POST request\n");
        fprintf( stderr, "   <output.file> = OPTIONAL, default file is ./temp.out\n" );
        fprintf( stderr, "<extra-entities> = OPTIONAL, additional header entities\n");
        fprintf( stderr, "                             do not add a final newline\n");
        fprintf( stderr, "                             only add newlines between\n");
        fprintf( stderr, "                             each entity.\n\n");
        fprintf( stderr, "                             <output.file> required when specifying <extra-entities>\n\n");

        fprintf( stderr, "    Example usage:\n\n" );

        fprintf( stderr, "    hpost http://host/path/doc.xml firstname=John\\&lastname=Doe\\&state=CA\n" );
        fprintf( stderr, "          (you must escape the '&' chars on the command line)\n\n" );
        fprintf( stderr, "    hpost http://host/path/doc.xml firstname=John\\&lastname=Doe ./local.html \"If-Modified-Since: Mon, 18 Sep 2000 16:00:00 GMT\"\n\n" );

        exit( 1 );
    }

    /* Setup watchdog timer callback */
    sigemptyset(&sa.sa_mask);	/* Signal to mask during handler */
    sa.sa_flags = 0;		/* No fancy options */
    sa.sa_handler = &sigalarm_handler;
    sigaction(SIGALRM, &sa, NULL);

    /* Set watchdog timer value to 30s */
    alarm(30);

    /* Additional HTTP header go there */
    memset(&hExtra, '\0', sizeof(hExtra));
    if(argc > 4)
      hExtra.Headers = argv[4];

    /* Post data go there */
    hExtra.PostData = argv[2];
    hExtra.PostLen = strlen(argv[2]);
                                            //  method enums defined in http.h
    hResponse = http_request( argv[1], &hExtra, kHMethodPost, HFLAG_NONE );

    /* Cancel watchdog */
    alarm(0);

    fprintf( stderr, "   HTTP_Response.lSize: %ld\n", hResponse.lSize );
    fprintf( stderr, "  HTTP_Response.iError: %d\n", hResponse.iError );
    if( hResponse.pError )
        fprintf( stderr, "  HTTP_Response.pError: %s\n", hResponse.pError );
    fprintf( stderr, "HTTP_Response.szHError: %s\n", hResponse.szHCode );
    fprintf( stderr, "  HTTP_Response.szHMsg: %s\n", hResponse.szHMsg );

    if( (hResponse.lSize > 0) && (hResponse.iError == 0) )
    {
        if( (outFile = open( (argc > 3) ? argv[3] : "./temp.out" ,
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

