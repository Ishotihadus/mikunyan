#include <stdint.h>

static inline int is_system_little() {
    int x = 1;
    return *(char*)&x == 1;
}

void decode_rgb565(const uint16_t* data, const int size, const int is_big_endian, uint8_t* image) {
    const uint16_t *d = data;
    uint8_t *p = image;
    if (is_big_endian == is_system_little()) {
        for (int i = 0; i < size; i++, d++, p += 3) {
            uint8_t r = *d & 0x00f8;
            uint8_t g = (*d & 0x0007) << 5 | (*d & 0xe000) >> 11;
            uint8_t b = (*d & 0x1f00) >> 5;
            p[0] = r | r >> 5;
            p[1] = g | g >> 6;
            p[2] = b | b >> 5;
        }
    } else {
        for (int i = 0; i < size; i++, d++, p += 3) {
            uint8_t r = (*d & 0xf800) >> 8;
            uint8_t g = (*d & 0x07e0) >> 3;
            uint8_t b = (*d & 0x001f) << 3;
            p[0] = r | r >> 5;
            p[1] = g | g >> 6;
            p[2] = b | b >> 5;
        }
    }
}
