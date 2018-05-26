#include <stdint.h>

static inline int is_system_little() {
    int x = 1;
    return *(char*)&x == 1;
}

void decode_rgb565(const uint16_t* data, const int size, const int is_big_endian, uint8_t* image) {
    const uint16_t *d = data;
    if (is_big_endian == is_system_little()) {
        uint8_t *p = image;
        for (int i = 0; i < size; i++, d++, p += 4) {
            uint_fast8_t r = *d & 0x00f8;
            uint_fast8_t g = (*d & 0x0007) << 5 | (*d & 0xe000) >> 11;
            uint_fast8_t b = (*d & 0x1f00) >> 5;
            p[0] = r | r >> 5;
            p[1] = g | g >> 6;
            p[2] = b | b >> 5;
            p[3] = 255;
        }
    } else {
        uint32_t *p = (uint32_t*)image;
        for (int i = 0; i < size; i++, d++, p++)
            *p = (*d & 0xf800) >> 8 | *d >> 13 | (*d & 0x7e0) << 5 | (*d & 0x60) << 3 | *d << 19 | (*d & 0x1c) << 14 | 0xff000000;
    }
}
