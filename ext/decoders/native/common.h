#include <ruby.h>

/* https://github.com/ruby/ruby/blob/master/siphash.c */

#ifdef _WIN32
#define BYTE_ORDER __LITTLE_ENDIAN
#elif !defined BYTE_ORDER
#include <endian.h>
#endif
#ifndef LITTLE_ENDIAN
#define LITTLE_ENDIAN __LITTLE_ENDIAN
#endif
#ifndef BIG_ENDIAN
#define BIG_ENDIAN __BIG_ENDIAN
#endif

#if BYTE_ORDER == LITTLE_ENDIAN
#define IS_LITTLE_ENDIAN 1
#define IS_BIG_ENDIAN 0
#elif BYTE_ORDER == BIG_ENDIAN
#define IS_LITTLE_ENDIAN 0
#define IS_BIG_ENDIAN 1
#else
#error "Only strictly little or big endian supported"
#endif
