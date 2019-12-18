#include "dxtc.h"
#include <stdint.h>
#include <string.h>
#include "color.h"
#include "endianness.h"

static inline void decode_dxt1_block(const uint8_t *data, uint32_t *outbuf) {
    uint8_t r0, g0, b0, r1, g1, b1;
    int q0 = *(uint16_t *)(data);
    int q1 = *(uint16_t *)(data + 2);
    rgb565_le(q0, &r0, &g0, &b0);
    rgb565_le(q1, &r1, &g1, &b1);
    uint_fast32_t c[4] = {color(r0, g0, b0, 255), color(r1, g1, b1, 255)};
    if (q0 > q1) {
        c[2] = color((r0 * 2 + r1) / 3, (g0 * 2 + g1) / 3, (b0 * 2 + b1) / 3, 255);
        c[3] = color((r0 + r1 * 2) / 3, (g0 + g1 * 2) / 3, (b0 + b1 * 2) / 3, 255);
    } else {
        c[2] = color((r0 + r1) / 2, (g0 + g1) / 2, (b0 + b1) / 2, 255);
        c[3] = color(0, 0, 0, 255);
    }
    uint_fast32_t d = lton32(*(uint32_t *)(data + 4));
    for (int i = 0; i < 16; i++, d >>= 2)
        outbuf[i] = c[d & 3];
}

int decode_dxt1(const uint8_t *data, const long w, const long h, uint32_t *image) {
    long num_blocks_x = (w + 3) / 4;
    long num_blocks_y = (h + 3) / 4;
    uint32_t buffer[16];
    const uint8_t *d = data;
    for (long by = 0; by < num_blocks_y; by++) {
        for (long bx = 0; bx < num_blocks_x; bx++, d += 8) {
            decode_dxt1_block(d, buffer);
            copy_block_buffer(bx, by, w, h, 4, 4, buffer, image);
        }
    }
    return 1;
}

static inline void decode_dxt5_block(const uint8_t *data, uint32_t *outbuf) {
    uint_fast32_t a[8] = {data[0], data[1]};
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
        a[i] = alpha_mask(a[i]);
    decode_dxt1_block(data + 8, outbuf);
    uint_fast64_t d = lton64(*(uint64_t *)data) >> 16;
    for (int i = 0; i < 16; i++, d >>= 3)
        outbuf[i] &= a[d & 7];
}

int decode_dxt5(const uint8_t *data, const long w, const long h, uint32_t *image) {
    long num_blocks_x = (w + 3) / 4;
    long num_blocks_y = (h + 3) / 4;
    uint32_t buffer[16];
    const uint8_t *d = data;
    for (long by = 0; by < num_blocks_y; by++) {
        for (long bx = 0; bx < num_blocks_x; bx++, d += 16) {
            decode_dxt5_block(d, buffer);
            copy_block_buffer(bx, by, w, h, 4, 4, buffer, image);
        }
    }
    return 1;
}
