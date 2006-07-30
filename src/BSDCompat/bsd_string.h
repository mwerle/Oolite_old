#ifndef BSD_STRING_H
#define BSD_STRING_H
#ifdef NEED_STRLCPY
#ifdef __cplusplus
extern "C" {
#endif

size_t strlcpy(char *dst, const char *src, size_t siz);
#ifdef __cplusplus
}
#endif

#endif
#endif

