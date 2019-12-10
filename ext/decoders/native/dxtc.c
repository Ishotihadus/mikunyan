#include "dxtc.h"
#include "common.h"
#include <stdint.h>
#include <string.h>

static inline uint_fast32_t color(uint_fast8_t r, uint_fast8_t g, uint_fast8_t b, uint_fast8_t a)
{
#if BYTE_ORDER == LITTLE_ENDIAN
    return r | g << 8 | b << 16 | a << 24;
#else
    return a | b << 8 | g << 16 | r << 24;
#endif
}

static inline void rgb565(const uint16_t d, uint8_t* r, uint8_t* g, uint8_t* b)
{
#if BYTE_ORDER == LITTLE_ENDIAN
    *r = (d >> 8 & 0xf8) | (d >> 13);
    *g = (d >> 3 & 0xfc) | (d >> 9 & 3);
    *b = (d << 3) | (d >> 2 & 7);
#else
    *r = (d & 0xf8) | (d >> 5 & 7);
    *g = (d << 5 & 0xe0) | (d >> 11 & 0x1c) | (d >> 1 & 3);
    *b = (d >> 5 & 0xf8) | (d >> 10 & 0x7);
#endif
}

static inline void decode_dxt1_block(const uint8_t* data, uint32_t* outbuf)
{
    uint8_t r0, g0, b0, r1, g1, b1;
    int q0 = *(uint16_t*)(data);
    int q1 = *(uint16_t*)(data + 2);
    rgb565(q0, &r0, &g0, &b0);
    rgb565(q1, &r1, &g1, &b1);
    uint_fast32_t c[4] = { color(r0, g0, b0, 255), color(r1, g1, b1, 255) };
    if (q0 > q1) {
        c[2] = color((r0 * 2 + r1) / 3, (g0 * 2 + g1) / 3, (b0 * 2 + b1) / 3, 255);
        c[3] = color((r0 + r1 * 2) / 3, (g0 + g1 * 2) / 3, (b0 + b1 * 2) / 3, 255);
    } else {
        c[2] = color((r0 + r1) / 2, (g0 + g1) / 2, (b0 + b1) / 2, 255);
        c[3] = color(0, 0, 0, 255);
    }
#if BYTE_ORDER == LITTLE_ENDIAN
    uint_fast32_t d = *(uint32_t*)(data + 4);
#else
    uint_fast32_t d = data[4] | data[5] << 8 | data[6] << 16 | data[7] << 24;
#endif
    for (int i = 0; i < 16; i++, d >>= 2)
        outbuf[i] = c[d & 3];
}

void decode_dxt1(const uint8_t* data, const int w, const int h, uint32_t* image)
{
    int num_blocks_x = (w + 3) / 4;
    int num_blocks_y = (h + 3) / 4;
    int copy_length_last = (w + 3) % 4 + 1;
    uint32_t buf[16];
    uint32_t* buf_end = buf + 16;
    const uint8_t* d = data;
    for (int t = 0; t < num_blocks_y; t++) {
        for (int s = 0; s < num_blocks_x; s++, d += 8) {
            decode_dxt1_block(d, buf);
            int copy_length = (s < num_blocks_x - 1 ? 4 : copy_length_last) * 4;
            uint32_t* b = buf;
            for (int y = h - t * 4 - 1; b < buf_end && y >= 0; b += 4, y--)
                memcpy(image + y * w + s * 4, b, copy_length);
        }
    }
}

static inline void decode_dxt5_block(const uint8_t* data, uint32_t* outbuf)
{
    uint_fast32_t a[8] = { data[0], data[1] };
    if (a[0] > a[1]) {
        a[2] = (a[0] * 6 + a[1]) / 7;
        a[3] = (a[0] * 5 + a[1] * 2) / 7;
        a[4] = (a[0] * 4 + a[1] * 3) / 7;
        a[5] = (a[0] * 3 + a[1] * 4) / 7;
        a[6] = (a[0] * 2 + a[1] * 5) / 7;
        a[7] = (a[0] + a[1] * 6) / 7;
    } else {
        a[2] = (a[0] * 4 + a[1]) / 5;
        a[3] = (a[0] * 3 + a[1] * 2) / 5;
        a[4] = (a[0] * 2 + a[1] * 3) / 5;
        a[5] = (a[0] + a[1] * 4) / 5;
        a[6] = 0;
        a[7] = 255;
    }
    for (int i = 0; i < 8; i++)
        a[i] = color(255, 255, 255, a[i]);
    decode_dxt1_block(data + 8, outbuf);
#if BYTE_ORDER == LITTLE_ENDIAN
    uint_fast64_t d = *(uint64_t*)data >> 16;
#else
    uint_fast64_t d = data[2] | data[3] << 8 | data[4] << 16 | data[5] << 24 | data[6] << 32 | data[7] << 40;
#endif
    for (int i = 0; i < 16; i++, d >>= 3)
        outbuf[i] &= a[d & 7];
}

void decode_dxt5(const uint8_t* data, const int w, const int h, uint32_t* image)
{
    int num_blocks_x = (w + 3) / 4;
    int num_blocks_y = (h + 3) / 4;
    int copy_length_last = (w + 3) % 4 + 1;
    uint32_t buf[16];
    uint32_t *buf_end = buf + 16;
    const uint8_t* d = data;
    for (int t = 0; t < num_blocks_y; t++) {
        for (int s = 0; s < num_blocks_x; s++, d += 16) {
            decode_dxt5_block(d, buf);
            int copy_length = (s < num_blocks_x - 1 ? 4 : copy_length_last) * 4;
            uint32_t *b = buf;
            for (int y = h - t * 4 - 1; b < buf_end && y >= 0; b += 4, y--)
                memcpy(image + y * w + s * 4, b, copy_length);
        }
    }
}
