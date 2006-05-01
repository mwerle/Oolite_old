/* ************************************************************************

   HTTPGET

   Copyright 1994 by Sami Tikka <sti@cs.hut.fi>

   Last change: Feb 10, 1995
   
   The right to use, modify and redistribute this code is allowed
   provided the above copyright notice and the below disclaimer appear
   on all copies.

   This file is provided AS IS with no warranties of any kind.  The author
   shall have no liability with respect to the infringement of copyrights,
   trade secrets or any patents by this file or any part thereof.  In no
   event will the author be liable for any lost revenue or profits or
   other special, indirect and consequential damages.

   Compile with (g)cc -o httpget httpget.c (-lsocket)

   ************************************************************************ */
     

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <unistd.h>

#include <sys/types.h>
#include <sys/param.h>
#include <sys/socket.h>
#include <netdb.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <sys/time.h>
#include <memory.h>


char *find_header_end(char *buf, int bytes) {

	char *end = buf + bytes;
  
	while (buf < end && !(*buf++ == '\n'
			      && (*buf == '\n'
				  || (*buf++ == '\r'
				      && *buf == '\n')))) ;
	if (*buf == '\n')
		return buf + 1;
	return NULL;
}

void parse_url(char *url, char *scheme, char *host, int *port, char *path)
{
	char *slash, *colon;
	char *delim;
	char turl[MAXPATHLEN];
	char *t;

	/* All operations on turl so as not to mess contents of url */
  
	strcpy(turl, url);

	delim = "://";

	if ((colon = strstr(turl, delim)) == NULL) {
		fprintf(stderr, "Warning: URL is not in format <scheme>://<host>/<path>.\nAssuming scheme = http.\n");
		strcpy(scheme, "http");
		t = turl;
	} else {
		*colon = '\0';
		strcpy(scheme, turl);
		t = colon + strlen(delim);
	}

	/* Now t points to the beginning of host name */

	if ((slash = strchr(t, '/')) == NULL) {
		/* If there isn't even one slash, the path must be empty */
		fprintf(stderr, "Warning: no slash character after the host name.  Empty path.  Adding slash.\n");
		strcpy(host, t);
		strcpy(path, "/");
	} else {
		strcpy(path, slash);
		*slash = '\0';	/* Terminate host name */
		strcpy(host, t);
	}

	/* Check if the hostname includes ":portnumber" at the end */

	if ((colon = strchr(host, ':')) == NULL) {
		*port = 80;	/* HTTP standard */
	} else {
		*colon = '\0';
		*port = atoi(colon + 1);
	}
}

#define BUFLEN 10 * 1024

