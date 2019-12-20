#include <ruby.h>
#include <stdint.h>
#include <stdlib.h>
#include "astc.h"
#include "dxtc.h"
#include "etc.h"
#include "pvrtc.h"
#include "rgb.h"

const char *error_msg = NULL;

#define DECODE_CHECK(call)                                                                  \
    if (!call) {                                                                            \
        rb_raise(rb_eRuntimeError, "%s", error_msg ? error_msg : "unknown internal error"); \
        error_msg = NULL;                                                                   \
        return Qnil;                                                                        \
    }

static int check_str_len(VALUE data, long len, long unit) {
    if (RSTRING_LEN(data) < len * unit) {
        rb_raise(rb_eStandardError, "Data size is not enough.");
        return 0;
    }
    return 1;
}

static int check_str_len_block(VALUE data, long w, long h, long bw, long bh, long unit) {
    long size = ((w + bw - 1) / bw) * ((h + bh - 1) / bh);
    return check_str_len(data, size, unit);
}

static VALUE rb_alloc_rgb(long n) {
    VALUE ret = rb_str_buf_new(n * 3);
    rb_str_set_len(ret, n * 3);
    return ret;
}

static VALUE rb_alloc_rgba(long n) {
    VALUE ret = rb_str_buf_new(n * 4);
    rb_str_set_len(ret, n * 4);
    return ret;
}

/*
 * Decode image from A8 binary
 * Returned image is not flipped
 *
 * @param [String] rb_data binary to decode
 * @param [Integer] rb_size width * height
 * @return [String] decoded rgb binary
 */
static VALUE rb_decode_a8(VALUE self, VALUE rb_data, VALUE rb_size) {
    long size = FIX2LONG(rb_size);
    if (!check_str_len(rb_data, size, 1))
        return Qnil;
    VALUE ret = rb_alloc_rgb(size);
    if (!decode_a8((uint8_t *)RSTRING_PTR(rb_data), size, (uint8_t *)RSTRING_PTR(ret)))
        return Qnil;
    return ret;
}

/*
 * Decode image from R8 binary
 * Returned image is not flipped
 *
 * @param [String] rb_data binary to decode
 * @param [Integer] rb_size width * height
 * @return [String] decoded rgb binary
 */
static VALUE rb_decode_r8(VALUE self, VALUE rb_data, VALUE rb_size) {
    long size = FIX2LONG(rb_size);
    if (!check_str_len(rb_data, size, 1))
        return Qnil;
    VALUE ret = rb_alloc_rgb(size);
    if (!decode_r8((uint8_t *)RSTRING_PTR(rb_data), size, (uint8_t *)RSTRING_PTR(ret)))
        return Qnil;
    return ret;
}

/*
 * Decode image from R16 binary
 * Returned image is not flipped
 *
 * @param [String] rb_data binary to decode
 * @param [Integer] rb_size width * height
 * @param [Boolean] rb_big whether input data are big endian
 * @return [String] decoded rgb binary
 */
static VALUE rb_decode_r16(VALUE self, VALUE rb_data, VALUE rb_size, VALUE rb_big) {
    long size = FIX2LONG(rb_size);
    if (!check_str_len(rb_data, size, 2))
        return Qnil;
    VALUE ret = rb_alloc_rgb(size);
    if (!decode_r16((uint8_t *)RSTRING_PTR(rb_data), size, RTEST(rb_big), (uint8_t *)RSTRING_PTR(ret)))
        return Qnil;
    return ret;
}

/*
 * Decode image from RGB565 binary
 * Returned image is not flipped
 *
 * @param [String] rb_data binary to decode
 * @param [Integer] rb_size width * height
 * @param [Boolean] rb_big whether input data are big endian
 * @return [String] decoded rgb binary
 */
static VALUE rb_decode_rgb565(VALUE self, VALUE rb_data, VALUE rb_size, VALUE rb_big) {
    long size = FIX2LONG(rb_size);
    if (!check_str_len(rb_data, size, 2))
        return Qnil;
    VALUE ret = rb_alloc_rgb(size);
    if (!decode_rgb565((uint16_t *)RSTRING_PTR(rb_data), size, RTEST(rb_big), (uint8_t *)RSTRING_PTR(ret)))
        return Qnil;
    return ret;
}

/*
 * Decode image from RHalf binary
 * Returned image is not flipped
 *
 * @param [String] rb_data binary to decode
 * @param [Integer] rb_size width * height
 * @param [Boolean] rb_big whether input data are big endian
 * @return [String] decoded rgb binary
 */
