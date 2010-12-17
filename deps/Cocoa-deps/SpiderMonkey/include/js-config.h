#if __i386__
#include "js-config-i386.h"
#elif __x86_64__
#include "js-config-x86_64.h"
#else
#error Unsupported platform.
#endif
