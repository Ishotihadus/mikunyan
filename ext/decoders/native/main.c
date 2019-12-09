#include "astc.h"
#include "dxtc.h"
#include "etc.h"
#include "rgb.h"
#include <ruby.h>
#include <stdint.h>
#include <stdlib.h>

/*
 * Decode image from A8 binary
 *
 * @param [String] rb_data binary to decode
 * @param [Integer] size width * height
 * @return [String] decoded rgb binary
 */
static VALUE rb_decode_a8(VALUE self, VALUE rb_data, VALUE size)
{
    if (RSTRING_LEN(rb_data) < FIX2LONG(size))
        rb_raise(rb_eStandardError, "Data size is not enough.");
    VALUE ret = rb_str_buf_new(FIX2LONG(size) * 3);
    decode_a8((uint8_t*)RSTRING_PTR(rb_data), FIX2INT(size), (uint8_t*)RSTRING_PTR(ret));
    rb_str_set_len(ret, FIX2LONG(size) * 3);
    return ret;
}

/*
 * Decode image from R16 binary
 *
 * @param [String] rb_data binary to decode
 * @param [Integer] size width * height
 * @param [Boolean] big whether input data are big endian
 * @return [String] decoded rgb binary
 */
static VALUE rb_decode_r16(VALUE self, VALUE rb_data, VALUE size, VALUE big)
{
    if (RSTRING_LEN(rb_data) < FIX2LONG(size) * 2)
        rb_raise(rb_eStandardError, "Data size is not enough.");
    VALUE ret = rb_str_buf_new(FIX2LONG(size) * 3);
    decode_r16((uint16_t*)RSTRING_PTR(rb_data), FIX2INT(size), RTEST(big), (uint8_t*)RSTRING_PTR(ret));
    rb_str_set_len(ret, FIX2LONG(size) * 3);
    return ret;
}

/*
 * Decode image from RGB565 binary
 *
 * @param [String] rb_data binary to decode
 * @param [Integer] size width * height
 * @param [Boolean] big whether input data are big endian
 * @return [String] decoded rgb binary
 */
static VALUE rb_decode_rgb565(VALUE self, VALUE rb_data, VALUE size, VALUE big)
{
    if (RSTRING_LEN(rb_data) < FIX2LONG(size) * 2)
        rb_raise(rb_eStandardError, "Data size is not enough.");
    VALUE ret = rb_str_buf_new(FIX2LONG(size) * 3);
    decode_rgb565((uint16_t*)RSTRING_PTR(rb_data), FIX2INT(size), RTEST(big), (uint8_t*)RSTRING_PTR(ret));
    rb_str_set_len(ret, FIX2LONG(size) * 3);
    return ret;
}

/*
 * Decode image from ETC1 compressed binary
 *
 * @param [String] rb_data binary to decode
 * @param [Integer] w image width
 * @param [Integer] h image height
 * @return [String] decoded rgba binary
 */
static VALUE rb_decode_etc1(VALUE self, VALUE rb_data, VALUE w, VALUE h)
{
    if (RSTRING_LEN(rb_data) < ((FIX2LONG(w) + 3) / 4) * ((FIX2LONG(h) + 3) / 4) * 8)
        rb_raise(rb_eStandardError, "Data size is not enough.");
    uint32_t* image = (uint32_t*)calloc(FIX2LONG(w) * FIX2LONG(h), sizeof(uint32_t));
    decode_etc1((uint64_t*)RSTRING_PTR(rb_data), FIX2INT(w), FIX2INT(h), image);
    VALUE ret = rb_str_new((char*)image, FIX2LONG(w) * FIX2LONG(h) * sizeof(uint32_t));
    free(image);
    return ret;
}

/*
 * Decode image from ETC2 compressed binary
 *
 * @param [String] rb_data binary to decode
 * @param [Integer] w image width
 * @param [Integer] h image height
 * @return [String] decoded rgba binary
 */
static VALUE rb_decode_etc2(VALUE self, VALUE rb_data, VALUE w, VALUE h)
{
    if (RSTRING_LEN(rb_data) < ((FIX2LONG(w) + 3) / 4) * ((FIX2LONG(h) + 3) / 4) * 8)
        rb_raise(rb_eStandardError, "Data size is not enough.");
    uint32_t* image = (uint32_t*)calloc(FIX2LONG(w) * FIX2LONG(h), sizeof(uint32_t));
    decode_etc2((uint64_t*)RSTRING_PTR(rb_data), FIX2INT(w), FIX2INT(h), image);
    VALUE ret = rb_str_new((char*)image, FIX2LONG(w) * FIX2LONG(h) * sizeof(uint32_t));
    free(image);
    return ret;
}

/*
 * Decode image from ETC2 Alpha1 compressed binary
 *
 * @param [String] rb_data binary to decode
 * @param [Integer] w image width
 * @param [Integer] h image height
 * @return [String] decoded rgba binary
 */
static VALUE rb_decode_etc2a1(VALUE self, VALUE rb_data, VALUE w, VALUE h)
{
    if (RSTRING_LEN(rb_data) < ((FIX2LONG(w) + 3) / 4) * ((FIX2LONG(h) + 3) / 4) * 9)
        rb_raise(rb_eStandardError, "Data size is not enough.");
    uint32_t* image = (uint32_t*)calloc(FIX2LONG(w) * FIX2LONG(h), sizeof(uint32_t));
    decode_etc2a8((uint64_t*)RSTRING_PTR(rb_data), FIX2INT(w), FIX2INT(h),
        image);
    VALUE ret = rb_str_new((char*)image, FIX2LONG(w) * FIX2LONG(h) * sizeof(uint32_t));
    free(image);
    return ret;
}

