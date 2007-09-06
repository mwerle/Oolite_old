# Project: js32

CC   = gcc.exe
WINDRES = windres.exe
RES  = js.res
SRCDIR = /d/devlibs/SpiderMonkey/js/src
OBJECTS = \
$(SRCDIR)/jsapi.o \
$(SRCDIR)/jsarena.o \
$(SRCDIR)/jsarray.o \
$(SRCDIR)/jsatom.o \
$(SRCDIR)/jsbool.o \
$(SRCDIR)/jscntxt.o \
$(SRCDIR)/jsdate.o \
$(SRCDIR)/jsdbgapi.o \
$(SRCDIR)/jsdhash.o \
$(SRCDIR)/jsdtoa.o \
$(SRCDIR)/jsemit.o \
$(SRCDIR)/jsexn.o \
$(SRCDIR)/jsfun.o \
$(SRCDIR)/jsgc.o \
$(SRCDIR)/jshash.o \
$(SRCDIR)/jsinterp.o \
$(SRCDIR)/jsiter.o \
$(SRCDIR)/jslock.o \
$(SRCDIR)/jslog2.o \
$(SRCDIR)/jslong.o \
$(SRCDIR)/jsmath.o \
$(SRCDIR)/jsnum.o \
$(SRCDIR)/jsobj.o \
$(SRCDIR)/jsopcode.o \
$(SRCDIR)/jsparse.o \
$(SRCDIR)/jsprf.o \
$(SRCDIR)/jsregexp.o \
$(SRCDIR)/jsscan.o \
$(SRCDIR)/jsscope.o \
$(SRCDIR)/jsscript.o \
$(SRCDIR)/jsstr.o \
$(SRCDIR)/jsutil.o \
$(SRCDIR)/jsxdrapi.o \
$(SRCDIR)/jsxml.o \
$(SRCDIR)/prmjtime.o \
$(SRCDIR)/$(RES)

#LIBS = --add-stdcall-alias -lfdlibm -lnspr4 -L./fdlibm -L/d/devlibs/nspr-4.4.1/lib
LIBS = --add-stdcall-alias -lfdlibm -L./fdlibm
BIN  = js32.dll
#CFLAGS = -I/d/devlibs/nspr-4.4.1/include -DJS_THREADSAFE -DXP_WIN \
#-DEXPORT_JS_API -D_WINDOWS -DWIN32 -D_MINGW -s
CFLAGS = -I/d/devlibs/nspr-4.4.1/include -DXP_WIN \
-DEXPORT_JS_API -D_WINDOWS -DWIN32 -D_MINGW -DJS_C_STRINGS_ARE_UTF8 -s

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
	$(WINDRES) -i $(SRCDIR)/js3240.rc -I rc -o $(RES) -O coff
