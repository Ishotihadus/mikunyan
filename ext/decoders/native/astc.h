#ifndef ASTC_H
#define ASTC_H

#include <stdint.h>

void decode_astc(const uint8_t*, const int, const int, const int, const int, uint32_t*);

#endif /* end of include guard: ASTC_H */