static VALUE rb_decode_rhalf(VALUE self, VALUE rb_data, VALUE rb_size, VALUE rb_big) {
    long size = FIX2LONG(rb_size);
    if (!check_str_len(rb_data, size, 2))
        return Qnil;
    VALUE ret = rb_alloc_rgb(size);
    if (!decode_rhalf((uint16_t *)RSTRING_PTR(rb_data), size, RTEST(rb_big), (uint8_t *)RSTRING_PTR(ret)))
        return Qnil;
    return ret;
}

/*
 * Decode image from RGHalf binary
 * Returned image is not flipped
 *
 * @param [String] rb_data binary to decode
 * @param [Integer] rb_size width * height
 * @param [Boolean] rb_big whether input data are big endian
 * @return [String] decoded rgb binary
 */
static VALUE rb_decode_rghalf(VALUE self, VALUE rb_data, VALUE rb_size, VALUE rb_big) {
    long size = FIX2LONG(rb_size);
    if (!check_str_len(rb_data, size, 4))
        return Qnil;
    VALUE ret = rb_alloc_rgb(size);
    if (!decode_rghalf((uint16_t *)RSTRING_PTR(rb_data), size, RTEST(rb_big), (uint8_t *)RSTRING_PTR(ret)))
        return Qnil;
    return ret;
}

/*
 * Decode image from RGBAHalf binary
 * Returned image is not flipped
 *
 * @param [String] rb_data binary to decode
 * @param [Integer] rb_size width * height
 * @param [Boolean] rb_big whether input data are big endian
 * @return [String] decoded rgba binary
 */
static VALUE rb_decode_rgbahalf(VALUE self, VALUE rb_data, VALUE rb_size, VALUE rb_big) {
    long size = FIX2LONG(rb_size);
    if (!check_str_len(rb_data, size, 8))
        return Qnil;
    VALUE ret = rb_alloc_rgba(size);
    if (!decode_rgbahalf((uint16_t *)RSTRING_PTR(rb_data), size, RTEST(rb_big), (uint8_t *)RSTRING_PTR(ret)))
        return Qnil;
    return ret;
}

/*
 * Decode image from ETC1 compressed binary
 *
 * @param [String] rb_data binary to decode
 * @param [Integer] rb_w image width
 * @param [Integer] rb_h image height
 * @return [String] decoded rgba binary
 */
static VALUE rb_decode_etc1(VALUE self, VALUE rb_data, VALUE rb_w, VALUE rb_h) {
    long w = FIX2LONG(rb_w), h = FIX2LONG(rb_h);
    if (!check_str_len_block(rb_data, w, h, 4, 4, 8))
        return Qnil;
    VALUE ret = rb_alloc_rgba(w * h);
    if (!decode_etc1((uint8_t *)RSTRING_PTR(rb_data), w, h, (uint32_t *)RSTRING_PTR(ret)))
        return Qnil;
    return ret;
}

/*
 * Decode image from ETC2 compressed binary
 *
 * @param [String] rb_data binary to decode
 * @param [Integer] rb_w image width
 * @param [Integer] rb_h image height
 * @return [String] decoded rgba binary
 */
static VALUE rb_decode_etc2(VALUE self, VALUE rb_data, VALUE rb_w, VALUE rb_h) {
    long w = FIX2LONG(rb_w), h = FIX2LONG(rb_h);
    if (!check_str_len_block(rb_data, w, h, 4, 4, 8))
        return Qnil;
    VALUE ret = rb_alloc_rgba(w * h);
    if (!decode_etc2((uint8_t *)RSTRING_PTR(rb_data), w, h, (uint32_t *)RSTRING_PTR(ret)))
        return Qnil;
    return ret;
}

/*
 * Decode image from ETC2 Alpha1 compressed binary
 *
 * @param [String] rb_data binary to decode
 * @param [Integer] rb_w image width
 * @param [Integer] rb_h image height
 * @return [String] decoded rgba binary
 */
static VALUE rb_decode_etc2a1(VALUE self, VALUE rb_data, VALUE rb_w, VALUE rb_h) {
    long w = FIX2LONG(rb_w), h = FIX2LONG(rb_h);
    if (!check_str_len_block(rb_data, w, h, 4, 4, 8))
        return Qnil;
    VALUE ret = rb_alloc_rgba(w * h);
    if (!decode_etc2a1((uint8_t *)RSTRING_PTR(rb_data), w, h, (uint32_t *)RSTRING_PTR(ret)))
        return Qnil;
    return ret;
}

/*
 * Decode image from ETC2 Alpha8 compressed binary
 *
 * @param [String] rb_data binary to decode
 * @param [Integer] rb_w image width
 * @param [Integer] rb_h image height
 * @return [String] decoded rgba binary
 */
