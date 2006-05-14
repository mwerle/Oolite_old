include $(GNUSTEP_MAKEFILES)/common.make

ADDITIONAL_INCLUDE_DIRS = -I$(HOME)/dev/include
ADDITIONAL_OBJC_LIBS = -lhttp -lgnustep-base -lunzip
OBJC_PROGRAM_NAME = tester

tester_LIB_DIRS += -L$(HOME)/dev/lib
tester_OBJC_FILES = tester.m DOOFetch.m DOOUnzip.m

include $(GNUSTEP_MAKEFILES)/objc.make

