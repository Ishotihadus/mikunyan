#ifndef PVRTC_H
#define PVRTC_H

#include <stdint.h>

int decode_pvrtc_4bpp(const uint8_t*, const int, const int, uint32_t*);

#endif /* end of include guard: PVRTC_H */
