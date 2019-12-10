#include <ruby.h>

/* https://github.com/ruby/ruby/blob/master/siphash.c */

#ifdef _WIN32
#define BYTE_ORDER __LITTLE_ENDIAN
#elif !defined BYTE_ORDER
#include <endian.h>
#endif

#ifndef BYTE_ORDER
#if defined(__BYTE_ORDER__)
#define BYTE_ORDER __BYTE_ORDER__
#elif defined(__BYTE_ORDER)
#define BYTE_ORDER __BYTE_ORDER
#else
#error "Neither BYTE_ORDER nor __BYTE_ORDER__ is defined."
#endif
#endif

#ifndef LITTLE_ENDIAN
#if defined(__LITTLE_ENDIAN)
#define LITTLE_ENDIAN __LITTLE_ENDIAN
#define BIG_ENDIAN __BIG_ENDIAN
#elif defined(__LITTLE_ENDIAN__)
#define LITTLE_ENDIAN __LITTLE_ENDIAN__
#define BIG_ENDIAN __BIG_ENDIAN__
#elif defined(__ORDER_LITTLE_ENDIAN__)
#define LITTLE_ENDIAN __ORDER_LITTLE_ENDIAN__
#define BIG_ENDIAN __ORDER_BIG_ENDIAN__
#else
#error "Neither LITTLE_ENDIAN, __LITTLE_ENDIAN, nor __ORDER_LITTLE_ENDIAN__ is defined."
#endif
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
