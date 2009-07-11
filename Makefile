# Build version string, taking into account that 'VER_REV' may not be set
VERSION     := $(shell cat src/Cocoa/oolite-version.xcconfig | cut -d '=' -f 2)
VER_MAJ     := $(strip $(shell echo "${VERSION}" | cut -d '.' -f 1))
VER_MIN     := $(strip $(shell echo "${VERSION}" | cut -d '.' -f 2))
VER_REV     := $(strip $(shell echo "${VERSION}" | cut -d '.' -f 3))
VER_REV     := $(if ${VER_REV},${VER_REV},0)
SVNREVISION := $(shell svn info  | grep Revision | cut -d ' ' -f 2)
VER         := $(shell echo "${VER_MAJ}.${VER_MIN}.${VER_REV}.${SVNREVISION}")
BUILDTIME   := $(shell date "+%Y.%m.%d %H:%M")

LIBJS_SRC_DIR=deps/Cross-platform-deps/SpiderMonkey/js/src

ifeq ($(GNUSTEP_HOST_OS),mingw32)
LIBJS=deps/Windows-x86-deps/DLLs/js32.dll
endif
ifeq ($(GNUSTEP_HOST_OS),linux-gnu)
# Set up GNU make environment
GNUSTEP_MAKEFILES=/usr/share/GNUstep/Makefiles
# These are the paths for our custom-built Javascript library
LIBJS_INC_DIR=$(LIBJS_SRC_DIR)
LIBJS_BIN_DIR=$(LIBJS_SRC_DIR)/Linux_All_OPT.OBJ
LIBJS=$(LIBJS_BIN_DIR)/libjs.a
endif

DEPS=$(LIBJS)

# Here are our default targets
#
.PHONY: release
release: $(DEPS)
	make -f GNUmakefile debug=no
	
.PHONY: release-snapshot
release-snapshot: $(DEPS)
	make -f GNUmakefile SNAPSHOT_BUILD=yes VERSION_STRING=$(VER) debug=no

.PHONY: debug
debug: $(DEPS)
	make -f GNUmakefile debug=yes

$(LIBJS):
ifeq ($(GNUSTEP_HOST_OS),mingw32)
	@echo "ERROR - this Makefile can't (yet) build the Javascript DLL"
	@echo "        Please build it yourself and copy it to $(LIBJS)."
	false
endif
	make -C $(LIBJS_SRC_DIR) -f Makefile.ref BUILD_OPT=1

.PHONY: clean
clean:
ifneq ($(GNUSTEP_HOST_OS),mingw32)
	make -C $(LIBJS_SRC_DIR)/editline -f Makefile.ref clobber
	make -C $(LIBJS_SRC_DIR) -f Makefile.ref clobber
	find $(LIBJS_SRC_DIR) -name "Linux_All_*.OBJ" | xargs rm -Rf
endif
	make -f GNUmakefile clean
	rm -Rf obj obj.dbg oolite.app

.PHONY: all
all: release release-snapshot debug

.PHONY: remake
remake: clean all

# Here are our Debian packager targets
#
.PHONY: pkg-deb
pkg-deb:
	debuild binary

.PHONY: pkg-debclean
pkg-debclean:
	debuild clean

# And here are our Windows packager targets
#
NSIS="C:\Program Files\NSIS\makensis.exe"
NSISVERSIONS=installers/win32/OoliteVersions.nsh

# Passing arguments cause problems with some versions of NSIS.
# Because of this, we generate them into a separate file and include them.
.PHONY: ${NSISVERSIONS}
${NSISVERSIONS}:
	@echo "; Version Definitions for Oolite" > $@
	@echo "; NOTE - This file is auto-generated by the Makefile, any manual edits will be overwritten" >> $@
	@echo "!define VER_MAJ ${VER_MAJ}" >> $@
	@echo "!define VER_MIN ${VER_MIN}" >> $@
	@echo "!define VER_REV ${VER_REV}" >> $@
	@echo "!define SVNREV ${SVNREVISION}" >> $@
	@echo "!define VERSION ${VER}" >> $@
	@echo "!define BUILDTIME \"${BUILDTIME}\"" >> $@

.PHONY: pkg-win
pkg-win: release ${NSISVERSIONS}
	$(NSIS) installers/win32/OOlite.nsi

.PHONY: pkg-win-snapshot
pkg-win-snapshot: release-snapshot ${NSISVERSIONS}
	@echo "!define SNAPSHOT 1" >> ${NSISVERSIONS}
	$(NSIS) installers/win32/OOlite.nsi

.PHONY: help
help:
	@echo "Use this Makefile to build Oolite:"
	@echo "  release - builds a release executable in oolite.app/oolite"
	@echo "  debug   - builds a debug executable in oolite.app/oolite.dbg"
	@echo "  all     - builds the above two targets"
	@echo "  clean   - removes all generated files"
	@echo
	@echo "  pkg-deb - builds a Debian package"
	@echo "  pkg-debclean - cleans up after a Debian package build"
	@echo
	@echo "  pkg-win - builds a release version Windows installer package"
	@echo "  pkg-win-snapshot - builds a snapshot version Windows installer package"
