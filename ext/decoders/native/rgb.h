#ifndef RGB_H
#define RGB_H

#include <stdint.h>

int decode_a8(const uint8_t *const, const long, uint8_t *);
int decode_r8(const uint8_t *const, const long, uint8_t *);
int decode_r16(const uint8_t *const, const long, const int, uint8_t *);
int decode_rgb565(const uint16_t *const, const long, const int, uint8_t *);
int decode_rhalf(const uint16_t *const, const long, const int, uint8_t *);
int decode_rghalf(const uint16_t *const, const long, const int, uint8_t *);
int decode_rgbahalf(const uint16_t *const, const long, const int, uint8_t *);

#endif /* end of include guard: RGB_H */
