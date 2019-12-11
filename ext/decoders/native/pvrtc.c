#include "pvrtc.h"
#include "common.h"
#include <stdint.h>
#include <string.h>

#define MORTON_POS(x, y) (morton_table_buf[num_blocks_x * (y) + (x)])

typedef struct {
    uint8_t a_r;
    uint8_t a_g;
    uint8_t a_b;
    uint8_t a_a;
    uint8_t b_r;
    uint8_t b_g;
    uint8_t b_b;
    uint8_t b_a;
} PVRTCTexelColor;

static inline uint32_t color(uint8_t r, uint8_t g, uint8_t b, uint8_t a)
{
#if BYTE_ORDER == LITTLE_ENDIAN
    return r | g << 8 | b << 16 | a << 24;
#else
    return a | b << 8 | g << 16 | r << 24;
#endif
}

static inline int morton_index(const int x, const int y, const int numblocks_x, const int numblocks_y)
{
    const int min_dim = numblocks_x <= numblocks_y ? numblocks_x : numblocks_y;
    int offset = 0, shift = 0;
    for (int mask = 1; mask < min_dim; mask <<= 1, shift++) {
        offset |= (((y & mask) | ((x & mask) << 1))) << shift;
    }
    offset |= ((x | y) >> shift) << (shift * 2);
    return offset;
}

static void applicate_color_4bpp(const uint8_t* data, const PVRTCTexelColor colors[9], uint32_t buf[16])
{
    typedef struct {
        uint16_t a_r;
        uint16_t a_g;
        uint16_t a_b;
        uint16_t a_a;
        uint16_t b_r;
        uint16_t b_g;
        uint16_t b_b;
        uint16_t b_a;
    } PVRTCInterpColor;

    static const int INTERP_WEIGHT[4][3] = { { 2, 2, 0 }, { 1, 3, 0 }, { 0, 4, 0 }, { 0, 3, 1 } };
    PVRTCInterpColor interp_colors[16] = {};

    for (int cy = 0, c = 0; cy < 4; cy++) {
        for (int cx = 0; cx < 4; cx++, c++) {
            for (int acy = 0, ac = 0; acy < 3; acy++) {
                for (int acx = 0; acx < 3; acx++, ac++) {
                    int interp_weight = INTERP_WEIGHT[cx][acx] * INTERP_WEIGHT[cy][acy];
                    interp_colors[c].a_r += colors[ac].a_r * interp_weight;
                    interp_colors[c].a_g += colors[ac].a_g * interp_weight;
                    interp_colors[c].a_b += colors[ac].a_b * interp_weight;
                    interp_colors[c].a_a += colors[ac].a_a * interp_weight;
                    interp_colors[c].b_r += colors[ac].b_r * interp_weight;
                    interp_colors[c].b_g += colors[ac].b_g * interp_weight;
                    interp_colors[c].b_b += colors[ac].b_b * interp_weight;
                    interp_colors[c].b_a += colors[ac].b_a * interp_weight;
                }
            }
            interp_colors[c].a_r = (interp_colors[c].a_r >> 1) + (interp_colors[c].a_r >> 6);
            interp_colors[c].a_g = (interp_colors[c].a_g >> 1) + (interp_colors[c].a_g >> 6);
            interp_colors[c].a_b = (interp_colors[c].a_b >> 1) + (interp_colors[c].a_b >> 6);
            interp_colors[c].a_a = (interp_colors[c].a_a) + (interp_colors[c].a_a >> 4);
            interp_colors[c].b_r = (interp_colors[c].b_r >> 1) + (interp_colors[c].b_r >> 6);
            interp_colors[c].b_g = (interp_colors[c].b_g >> 1) + (interp_colors[c].b_g >> 6);
            interp_colors[c].b_b = (interp_colors[c].b_b >> 1) + (interp_colors[c].b_b >> 6);
            interp_colors[c].b_a = (interp_colors[c].b_a) + (interp_colors[c].b_a >> 4);
        }
    }

    int mod_mode = data[4] & 1;
#if BYTE_ORDER == LITTLE_ENDIAN
    uint32_t mod_bits = *(uint32_t*)data;
#else
    uint32_t mod_bits = data[0] | data[1] << 8 | data[2] << 16 | data[3] << 24;
#endif

    if (mod_mode) {
        // punch-through
        for (int i = 0; i < 16; i++, mod_bits >>= 2) {
            int r, g, b, a;
            switch (mod_bits & 3) {
            case 0:
                r = interp_colors[i].a_r;
                g = interp_colors[i].a_g;
                b = interp_colors[i].a_b;
                a = interp_colors[i].a_a;
                break;
            case 3:
                r = interp_colors[i].b_r;
                g = interp_colors[i].b_g;
                b = interp_colors[i].b_b;
                a = interp_colors[i].b_a;
                break;
            default:
                r = (interp_colors[i].a_r + interp_colors[i].b_r) / 2;
                g = (interp_colors[i].a_g + interp_colors[i].b_g) / 2;
                b = (interp_colors[i].a_b + interp_colors[i].b_b) / 2;
                a = (mod_bits & 3) == 2 ? 0 : (interp_colors[i].a_a + interp_colors[i].b_a) / 2;
            }
            buf[i] = color(r, g, b, a);
        }
    } else {
        // standard
        for (int i = 0; i < 16; i++, mod_bits >>= 2) {
            int r, g, b, a;
            switch (mod_bits & 3) {
            case 0:
                r = interp_colors[i].a_r;
                g = interp_colors[i].a_g;
                b = interp_colors[i].a_b;
                a = interp_colors[i].a_a;
                break;
            case 1:
                r = (interp_colors[i].a_r * 5 + interp_colors[i].b_r * 3) / 8;
                g = (interp_colors[i].a_g * 5 + interp_colors[i].b_g * 3) / 8;
                b = (interp_colors[i].a_b * 5 + interp_colors[i].b_b * 3) / 8;
                a = (interp_colors[i].a_a * 5 + interp_colors[i].b_a * 3) / 8;
                break;
            case 2:
                r = (interp_colors[i].a_r * 3 + interp_colors[i].b_r * 5) / 8;
                g = (interp_colors[i].a_g * 3 + interp_colors[i].b_g * 5) / 8;
                b = (interp_colors[i].a_b * 3 + interp_colors[i].b_b * 5) / 8;
                a = (interp_colors[i].a_a * 3 + interp_colors[i].b_a * 5) / 8;
                break;
            case 3:
                r = interp_colors[i].b_r;
                g = interp_colors[i].b_g;
                b = interp_colors[i].b_b;
                a = interp_colors[i].b_a;
                break;
            }
            buf[i] = color(r, g, b, a);
        }
    }
}

