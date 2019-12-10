#include <cstdio>
#include <cstdlib>
#include <cstring>
#include "crn_decomp.h"
#include <ruby.h>

ID sym_at_data, sym_new;
VALUE stFileInfo, stTextureInfo, stLevelInfo;

static void set_format_constant(VALUE module) {
    rb_const_set(module, rb_intern("INVALID"), LONG2NUM(cCRNFmtInvalid));
    rb_const_set(module, rb_intern("FIRST_VALID"), LONG2NUM(cCRNFmtFirstValid));
    rb_const_set(module, rb_intern("DXT1"), LONG2NUM(cCRNFmtDXT1));
    rb_const_set(module, rb_intern("DXT3"), LONG2NUM(cCRNFmtDXT3));
    rb_const_set(module, rb_intern("DXT5"), LONG2NUM(cCRNFmtDXT5));
    rb_const_set(module, rb_intern("DXT5_CCXY"), LONG2NUM(cCRNFmtDXT5_CCxY));
    rb_const_set(module, rb_intern("DXT5_XGXR"), LONG2NUM(cCRNFmtDXT5_xGxR));
    rb_const_set(module, rb_intern("DXT5_XGBR"), LONG2NUM(cCRNFmtDXT5_xGBR));
    rb_const_set(module, rb_intern("DXT5_AGBR"), LONG2NUM(cCRNFmtDXT5_AGBR));
    rb_const_set(module, rb_intern("DXN_XY"), LONG2NUM(cCRNFmtDXN_XY));
    rb_const_set(module, rb_intern("DXN_YX"), LONG2NUM(cCRNFmtDXN_YX));
    rb_const_set(module, rb_intern("DXT5A"), LONG2NUM(cCRNFmtDXT5A));
    rb_const_set(module, rb_intern("ETC1"), LONG2NUM(cCRNFmtETC1));
    rb_const_set(module, rb_intern("ETC2"), LONG2NUM(cCRNFmtETC2));
    rb_const_set(module, rb_intern("ETC2A"), LONG2NUM(cCRNFmtETC2A));
    rb_const_set(module, rb_intern("ETC1S"), LONG2NUM(cCRNFmtETC1S));
    rb_const_set(module, rb_intern("ETC2AS"), LONG2NUM(cCRNFmtETC2AS));
    rb_const_set(module, rb_intern("TOTAL"), LONG2NUM(cCRNFmtTotal));
}

static VALUE rb_cCrunchStream_file_info(VALUE self) {
    VALUE str = rb_ivar_get(self, sym_at_data);
    crnd::crn_file_info file_info;
    if (!crnd::crnd_validate_file(RSTRING_PTR(str), RSTRING_LENINT(str), &file_info)) {
        rb_raise(rb_eRuntimeError, "cannot get file info (invalid file?)");
        return Qnil;
    }
    VALUE level_compressed_size = rb_ary_new2(file_info.m_levels);
    for (uint32_t i = 0; i < file_info.m_levels; i++)
        rb_ary_push(level_compressed_size, UINT2NUM(file_info.m_level_compressed_size[i]));
    VALUE args[] = {
        UINT2NUM(file_info.m_struct_size),
        UINT2NUM(file_info.m_actual_data_size),
        UINT2NUM(file_info.m_header_size),
        UINT2NUM(file_info.m_total_palette_size),
        UINT2NUM(file_info.m_tables_size),
        UINT2NUM(file_info.m_levels),
        level_compressed_size,
        UINT2NUM(file_info.m_color_endpoint_palette_entries),
        UINT2NUM(file_info.m_color_selector_palette_entries),
        UINT2NUM(file_info.m_alpha_endpoint_palette_entries),
        UINT2NUM(file_info.m_alpha_selector_palette_entries)
    };
    return rb_class_new_instance(sizeof(args) / sizeof(VALUE), args, stFileInfo);
}

static VALUE rb_cCrunchStream_texture_info(VALUE self) {
    VALUE str = rb_ivar_get(self, sym_at_data);
    crnd::crn_texture_info texture_info;
    if (!crnd::crnd_get_texture_info(RSTRING_PTR(str), RSTRING_LENINT(str), &texture_info)) {
        rb_raise(rb_eRuntimeError, "cannot get texture info (invalid file?)");
        return Qnil;
    }
    VALUE args[] = {
        UINT2NUM(texture_info.m_struct_size),
        UINT2NUM(texture_info.m_width),
        UINT2NUM(texture_info.m_height),
        UINT2NUM(texture_info.m_levels),
        UINT2NUM(texture_info.m_faces),
        UINT2NUM(texture_info.m_bytes_per_block),
        UINT2NUM(texture_info.m_userdata0),
        UINT2NUM(texture_info.m_userdata1),
        UINT2NUM(texture_info.m_format)
    };
    return rb_class_new_instance(sizeof(args) / sizeof(VALUE), args, stTextureInfo);
}

