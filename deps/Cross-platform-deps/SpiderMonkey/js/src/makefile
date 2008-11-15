# Project: js32

CC   = gcc.exe
WINDRES = windres.exe
RES  = js.res
#SRCDIR = /d/devlibs/SpiderMonkey/js/src
OBJECTS = \
	jsapi.o \
	jsarena.o \
	jsarray.o \
	jsatom.o \
	jsbool.o \
	jscntxt.o \
	jsdate.o \
	jsdbgapi.o \
	jsdhash.o \
	jsdtoa.o \
	jsemit.o \
	jsexn.o \
	jsfun.o \
	jsgc.o \
	jshash.o \
	jsinterp.o \
	jsiter.o \
	jslock.o \
	jslog2.o \
	jslong.o \
	jsmath.o \
	jsnum.o \
	jsobj.o \
	jsopcode.o \
	jsparse.o \
	jsprf.o \
	jsregexp.o \
	jsscan.o \
	jsscope.o \
	jsscript.o \
	jsstr.o \
	jsutil.o \
	jsxdrapi.o \
	jsxml.o \
	prmjtime.o \
	$(RES)

#LIBS = --add-stdcall-alias -lfdlibm -lnspr4 -L./fdlibm -L/d/devlibs/nspr-4.4.1/lib
LIBS = --add-stdcall-alias -lfdlibm -L./fdlibm
BIN  = js32.dll
#CFLAGS = -I/d/devlibs/nspr-4.4.1/include -DJS_THREADSAFE -DXP_WIN \
#-DEXPORT_JS_API -D_WINDOWS -DWIN32 -D_MINGW -s
#CFLAGS = -I/d/devlibs/nspr-4.4.1/include -DXP_WIN \
#-DEXPORT_JS_API -D_WINDOWS -DWIN32 -D_MINGW -DJS_C_STRINGS_ARE_UTF8 -s
CFLAGS = -DXP_WIN -DEXPORT_JS_API -D_WINDOWS -DWIN32 -D_MINGW -DJS_C_STRINGS_ARE_UTF8 -s

DLLWRAP=dllwrap.exe
DEFFILE=libjs.def
STATICLIB=libjs32.a
.c.o: $(CC) -c $(CFLAGS) -o $@ $*.c

$(BIN): $(OBJECTS)
	$(CC) -shared -o $@ \
	-Wl,--output-def,$(DEFFILE) \
	-Wl,--out-implib,$(STATICLIB) \
	$(OBJECTS) \
	$(LIBS)

$(RES): 
	$(WINDRES) -i 	js3240.rc -I rc -o $(RES) -O coff

#.c.o:
#	$(CC) $(CCFLAGS) -o 	$@ $<
