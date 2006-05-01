AUTOMAKE_OPTIONS = gnu

bin_PROGRAMS =  hget hpost hhead
hget_SOURCES =  hget.c
hget_LDADD = ./libhttp.la
hpost_SOURCES = hpost.c
hpost_LDADD = ./libhttp.la
hhead_SOURCES = hhead.c
hhead_LDADD = ./libhttp.la

lib_LTLIBRARIES = libhttp.la

libhttp_la_SOURCES = http.c

include_HEADERS = http.h

libhttp_la_LDFLAGS = -version-info 0:9:0


CC = @CC@
VERSION = @VERSION@
CFLAGS = @CFLAGS@

EXTRA_DIST = httpget.c Makefile.simple http.txt