static inline void expand_color(const uint8_t* data, PVRTCTexelColor* color)
{
#if BYTE_ORDER == LITTLE_ENDIAN
    uint16_t ca = *(uint16_t*)(data + 4);
    uint16_t cb = *(uint16_t*)(data + 6);
#else
    uint16_t ca = data[4] | data[5] << 8;
    uint16_t cb = data[6] | data[7] << 8;
#endif
    if (ca & 0x8000) {
        color->a_r = ca >> 10 & 0x1f;
        color->a_g = ca >> 5 & 0x1f;
        color->a_b = (ca & 0x1e) | (ca >> 4 & 1);
        color->a_a = 0xf;
    } else {
        color->a_r = (ca >> 7 & 0x1e) | (ca >> 11 & 1);
        color->a_g = (ca >> 3 & 0x1e) | (ca >> 7 & 1);
        color->a_b = (ca << 1 & 0x1c) | (ca >> 2 & 3);
        color->a_a = ca >> 11 & 0xe;
    }
    if (cb & 0x8000) {
        color->b_r = cb >> 10 & 0x1f;
        color->b_g = cb >> 5 & 0x1f;
        color->b_b = cb & 0x1f;
        color->b_a = 0xf;
    } else {
        color->b_r = (cb >> 7 & 0x1e) | (cb >> 11 & 1);
        color->b_g = (cb >> 3 & 0x1e) | (cb >> 7 & 1);
        color->b_b = (cb << 1 & 0x1e) | (cb >> 3 & 1);
        color->b_a = cb >> 11 & 0xe;
    }
}

int decode_pvrtc_4bpp(const uint8_t* data, const int w, const int h, uint32_t* image)
{
    int num_blocks_x = (w + 3) / 4;
    int num_blocks_y = (h + 3) / 4;
    int num_blocks = num_blocks_x * num_blocks_y;
    int copy_length_last = (w + 3) % 4 + 1;

    PVRTCTexelColor* texel_colors = (PVRTCTexelColor*)malloc(sizeof(PVRTCTexelColor) * num_blocks);
    if (texel_colors == NULL)
        return 0;
    const uint8_t* d = data;
    for (int i = 0; i < num_blocks; i++, d += 8)
        expand_color(d, texel_colors + i);

    int* morton_table_buf = (int*)malloc(sizeof(int) * num_blocks);
    if (morton_table_buf == NULL) {
        free(texel_colors);
        return 0;
    }
    for (int y = 0; y < num_blocks_y; y++)
        for (int x = 0; x < num_blocks_x; x++)
            MORTON_POS(x, y) = morton_index(x, y, num_blocks_x, num_blocks_y);

    uint32_t buffer[16];
    uint32_t* buffer_end = buffer + 16;
    PVRTCTexelColor colors[9];
    int pos_x[3], pos_y[3];
    for (int by = 0; by < num_blocks_y; by++) {
        pos_y[0] = by == 0 ? 0 : by - 1;
        pos_y[1] = by;
        pos_y[2] = by == num_blocks_y - 1 ? num_blocks_y - 1 : by + 1;
        for (int bx = 0, x = 0; bx < num_blocks_x; bx++, d += 8, x += 4) {
            pos_x[0] = bx == 0 ? 0 : bx - 1;
            pos_x[1] = bx;
            pos_x[2] = bx == num_blocks_x - 1 ? num_blocks_x - 1 : bx + 1;
            for (int cy = 0, c = 0; cy < 3; cy++)
                for (int cx = 0; cx < 3; cx++, c++)
                    colors[c] = texel_colors[MORTON_POS(pos_x[cx], pos_y[cy])];
            applicate_color_4bpp(data + MORTON_POS(bx, by) * 8, colors, buffer);
            int copy_length = (bx < num_blocks_x - 1 ? 4 : copy_length_last) * 4;
            uint32_t* b = buffer;
            for (int y = h - by * 4 - 1; b < buffer_end && y >= 0; y--, b += 4)
                memcpy(image + y * w + x, b, copy_length);
        }
    }

    free(morton_table_buf);
    free(texel_colors);
    return 1;
}