static VALUE rb_cCrunchStream_level_info(VALUE self, VALUE rb_level) {
    VALUE str = rb_ivar_get(self, sym_at_data);
    crnd::crn_level_info level_info;
    if (!crnd::crnd_get_level_info(RSTRING_PTR(str), RSTRING_LENINT(str), NUM2UINT(rb_level), &level_info)) {
        rb_raise(rb_eRuntimeError, "cannot get level info (invalid file or invalid level?)");
        return Qnil;
    }
    VALUE args[] = {
        UINT2NUM(level_info.m_struct_size),
        UINT2NUM(level_info.m_width),
        UINT2NUM(level_info.m_height),
        UINT2NUM(level_info.m_faces),
        UINT2NUM(level_info.m_blocks_x),
        UINT2NUM(level_info.m_blocks_y),
        UINT2NUM((level_info.m_width + level_info.m_blocks_x - 1) / level_info.m_blocks_x),
        UINT2NUM((level_info.m_height + level_info.m_blocks_y - 1) / level_info.m_blocks_y),
        UINT2NUM(level_info.m_bytes_per_block),
        UINT2NUM(level_info.m_format)
    };
    return rb_class_new_instance(sizeof(args) / sizeof(VALUE), args, stLevelInfo);
}

static VALUE rb_cCrunchStream_unpack_level(VALUE self, VALUE rb_level) {
    VALUE str = rb_ivar_get(self, sym_at_data);
    crnd::crn_level_info level_info;
    if (!crnd::crnd_get_level_info(RSTRING_PTR(str), RSTRING_LENINT(str), NUM2UINT(rb_level), &level_info)) {
        rb_raise(rb_eRuntimeError, "cannot get level info (invalid file or invalid level?)");
        return Qnil;
    }
    uint32_t pitch_size = level_info.m_blocks_x * level_info.m_bytes_per_block;
    uint32_t size = pitch_size * level_info.m_blocks_y;
    VALUE ret = rb_str_buf_new(size);
    void *ret_ptr = (void*)RSTRING_PTR(ret);
    crnd::crnd_unpack_context context = crnd::crnd_unpack_begin(RSTRING_PTR(str), RSTRING_LENINT(str));
    if (context == nullptr) {
        rb_raise(rb_eRuntimeError, "context creation error");
        return Qnil;
    }
    if (!crnd::crnd_unpack_level(context, &ret_ptr, size, pitch_size, 0)) {
        rb_raise(rb_eRuntimeError, "unpack error");
        return Qnil;
    }
    crnd::crnd_unpack_end(context);
    rb_str_set_len(ret, size);
    return ret;
}

extern "C" {

static VALUE create_rb_struct(const int argc, const char **argv) {
    VALUE *argv_values = (VALUE*)malloc(sizeof(VALUE*) * argc);
    for (int i = 0; i < argc; i++)
        argv_values[i] = ID2SYM(rb_intern(argv[i]));
    VALUE ret = rb_funcall2(rb_cStruct, sym_new, argc, argv_values);
    free(argv_values);
    return ret;
}

static VALUE rb_cCrunchStream_initialize(VALUE self, VALUE rb_data) {
    Check_Type(rb_data, T_STRING);
    rb_ivar_set(self, sym_at_data, rb_data);
    return self;
}

void Init_crunch()
{
    sym_new = rb_intern("new");
    sym_at_data = rb_intern("@data");

    VALUE mMikunyan = rb_define_module("Mikunyan");
    VALUE mDecodeHelper = rb_define_module_under(mMikunyan, "DecodeHelper");
    VALUE cCrunchStream = rb_define_class_under(mDecodeHelper, "CrunchStream", rb_cObject);
    rb_attr(cCrunchStream, rb_intern("data"), TRUE, FALSE, TRUE);

    const char* stFileInfoStr[] = {"struct_size", "actual_data_size", "header_size", "total_palette_size", "tables_size", "levels", "level_compressed_size", "color_endpoint_palette_entries", "color_selector_palette_entries", "alpha_endpoint_palette_entries", "alpha_selector_palette_entries"};
    stFileInfo = create_rb_struct(sizeof(stFileInfoStr) / sizeof(char*), stFileInfoStr);
    rb_const_set(cCrunchStream, rb_intern("FileInfo"), stFileInfo);

    const char* stTextureInfoStr[] = {"struct_size", "width", "height", "levels", "faces", "bytes_per_block", "userdata0", "userdata1", "format"};
    stTextureInfo = create_rb_struct(sizeof(stTextureInfoStr) / sizeof(char*), stTextureInfoStr);
    rb_const_set(cCrunchStream, rb_intern("TextureInfo"), stTextureInfo);

    const char* stLevelInfoStr[] = {"struct_size", "width", "height", "faces", "blocks_x", "blocks_y", "block_width", "block_height", "bytes_per_block", "format"};
    stLevelInfo = create_rb_struct(sizeof(stLevelInfoStr) / sizeof(char*), stLevelInfoStr);
    rb_const_set(cCrunchStream, rb_intern("LevelInfo"), stLevelInfo);

    rb_define_method(cCrunchStream, "initialize", RUBY_METHOD_FUNC(rb_cCrunchStream_initialize), 1);
    rb_define_method(cCrunchStream, "file_info", RUBY_METHOD_FUNC(rb_cCrunchStream_file_info), 0);
    rb_define_method(cCrunchStream, "texture_info", RUBY_METHOD_FUNC(rb_cCrunchStream_texture_info), 0);
    rb_define_method(cCrunchStream, "level_info", RUBY_METHOD_FUNC(rb_cCrunchStream_level_info), 1);
    rb_define_method(cCrunchStream, "unpack_level", RUBY_METHOD_FUNC(rb_cCrunchStream_unpack_level), 1);

    VALUE mFormat = rb_define_module_under(cCrunchStream, "Format");
    set_format_constant(mFormat);
}

}
