#ifndef DXTC_H
#define DXTC_H

#include <stdint.h>

int decode_dxt1(const uint8_t *, const long, const long, uint32_t *);
int decode_dxt5(const uint8_t *, const long, const long, uint32_t *);

#endif /* end of include guard: DXTC_H */
