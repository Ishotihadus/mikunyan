#include <stdint.h>
#include "dxtc.h"

static inline uint_fast32_t color(uint_fast8_t r, uint_fast8_t g, uint_fast8_t b, uint_fast8_t a) {
    return r | g << 8 | b << 16 | a << 24;
}

static inline void rgb565(const uint_fast16_t c, int *r, int *g, int *b) {
    *r = (c & 0xf800) >> 8;
    *g = (c & 0x07e0) >> 3;
    *b = (c & 0x001f) << 3;
    *r |= *r >> 5;
    *g |= *g >> 6;
    *b |= *b >> 5;
}

static inline void decode_dxt1_block(const uint64_t *data, uint32_t *outbuf) {
    int r0, g0, b0, r1, g1, b1;
    int q0 = ((uint16_t*)data)[0];
    int q1 = ((uint16_t*)data)[1];
    rgb565(q0, &r0, &g0, &b0);
    rgb565(q1, &r1, &g1, &b1);
    uint_fast32_t c[4] = { color(r0, g0, b0, 255), color(r1, g1, b1, 255) };
    if (q0 > q1) {
        c[2] = color((r0 * 2 + r1) / 3, (g0 * 2 + g1) / 3, (b0 * 2 + b1) / 3, 255);
        c[3] = color((r0 + r1 * 2) / 3, (g0 + g1 * 2) / 3, (b0 + b1 * 2) / 3, 255);
    } else {
        c[2] = color((r0 + r1) / 2, (g0 + g1) / 2, (b0 + b1) / 2, 255);
    }
    uint_fast32_t d = *data >> 32;
    for (int i = 0; i < 16; i++, d >>= 2)
        outbuf[i] = c[d & 3];
}

void decode_dxt1(const uint64_t *data, const int w, const int h, uint32_t *image) {
    int bcw = (w + 3) / 4;
    int bch = (h + 3) / 4;
    int clen_last = (w + 3) % 4 + 1;
    uint32_t buf[16];
    const uint64_t *d = data;
    for (int t = 0; t < bch; t++) {
        for (int s = 0; s < bcw; s++, d++) {
            decode_dxt1_block(d, buf);
            int clen = (s < bcw - 1 ? 4 : clen_last) * 4;
            for (int i = 0, y = h - t * 4 - 1; i < 4 && y >= 0; i++, y--)
                memcpy(image + y * w + s * 4, buf + i * 4, clen);
        }
    }
}

static inline void decode_dxt5_block(const uint64_t *data, uint32_t *outbuf) {
    uint_fast32_t a[8] = { ((uint8_t*)data)[0], ((uint8_t*)data)[1] };
    if (a[0] > a[1]) {
        a[2] = (a[0] * 6 + a[1]    ) / 7;
        a[3] = (a[0] * 5 + a[1] * 2) / 7;
        a[4] = (a[0] * 4 + a[1] * 3) / 7;
        a[5] = (a[0] * 3 + a[1] * 4) / 7;
        a[6] = (a[0] * 2 + a[1] * 5) / 7;
        a[7] = (a[0]     + a[1] * 6) / 7;
    } else {
        a[2] = (a[0] * 4 + a[1]    ) / 5;
        a[3] = (a[0] * 3 + a[1] * 2) / 5;
        a[4] = (a[0] * 2 + a[1] * 3) / 5;
        a[5] = (a[0]     + a[1] * 4) / 5;
        a[7] = 255;
    }
    for (int i = 0; i < 8; i++)
        a[i] <<= 24;

    int r0, g0, b0, r1, g1, b1;
    int q0 = ((uint16_t*)(data + 1))[0];
    int q1 = ((uint16_t*)(data + 1))[1];
    rgb565(q0, &r0, &g0, &b0);
    rgb565(q1, &r1, &g1, &b1);
    uint_fast32_t c[4] = { color(r0, g0, b0, 0), color(r1, g1, b1, 0) };
    if (q0 > q1) {
        c[2] = color((r0 * 2 + r1) / 3, (g0 * 2 + g1) / 3, (b0 * 2 + b1) / 3, 0);
        c[3] = color((r0 + r1 * 2) / 3, (g0 + g1 * 2) / 3, (b0 + b1 * 2) / 3, 0);
    } else {
        c[2] = color((r0 + r1) / 2, (g0 + g1) / 2, (b0 + b1) / 2, 0);
    }

    uint_fast64_t da = *data >> 16;
    uint_fast32_t dc = *(data + 1) >> 32;
    for (int i = 0; i < 16; i++, da >>= 3, dc >>= 2)
        outbuf[i] = a[da & 7] | c[dc & 3];
}

void decode_dxt5(const uint64_t *data, const int w, const int h, uint32_t *image) {
    int bcw = (w + 3) / 4;
    int bch = (h + 3) / 4;
    int clen_last = (w + 3) % 4 + 1;
    uint32_t buf[16];
    const uint64_t *d = data;
    for (int t = 0; t < bch; t++) {
        for (int s = 0; s < bcw; s++, d += 2) {
            decode_dxt5_block(d, buf);
            int clen = (s < bcw - 1 ? 4 : clen_last) * 4;
            for (int i = 0, y = h - t * 4 - 1; i < 4 && y >= 0; i++, y--)
                memcpy(image + y * w + s * 4, buf + i * 4, clen);
        }
    }
}
