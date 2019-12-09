#ifndef RGB_H
#define RGB_H

#include <stdint.h>

void decode_a8(const uint8_t*, const int, uint8_t*);
void decode_r16(const uint16_t*, const int, const int, uint8_t*);
void decode_rgb565(const uint16_t*, const int, const int, uint8_t*);

#endif /* end of include guard: RGB_H */
