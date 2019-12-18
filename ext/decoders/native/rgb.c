#include "rgb.h"
#include <math.h>
#include <stdint.h>
#include "color.h"
#include "fp16.h"

int decode_a8(const uint8_t *const data, const long size, uint8_t *image) {
    const uint8_t *d = data, *d_end = data + size;
    for (int i = 0; d < d_end; d++) {
        image[i++] = *d;
        image[i++] = *d;
        image[i++] = *d;
    }
    return 1;
}

int decode_r8(const uint8_t *const data, const long size, uint8_t *image) {
    const uint8_t *d = data, *d_end = data + size;
    for (int i = 0; d < d_end; d++) {
        image[i++] = *d;
        image[i++] = 0;
        image[i++] = 0;
    }
    return 1;
}

int decode_r16(const uint8_t *const data, const long size, const int endian_big, uint8_t *image) {
    const uint8_t *d = endian_big ? data : data + 1;
    const uint8_t *d_end = data + size * 2;
    for (int i = 0; d < d_end; d += 2) {
        image[i++] = *d;
        image[i++] = 0;
        image[i++] = 0;
    }
    return 1;
}

int decode_rgb565(const uint16_t *const data, const long size, const int endian_big, uint8_t *image) {
    const uint16_t *d = data, *d_end = data + size;
    if (endian_big)
        for (; d < d_end; d++, image += 3)
            rgb565_bep(*d, image);
    else
        for (; d < d_end; d++, image += 3)
            rgb565_lep(*d, image);
    return 1;
}

static inline uint8_t u16_f16_u8(const uint16_t val) {
    float f = fp16_ieee_to_fp32_value(val);
    if (!isfinite(f) || f < 0)
        return 0;
    else if (f > 1)
        return 255;
    else
        return roundf(f * 255);
}

int decode_rhalf(const uint16_t *data, const long size, const int endian_big, uint8_t *image) {
    if (endian_big) {
        for (long i = 0; i < size; i++, data++) {
            *image++ = u16_f16_u8(bton16(*data));
            *image++ = 0;
            *image++ = 0;
        }
    } else {
        for (long i = 0; i < size; i++, data++) {
            *image++ = u16_f16_u8(lton16(*data));
            *image++ = 0;
            *image++ = 0;
        }
    }
    return 1;
}

int decode_rghalf(const uint16_t *data, const long size, const int endian_big, uint8_t *image) {
    if (endian_big) {
        for (long i = 0; i < size; i++, data++, image++) {
            *image++ = u16_f16_u8(bton16(*data++));
            *image++ = u16_f16_u8(bton16(*data++));
            *image++ = 0;
        }
    } else {
        for (long i = 0; i < size; i++, data++) {
            *image++ = u16_f16_u8(lton16(*data++));
            *image++ = u16_f16_u8(lton16(*data++));
            *image++ = 0;
        }
    }
    return 1;
}

int decode_rgbahalf(const uint16_t *data, const long size, const int endian_big, uint8_t *image) {
    long lsize = size * 4;
    if (endian_big)
        for (long i = 0; i < lsize; i++, data++, image++)
            *image = u16_f16_u8(bton16(*data));
    else
        for (long i = 0; i < lsize; i++, data++, image++)
            *image = u16_f16_u8(lton16(*data));
    return 1;
}
