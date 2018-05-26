#include <stdlib.h>
#include <stdint.h>
#include <ruby.h>
#include "astc.h"
#include "rgb.h"

static VALUE rb_decode_rgb565(VALUE self, VALUE rb_data, VALUE size, VALUE big) {
    uint8_t *image = (uint8_t*)malloc(FIX2LONG(size) * 3);
    decode_rgb565((uint16_t*)RSTRING_PTR(rb_data), FIX2INT(size), RTEST(big), image);
    VALUE ret = rb_str_new((char*)image, FIX2LONG(size) * 3);
    free(image);
    return ret;
}

static VALUE rb_decode_astc(VALUE self, VALUE rb_data, VALUE w, VALUE h, VALUE bw, VALUE bh) {
    const uint8_t *data = (uint8_t*)RSTRING_PTR(rb_data);
    uint32_t *image = (uint32_t*)calloc(FIX2LONG(w) * FIX2LONG(h), sizeof(uint32_t));
    decode_astc(data, FIX2INT(w), FIX2INT(h), FIX2INT(bw), FIX2INT(bh), image);
    VALUE ret = rb_str_new((char*)image, FIX2LONG(w) * FIX2LONG(h) * sizeof(uint32_t));
    free(image);
    return ret;
}

void Init_native() {
    VALUE mMikunyan = rb_define_module("Mikunyan");
    VALUE mDecodeHelper = rb_define_module_under(mMikunyan, "DecodeHelper");
	rb_define_module_function(mDecodeHelper, "decode_astc", rb_decode_astc, 5);
    rb_define_module_function(mDecodeHelper, "decode_rgb565", rb_decode_rgb565, 3);
}
