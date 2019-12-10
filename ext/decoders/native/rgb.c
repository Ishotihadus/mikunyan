#include "rgb.h"
#include "common.h"
#include <stdint.h>

void decode_a8(const uint8_t* data, const int size, uint8_t* image)
{
    const uint8_t *d = data, *d_end = data + size;
    for (int i = 0; d < d_end; d++) {
        image[i++] = *d;
        image[i++] = *d;
        image[i++] = *d;
    }
}

void decode_r8(const uint8_t* data, const int size, uint8_t* image)
{
    const uint8_t *d = data, *d_end = data + size;
    for (int i = 0; d < d_end; d++) {
        image[i++] = *d;
        image[i++] = 0;
        image[i++] = 0;
    }
}

void decode_r16(const uint16_t* data, const int size, const int endian_big, uint8_t* image)
{
    const uint16_t *d = data, *d_end = data + size;
    if (IS_LITTLE_ENDIAN == !endian_big) {
        // Same endian
        for (int i = 0; d < d_end; d++) {
            uint8_t c = *d >> 8;
            image[i++] = c;
            image[i++] = 0;
            image[i++] = 0;
        }
    } else {
        // Different endian
        for (int i = 0; d < d_end; d++) {
            image[i++] = *d;
            image[i++] = 0;
            image[i++] = 0;
        }
    }
}

void decode_rgb565(const uint16_t* data, const int size, const int endian_big, uint8_t* image)
{
    const uint16_t *d = data, *d_end = data + size;
    if (IS_LITTLE_ENDIAN == !endian_big) {
        // Same endian
        // RRRRR GGG | GGG BBBBB
        for (int i = 0; d < d_end; d++) {
            image[i++] = (*d >> 8 & 0xf8) | (*d >> 13);
            image[i++] = (*d >> 3 & 0xfc) | (*d >> 9 & 3);
            image[i++] = (*d << 3) | (*d >> 2 & 7);
        }
    } else {
        // Different endian
        // GGG BBBBB | RRRRR GGG
        for (int i = 0; d < d_end; d++) {
            image[i++] = (*d & 0xf8) | (*d >> 5 & 7);
            image[i++] = (*d << 5 & 0xe0) | (*d >> 11 & 0x1c) | (*d >> 1 & 3);
            image[i++] = (*d >> 5 & 0xf8) | (*d >> 10 & 0x7);
        }
    }
}
