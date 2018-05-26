#ifndef DXTC_H
#define DXTC_H

#include <stdint.h>

void decode_dxt1(const uint64_t*, const int, const int, uint32_t*);
void decode_dxt5(const uint64_t*, const int, const int, uint32_t*);

#endif /* end of include guard: DXTC_H */