static VALUE rb_decode_etc2a8(VALUE self, VALUE rb_data, VALUE rb_w, VALUE rb_h) {
    long w = FIX2LONG(rb_w), h = FIX2LONG(rb_h);
    if (!check_str_len_block(rb_data, w, h, 4, 4, 16))
        return Qnil;
    VALUE ret = rb_alloc_rgba(w * h);
    if (!decode_etc2a8((uint8_t *)RSTRING_PTR(rb_data), w, h, (uint32_t *)RSTRING_PTR(ret)))
        return Qnil;
    return ret;
}

/*
 * Decode image from EAC R11 compressed binary
 *
 * @param [String] rb_data binary to decode
 * @param [Integer] rb_w image width
 * @param [Integer] rb_h image height
 * @return [String] decoded rgba binary
 */
static VALUE rb_decode_eacr(VALUE self, VALUE rb_data, VALUE rb_w, VALUE rb_h) {
    long w = FIX2LONG(rb_w), h = FIX2LONG(rb_h);
    if (!check_str_len_block(rb_data, w, h, 4, 4, 8))
        return Qnil;
    VALUE ret = rb_alloc_rgba(w * h);
    if (!decode_eacr((uint8_t *)RSTRING_PTR(rb_data), w, h, (uint32_t *)RSTRING_PTR(ret)))
        return Qnil;
    return ret;
}

/*
 * Decode image from EAC Signed R11 compressed binary
 *
 * @param [String] rb_data binary to decode
 * @param [Integer] rb_w image width
 * @param [Integer] rb_h image height
 * @return [String] decoded rgba binary
 */
static VALUE rb_decode_eacsr(VALUE self, VALUE rb_data, VALUE rb_w, VALUE rb_h) {
    long w = FIX2LONG(rb_w), h = FIX2LONG(rb_h);
    if (!check_str_len_block(rb_data, w, h, 4, 4, 8))
        return Qnil;
    VALUE ret = rb_alloc_rgba(w * h);
    if (!decode_eacr_signed((uint8_t *)RSTRING_PTR(rb_data), w, h, (uint32_t *)RSTRING_PTR(ret)))
        return Qnil;
    return ret;
}

/*
 * Decode image from EAC RG11 compressed binary
 *
 * @param [String] rb_data binary to decode
 * @param [Integer] rb_w image width
 * @param [Integer] rb_h image height
 * @return [String] decoded rgba binary
 */
static VALUE rb_decode_eacrg(VALUE self, VALUE rb_data, VALUE rb_w, VALUE rb_h) {
    long w = FIX2LONG(rb_w), h = FIX2LONG(rb_h);
    if (!check_str_len_block(rb_data, w, h, 4, 4, 16))
        return Qnil;
    VALUE ret = rb_alloc_rgba(w * h);
    if (!decode_eacrg((uint8_t *)RSTRING_PTR(rb_data), w, h, (uint32_t *)RSTRING_PTR(ret)))
        return Qnil;
    return ret;
}

/*
 * Decode image from EAC RG11 compressed binary
 *
 * @param [String] rb_data binary to decode
 * @param [Integer] rb_w image width
 * @param [Integer] rb_h image height
 * @return [String] decoded rgba binary
 */
static VALUE rb_decode_eacsrg(VALUE self, VALUE rb_data, VALUE rb_w, VALUE rb_h) {
    long w = FIX2LONG(rb_w), h = FIX2LONG(rb_h);
    if (!check_str_len_block(rb_data, w, h, 4, 4, 16))
        return Qnil;
    VALUE ret = rb_alloc_rgba(w * h);
    if (!decode_eacrg_signed((uint8_t *)RSTRING_PTR(rb_data), w, h, (uint32_t *)RSTRING_PTR(ret)))
        return Qnil;
    return ret;
}

/*
 * Decode image from ASTC compressed binary
 *
 * @param [String] rb_data binary to decode
 * @param [Integer] rb_w image width
 * @param [Integer] rb_h image height
 * @param [Integer] rb_bw block width
 * @param [Integer] rb_bh block height
 * @return [String] decoded rgba binary
 */
static VALUE rb_decode_astc(VALUE self, VALUE rb_data, VALUE rb_w, VALUE rb_h, VALUE rb_bw, VALUE rb_bh) {
    long w = FIX2LONG(rb_w);
    long h = FIX2LONG(rb_h);
    int bw = FIX2INT(rb_bw);
    int bh = FIX2INT(rb_bh);
    if (!check_str_len_block(rb_data, w, h, bw, bh, 16))
        return Qnil;
    VALUE ret = rb_alloc_rgba(w * h);
    DECODE_CHECK(decode_astc((uint8_t *)RSTRING_PTR(rb_data), w, h, bw, bh, (uint32_t *)RSTRING_PTR(ret)));
    return ret;
}

/*
 * Decode image from DXT1 compressed binary
 *
 * @param [String] rb_data binary to decode
 * @param [Integer] rb_w image width
 * @param [Integer] rb_h image height
 * @return [String] decoded rgba binary
 */