/*
 * Decode image from ETC2 Alpha8 compressed binary
 *
 * @param [String] rb_data binary to decode
 * @param [Integer] w image width
 * @param [Integer] h image height
 * @return [String] decoded rgba binary
 */
static VALUE rb_decode_etc2a8(VALUE self, VALUE rb_data, VALUE w, VALUE h)
{
    if (RSTRING_LEN(rb_data) < ((FIX2LONG(w) + 3) / 4) * ((FIX2LONG(h) + 3) / 4) * 16)
        rb_raise(rb_eStandardError, "Data size is not enough.");
    uint32_t* image = (uint32_t*)calloc(FIX2LONG(w) * FIX2LONG(h), sizeof(uint32_t));
    decode_etc2a8((uint64_t*)RSTRING_PTR(rb_data), FIX2INT(w), FIX2INT(h),
        image);
    VALUE ret = rb_str_new((char*)image, FIX2LONG(w) * FIX2LONG(h) * sizeof(uint32_t));
    free(image);
    return ret;
}

/*
 * Decode image from ASTC compressed binary
 *
 * @param [String] rb_data binary to decode
 * @param [Integer] w image width
 * @param [Integer] h image height
 * @param [Integer] bw block width
 * @param [Integer] bh block height
 * @return [String] decoded rgba binary
 */
static VALUE rb_decode_astc(VALUE self, VALUE rb_data, VALUE w, VALUE h,
    VALUE bw, VALUE bh)
{
    if (RSTRING_LEN(rb_data) < ((FIX2LONG(w) + FIX2LONG(bw) - 1) / FIX2LONG(bw)) * ((FIX2LONG(h) + FIX2LONG(bh) - 1) / FIX2LONG(bh)) * 16)
        rb_raise(rb_eStandardError, "Data size is not enough.");
    const uint8_t* data = (uint8_t*)RSTRING_PTR(rb_data);
    uint32_t* image = (uint32_t*)calloc(FIX2LONG(w) * FIX2LONG(h), sizeof(uint32_t));
    decode_astc(data, FIX2INT(w), FIX2INT(h), FIX2INT(bw), FIX2INT(bh), image);
    VALUE ret = rb_str_new((char*)image, FIX2LONG(w) * FIX2LONG(h) * sizeof(uint32_t));
    free(image);
    return ret;
}

/*
 * Decode image from DXT1 compressed binary
 *
 * @param [String] rb_data binary to decode
 * @param [Integer] w image width
 * @param [Integer] h image height
 * @return [String] decoded rgba binary
 */
static VALUE rb_decode_dxt1(VALUE self, VALUE rb_data, VALUE w, VALUE h)
{
    if (RSTRING_LEN(rb_data) < ((FIX2LONG(w) + 3) / 4) * ((FIX2LONG(h) + 3) / 4) * 8)
        rb_raise(rb_eStandardError, "Data size is not enough.");
    uint32_t* image = (uint32_t*)calloc(FIX2LONG(w) * FIX2LONG(h), sizeof(uint32_t));
    decode_dxt1((uint64_t*)RSTRING_PTR(rb_data), FIX2INT(w), FIX2INT(h), image);
    VALUE ret = rb_str_new((char*)image, FIX2LONG(w) * FIX2LONG(h) * sizeof(uint32_t));
    free(image);
    return ret;
}

/*
 * Decode image from DXT5 compressed binary
 *
 * @param [String] rb_data binary to decode
 * @param [Integer] w image width
 * @param [Integer] h image height
 * @return [String] decoded rgba binary
 */
static VALUE rb_decode_dxt5(VALUE self, VALUE rb_data, VALUE w, VALUE h)
{
    if (RSTRING_LEN(rb_data) < ((FIX2LONG(w) + 3) / 4) * ((FIX2LONG(h) + 3) / 4) * 16)
        rb_raise(rb_eStandardError, "Data size is not enough.");
    uint32_t* image = (uint32_t*)calloc(FIX2LONG(w) * FIX2LONG(h), sizeof(uint32_t));
    decode_dxt5((uint64_t*)RSTRING_PTR(rb_data), FIX2INT(w), FIX2INT(h), image);
    VALUE ret = rb_str_new((char*)image, FIX2LONG(w) * FIX2LONG(h) * sizeof(uint32_t));
    free(image);
    return ret;
}

void Init_native()
{
    VALUE mMikunyan = rb_define_module("Mikunyan");
    VALUE mDecodeHelper = rb_define_module_under(mMikunyan, "DecodeHelper");
    rb_define_module_function(mDecodeHelper, "decode_a8", rb_decode_a8, 2);
    rb_define_module_function(mDecodeHelper, "decode_r16", rb_decode_r16, 3);
    rb_define_module_function(mDecodeHelper, "decode_rgb565", rb_decode_rgb565, 3);
    rb_define_module_function(mDecodeHelper, "decode_etc1", rb_decode_etc1, 3);
    rb_define_module_function(mDecodeHelper, "decode_etc2", rb_decode_etc2, 3);
    rb_define_module_function(mDecodeHelper, "decode_etc2a1", rb_decode_etc2a1, 3);
    rb_define_module_function(mDecodeHelper, "decode_etc2a8", rb_decode_etc2a8, 3);
    rb_define_module_function(mDecodeHelper, "decode_astc", rb_decode_astc, 5);
    rb_define_module_function(mDecodeHelper, "decode_dxt1", rb_decode_dxt1, 3);
    rb_define_module_function(mDecodeHelper, "decode_dxt5", rb_decode_dxt5, 3);
}