int main(int argc, char *argv[])
{
	char buf[BUFLEN];
	char request[MAXPATHLEN + 20];
	char scheme[50], host[MAXPATHLEN], path[MAXPATHLEN];
	char *url;
	char *proxy;
	int port;
	int reload = 0;
	struct hostent *nameinfo;
	int s;
	struct sockaddr_in addr;
	struct timeval from_request, from_reply, end;
	long total_bytes, bytes;
	fd_set set;
	int in_header;
	char *h_end_ptr;
	long secs, usecs, bytes_per_sec;
    

	if (argc < 2) {
		fprintf(stderr, "Wrong number of arguments.\n");
		fprintf(stderr, "Usage: httpget -r http://host.name/path/to/document.html\n");
		exit(1);
	}
	if (!strcmp(argv[1], "-r")) {
		reload = 1;
	}
	url = argv[argc - 1];
	if ((proxy = getenv("http_proxy")) == NULL) {
		parse_url(url, scheme, host, &port, path);
		fprintf(stderr, "URL scheme = %s\n", scheme);
		fprintf(stderr, "URL host = %s\n", host);
		fprintf(stderr, "URL port = %d\n", port);
		fprintf(stderr, "URL path = %s\n", path);
		if (strcasecmp(scheme, "http") != 0) {
			fprintf(stderr, "httpget cannot operate on %s URLs without a proxy\n", scheme);
			exit(1);
		}
	} else {
		parse_url(proxy, scheme, host, &port, path);
		fprintf(stderr, "Using proxy server at %s:%d\n", host, port);
	}


	/* Find out the IP address */

	if ((nameinfo = gethostbyname(host)) == NULL) {
		addr.sin_addr.s_addr = inet_addr(host);
		if ((int)addr.sin_addr.s_addr == -1) {
			fprintf(stderr, "Unknown host %s\n", host);
			exit(1);
		}
	} else {
		memcpy((char *)&addr.sin_addr.s_addr, nameinfo->h_addr, nameinfo->h_length);
	}

	/* Create socket and connect */
  
	if ((s = socket(PF_INET, SOCK_STREAM, 0)) == -1) {
		perror("httpget: socket()");
		exit(1);
	}
	addr.sin_family = AF_INET;
	addr.sin_port = htons(port);
  
	if (connect(s, (struct sockaddr *)&addr, sizeof(addr)) == -1) {
		perror("httpget: connect()");
		exit(1);
	}

	fprintf(stderr, "Connected to %s:%d\n", host, port);

	if (proxy) {
		fprintf(stderr, "Sending URL %s to proxy...\n", url);
		sprintf(request, "GET %s HTTP/1.0\r\n", url);
	} else {
		fprintf(stderr, "Sending request...\n");
		sprintf(request, "GET %s HTTP/1.0\r\n", path);
	}
	if (reload) {
		strcat(request, "Pragma: no-cache\r\n");
	}
	strcat(request, "Accept: */*\r\n\r\n");
  
	gettimeofday(&from_request, NULL);

	write(s, request, strlen(request));

	FD_ZERO(&set);
	FD_SET(s, &set);

	if (select(FD_SETSIZE, &set, NULL, NULL, NULL) == -1) {
		perror("httpget: select()");
		exit(1);
	}

	gettimeofday(&from_reply, NULL);

	fprintf(stderr, "----- HTTP reply header follows -----\n");

	in_header = 1;

	total_bytes = 0;
  
	while ((bytes = read(s, buf, BUFLEN)) != 0) {
		total_bytes += bytes;

		if (in_header) {
			/* Search for the reply header delimiter (blank line) */

			h_end_ptr = find_header_end(buf, total_bytes);
      
			if (h_end_ptr != NULL) {
				/* Found, print up to delimiter to stderr and rest to stdout */
				fwrite(buf, h_end_ptr - buf, 1, stderr);
				fprintf(stderr, "----- HTTP reply header end -----\n");
				fwrite(h_end_ptr, bytes - (h_end_ptr - buf), 1, stdout);
				in_header = 0;
			} else {
				/* Not found, print all in buf to stderr and read for more headers */
				fwrite(buf, bytes, 1, stderr);
			}
			fflush(stderr);
		} else {
			fwrite(buf, bytes, 1, stdout);
		}
	}
	gettimeofday(&end, NULL);
	close(s);
	fprintf(stderr, "Connection closed.\n");

	if (end.tv_usec < from_reply.tv_usec) {
		end.tv_sec -= 1;
		end.tv_usec += 1000000;
	}
  
	usecs = end.tv_usec - from_reply.tv_usec;
	secs = end.tv_sec - from_reply.tv_sec;
  
	fprintf(stderr, "Total of %ld bytes read in %ld.%ld seconds\n",
		total_bytes, secs, usecs);

	if (secs != 0) {
		bytes_per_sec = (int)((total_bytes / (float)secs) + 0.5);
		fprintf(stderr, "%ld bytes per second\n", bytes_per_sec);
	}
	  
	exit(0);
}

/*
 * Local variables:
 * compile-command: "gcc -Wall -o httpget httpget.c -lsocket -nsl"
 * End:
 */