static VALUE rb_decode_dxt1(VALUE self, VALUE rb_data, VALUE rb_w, VALUE rb_h) {
    long w = FIX2LONG(rb_w);
    long h = FIX2LONG(rb_h);
    if (!check_str_len_block(rb_data, w, h, 4, 4, 8))
        return Qnil;
    VALUE ret = rb_alloc_rgba(w * h);
    DECODE_CHECK(decode_dxt1((uint8_t *)RSTRING_PTR(rb_data), w, h, (uint32_t *)RSTRING_PTR(ret)));
    return ret;
}

/*
 * Decode image from DXT5 compressed binary
 *
 * @param [String] rb_data binary to decode
 * @param [Integer] rb_w image width
 * @param [Integer] rb_h image height
 * @return [String] decoded rgba binary
 */
static VALUE rb_decode_dxt5(VALUE self, VALUE rb_data, VALUE rb_w, VALUE rb_h) {
    long w = FIX2LONG(rb_w);
    long h = FIX2LONG(rb_h);
    if (!check_str_len_block(rb_data, w, h, 4, 4, 16))
        return Qnil;
    VALUE ret = rb_alloc_rgba(w * h);
    DECODE_CHECK(decode_dxt5((uint8_t *)RSTRING_PTR(rb_data), w, h, (uint32_t *)RSTRING_PTR(ret)));
    return ret;
}

/*
 * Decode image from PVRTC1 compressed binary
 *
 * @param [String] rb_data binary to decode
 * @param [Integer] rb_w image width
 * @param [Integer] rb_h image height
 * @param [Boolean] rb_is2bpp whether 2bpp or not (4bpp)
 * @return [String] decoded rgba binary
 */
static VALUE rb_decode_pvrtc1(VALUE self, VALUE rb_data, VALUE rb_w, VALUE rb_h, VALUE rb_is2bpp) {
    int is2bpp = RTEST(rb_is2bpp);
    long w = FIX2LONG(rb_w);
    long h = FIX2LONG(rb_h);
    if (!check_str_len_block(rb_data, w, h, is2bpp ? 8 : 4, 4, 8))
        return Qnil;
    VALUE ret = rb_alloc_rgba(w * h);
    DECODE_CHECK(decode_pvrtc((uint8_t *)RSTRING_PTR(rb_data), w, h, (uint32_t *)RSTRING_PTR(ret), is2bpp));
    return ret;
}

void Init_native() {
    VALUE mMikunyan = rb_define_module("Mikunyan");
    VALUE mDecodeHelper = rb_define_module_under(mMikunyan, "DecodeHelper");
    rb_define_module_function(mDecodeHelper, "decode_a8", rb_decode_a8, 2);
    rb_define_module_function(mDecodeHelper, "decode_r8", rb_decode_r8, 2);
    rb_define_module_function(mDecodeHelper, "decode_r16", rb_decode_r16, 3);
    rb_define_module_function(mDecodeHelper, "decode_rgb565", rb_decode_rgb565, 3);
    rb_define_module_function(mDecodeHelper, "decode_rhalf", rb_decode_rhalf, 3);
    rb_define_module_function(mDecodeHelper, "decode_rghalf", rb_decode_rghalf, 3);
    rb_define_module_function(mDecodeHelper, "decode_rgbahalf", rb_decode_rgbahalf, 3);
    rb_define_module_function(mDecodeHelper, "decode_etc1", rb_decode_etc1, 3);
    rb_define_module_function(mDecodeHelper, "decode_etc2", rb_decode_etc2, 3);
    rb_define_module_function(mDecodeHelper, "decode_etc2a1", rb_decode_etc2a1, 3);
    rb_define_module_function(mDecodeHelper, "decode_etc2a8", rb_decode_etc2a8, 3);
    rb_define_module_function(mDecodeHelper, "decode_eacr", rb_decode_eacr, 3);
    rb_define_module_function(mDecodeHelper, "decode_eacsr", rb_decode_eacsr, 3);
    rb_define_module_function(mDecodeHelper, "decode_eacrg", rb_decode_eacrg, 3);
    rb_define_module_function(mDecodeHelper, "decode_eacsrg", rb_decode_eacsrg, 3);
    rb_define_module_function(mDecodeHelper, "decode_astc", rb_decode_astc, 5);
    rb_define_module_function(mDecodeHelper, "decode_dxt1", rb_decode_dxt1, 3);
    rb_define_module_function(mDecodeHelper, "decode_dxt5", rb_decode_dxt5, 3);
    rb_define_module_function(mDecodeHelper, "decode_pvrtc1", rb_decode_pvrtc1, 4);
}
