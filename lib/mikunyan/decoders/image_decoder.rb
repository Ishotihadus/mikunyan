# frozen_string_literal: true

begin
  require 'oily_png'
rescue LoadError
  require 'chunky_png'
end
require 'bin_utils'
require 'mikunyan/decoders/native'
require 'mikunyan/decoders/crunch'

module Mikunyan
  module Decoder
    # Class for image decoding tools
    class ImageDecoder
      # Decode image from Mikunyan::ObjectValue
      # @param [Mikunyan::ObjectValue] object object to decode
      # @return [ChunkyPNG::Image,nil] decoded image
      def self.decode_object(object)
        return nil unless object.is_a?(ObjectValue)

        endian = object.endian
        width = object['m_Width']&.value
        height = object['m_Height']&.value
        bin = object['image data']&.value
        fmt = object['m_TextureFormat']&.value
        return nil unless width && height && bin && fmt

        bin = object['m_StreamData']&.value if bin.empty?
        return nil unless bin

        case fmt
        when 1 # Alpha8
          decode_a8(width, height, bin)
        when 2 # ARGB4444
          decode_argb4444(width, height, bin, endian)
        when 3 # RGB24
          decode_rgb24(width, height, bin)
        when 4 # RGBA32
          decode_rgba32(width, height, bin)
        when 5 # ARGB32
          decode_argb32(width, height, bin)
        when 7 # RGB565
          decode_rgb565(width, height, bin, endian)
        when 9 # R16
          decode_r16(width, height, bin)
        when 10 # DXT1
          decode_dxt1(width, height, bin)
        when 12 # DXT5
          decode_dxt5(width, height, bin)
        when 13 # RGBA4444
          decode_rgba4444(width, height, bin, endian)
        when 14 # BGRA32
          decode_bgra32(width, height, bin)
        when 15 # RHalf
          decode_rhalf(width, height, bin, endian)
        when 16 # RGHalf
          decode_rghalf(width, height, bin, endian)
        when 17 # RGBAHalf
          decode_rgbahalf(width, height, bin, endian)
        when 18 # RFloat
          decode_rfloat(width, height, bin, endian)
        when 19 # RGFloat
          decode_rgfloat(width, height, bin, endian)
        when 20 # RGBAFloat
          decode_rgbafloat(width, height, bin, endian)
        # when 21 # YUY2
        when 22 # RGB9e5Float
          decode_rgb9e5float(width, height, bin, endian)
        # when 24 # BC6H
        # when 25 # BC7
        # when 26 # BC4
        # when 27 # BC5
        when 28, 29, 64, 65 # DXT1Crunched, DXT5Crunched, ETC_RGB4Crunched, ETC2_RGBA8Crunched
          decode_crunched(width, height, bin)
        when 30, 31, -127 # PVRTC_RGB2, PVRTC_RGBA2, PVRTC_2BPP_RGBA
          decode_pvrtc1_2bpp(width, height, bin)
        when 32, 33 # PVRTC_RGB4, PVRTC_RGBA4
          decode_pvrtc1_4bpp(width, height, bin)
        when 34 # ETC_RGB4
          decode_etc1(width, height, bin)
        # when 41 # EAC_R
        # when 42 # EAC_R_SIGNED
        # when 43 # EAC_RG
        # when 44 # EAC_RG_SIGNED
        when 45 # ETC2_RGB
          decode_etc2rgb(width, height, bin)
        when 46 # ETC2_RGBA1
          decode_etc2rgba1(width, height, bin)
        when 47 # ETC2_RGBA8
          decode_etc2rgba8(width, height, bin)
        when 48, 54, 66 # ASTC_RGB_4x4, ASTC_RGBA_4x4, ASTC_HDR_4x4
          decode_astc(width, height, 4, bin)
        when 49, 55, 67 # ASTC_RGB_5x5, ASTC_RGBA_5x5, ASTC_HDR_5x5
          decode_astc(width, height, 5, bin)
        when 50, 56, 68 # ASTC_RGB_6x6, ASTC_RGBA_6x6, ASTC_HDR_6x6
          decode_astc(width, height, 6, bin)
        when 51, 57, 69 # ASTC_RGB_8x8, ASTC_RGBA_8x8, ASTC_HDR_8x8
          decode_astc(width, height, 8, bin)
        when 52, 58, 70 # ASTC_10x10, ASTC_RGBA_10x10, ASTC_HDR_10x10
          decode_astc(width, height, 10, bin)
        when 53, 59, 71 # ASTC_RGB_12x12, ASTC_RGBA_12x12, ASTC_HDR_12x12
          decode_astc(width, height, 12, bin)
        # when 60 # ETC_RGB4_3DS
        # when 61 # ETC_RGBA8_3DS
        when 62 # RG16
          decode_rg16(width, height, bin)
        when 63 # R8
          decode_r8(width, height, bin)
        end
      end

      # Decode image from A8 binary
      # @param [Integer] width image width
      # @param [Integer] height image height
      # @param [String] bin binary to decode
      # @return [ChunkyPNG::Image] decoded image
      def self.decode_a8(width, height, bin)
        ChunkyPNG::Image.from_rgb_stream(width, height, DecodeHelper.decode_a8(bin, width * height)).flip
      end

      # Decode image from R8 binary
      # @param [Integer] width image width
      # @param [Integer] height image height
      # @param [String] bin binary to decode
      # @return [ChunkyPNG::Image] decoded image
      def self.decode_r8(width, height, bin)
        ChunkyPNG::Image.from_rgb_stream(width, height, DecodeHelper.decode_r8(bin, width * height)).flip
      end

      # Decode image from ARGB4444 binary
      # @param [Integer] width image width
      # @param [Integer] height image height
      # @param [String] bin binary to decode
      # @param [Symbol] endian endianness of binary
      # @return [ChunkyPNG::Image] decoded image
      def self.decode_argb4444(width, height, bin, endian = :big)
        mem = String.new(capacity: width * height * 4)
        (width * height).times do |i|
          c = endian == :little ? BinUtils.get_int16_le(bin, i * 2) : BinUtils.get_int16_be(bin, i * 2)
          c = ((c & 0x0f00) << 16) | ((c & 0x00f0) << 12) | ((c & 0x000f) << 8) | ((c & 0xf000) >> 12)
          BinUtils.append_int32_be!(mem, c << 4 | c)
        end
        ChunkyPNG::Image.from_rgba_stream(width, height, mem).flip
      end

      # Decode image from RGB24 binary
      # @param [Integer] width image width
      # @param [Integer] height image height
      # @param [String] bin binary to decode
      # @return [ChunkyPNG::Image] decoded image
      def self.decode_rgb24(width, height, bin)
        ChunkyPNG::Image.from_rgb_stream(width, height, bin).flip
      end

      # Decode image from RGBA32 binary
      # @param [Integer] width image width
      # @param [Integer] height image height
      # @param [String] bin binary to decode
      # @return [ChunkyPNG::Image] decoded image
      def self.decode_rgba32(width, height, bin)
        ChunkyPNG::Image.from_rgba_stream(width, height, bin).flip
      end

      # Decode image from ARGB32 binary
      # @param [Integer] width image width
      # @param [Integer] height image height
      # @param [String] bin binary to decode
      # @return [ChunkyPNG::Image] decoded image
      def self.decode_argb32(width, height, bin)
        mem = String.new(capacity: width * height * 4)
        (width * height).times do |i|
          c = BinUtils.get_int32_be(bin, i * 4)
          BinUtils.append_int32_be!(mem, ((c & 0x00ffffff) << 8) | ((c & 0xff000000) >> 24))
        end
        ChunkyPNG::Image.from_rgba_stream(width, height, mem).flip
      end

      # Decode image from RGB565 binary
      # @param [Integer] width image width
      # @param [Integer] height image height
      # @param [String] bin binary to decode
      # @param [Symbol] endian endianness of binary
      # @return [ChunkyPNG::Image] decoded image
      def self.decode_rgb565(width, height, bin, endian = :big)
        ChunkyPNG::Image.from_rgb_stream(width, height, DecodeHelper.decode_rgb565(bin, width * height, endian == :big)).flip
      end

      # Decode image from R16 binary
      # @param [Integer] width image width
      # @param [Integer] height image height
      # @param [String] bin binary to decode
      # @param [Symbol] endian endianness of binary
      # @return [ChunkyPNG::Image] decoded image
      def self.decode_r16(width, height, bin, endian = :big)
        ChunkyPNG::Image.from_rgb_stream(width, height, DecodeHelper.decode_r16(bin, width * height, endian == :big)).flip
      end

      # Decode image from RGBA4444 binary
      # @param [Integer] width image width
      # @param [Integer] height image height
      # @param [String] bin binary to decode
      # @param [Symbol] endian endianness of binary
      # @return [ChunkyPNG::Image] decoded image
      def self.decode_rgba4444(width, height, bin, endian = :big)
        mem = String.new(capacity: width * height * 4)
        (width * height).times do |i|
          c = endian == :little ? BinUtils.get_int16_le(bin, i * 2) : BinUtils.get_int16_be(bin, i * 2)
          c = ((c & 0xf000) << 12) | ((c & 0x0f00) << 8) | ((c & 0x00f0) << 4) | (c & 0x000f)
          BinUtils.append_int32_be!(mem, c << 4 | c)
        end
        ChunkyPNG::Image.from_rgba_stream(width, height, mem).flip
      end

      # Decode image from RG16 binary
      # @param [Integer] width image width
      # @param [Integer] height image height
      # @param [String] bin binary to decode
      # @return [ChunkyPNG::Image] decoded image
      def self.decode_rg16(width, height, bin)
        mem = String.new(capacity: width * height * 3)
        (width * height).times do |i|
          BinUtils.append_int16_int8_be!(mem, BinUtils.get_int16_be(bin, i * 2), 0)
        end
        ChunkyPNG::Image.from_rgb_stream(width, height, mem).flip
      end

      # Decode image from BGRA32 binary
      # @param [Integer] width image width
      # @param [Integer] height image height
      # @param [String] bin binary to decode
      # @return [ChunkyPNG::Image] decoded image
      def self.decode_bgra32(width, height, bin)
        mem = String.new(capacity: width * height * 4)
        (width * height).times do |i|
          c = BinUtils.get_int32_le(bin, i * 4)
          BinUtils.append_int32_be!(mem, ((c & 0x00ffffff) << 8) | ((c & 0xff000000) >> 24))
        end
        ChunkyPNG::Image.from_rgba_stream(width, height, mem).flip
      end

      # Decode image from RGB9e5 binary
      # @param [Integer] width image width
      # @param [Integer] height image height
      # @param [String] bin binary to decode
      # @param [Symbol] endian endianness of binary
      # @return [ChunkyPNG::Image] decoded image
      def self.decode_rgb9e5float(width, height, bin, endian = :big)
        mem = String.new(capacity: width * height * 3)
        (width * height).times do |i|
          n = endian == :little ? BinUtils.get_int32_le(bin, i * 4) : BinUtils.get_int32_be(bin, i * 4)
          b = n >> 18 & 0x1ff
          g = n >> 9 & 0x1ff
          r = n & 0x1ff
          scale = n >> 27 & 0x1f
          scale = 2**(scale - 24)
          BinUtils.append_int8!(mem, f2i(r * scale), f2i(g * scale), f2i(b * scale))
        end
        ChunkyPNG::Image.from_rgb_stream(width, height, mem).flip
      end

      # Decode image from R Half-float binary
      # @param [Integer] width image width
      # @param [Integer] height image height
      # @param [String] bin binary to decode
      # @param [Symbol] endian endianness of binary
      # @return [ChunkyPNG::Image] decoded image
      def self.decode_rhalf(width, height, bin, endian = :big)
        mem = String.new(capacity: width * height * 3)
        (width * height).times do |i|
          c = f2i(n2f(endian == :little ? BinUtils.get_int16_le(bin, i * 2) : BinUtils.get_int16_be(bin, i * 2)))
          BinUtils.append_int8!(mem, c, c, c)
        end
        ChunkyPNG::Image.from_rgb_stream(width, height, mem).flip
      end

      # Decode image from RG Half-float binary
      # @param [Integer] width image width
      # @param [Integer] height image height
      # @param [String] bin binary to decode
      # @param [Symbol] endian endianness of binary
      # @return [ChunkyPNG::Image] decoded image
      def self.decode_rghalf(width, height, bin, endian = :big)
        mem = String.new(capacity: width * height * 3)
        (width * height).times do |i|
          r = f2i(n2f(endian == :little ? BinUtils.get_int16_le(bin, i * 4) : BinUtils.get_int16_be(bin, i * 4)))
          g = f2i(n2f(endian == :little ? BinUtils.get_int16_le(bin, i * 4 + 2) : BinUtils.get_int16_be(bin, i * 4 + 2)))
          BinUtils.append_int8!(mem, r, g, 0)
        end
        ChunkyPNG::Image.from_rgb_stream(width, height, mem).flip
      end

      # Decode image from RGBA Half-float binary
      # @param [Integer] width image width
      # @param [Integer] height image height
      # @param [String] bin binary to decode
      # @param [Symbol] endian endianness of binary
      # @return [ChunkyPNG::Image] decoded image
      def self.decode_rgbahalf(width, height, bin, endian = :big)
        mem = String.new(capacity: width * height * 4)
        (width * height).times do |i|
          r = f2i(n2f(endian == :little ? BinUtils.get_int16_le(bin, i * 8) : BinUtils.get_int16_be(bin, i * 8)))
          g = f2i(n2f(endian == :little ? BinUtils.get_int16_le(bin, i * 8 + 2) : BinUtils.get_int16_be(bin, i * 8 + 2)))
          b = f2i(n2f(endian == :little ? BinUtils.get_int16_le(bin, i * 8 + 4) : BinUtils.get_int16_be(bin, i * 8 + 4)))
          a = f2i(n2f(endian == :little ? BinUtils.get_int16_le(bin, i * 8 + 6) : BinUtils.get_int16_be(bin, i * 8 + 6)))
          BinUtils.append_int8!(mem, r, g, b, a)
        end
        ChunkyPNG::Image.from_rgba_stream(width, height, mem).flip
      end

      # Decode image from R float binary
      # @param [Integer] width image width
      # @param [Integer] height image height
      # @param [String] bin binary to decode
      # @param [Symbol] endian endianness of binary
      # @return [ChunkyPNG::Image] decoded image
      def self.decode_rfloat(width, height, bin, endian = :big)
        mem = String.new(capacity: width * height * 3)
        unpackstr = endian == :little ? 'e' : 'g'
        (width * height).times do |i|
          c = f2i(bin.byteslice(i * 4, 4).unpack1(unpackstr))
          BinUtils.append_int8!(mem, c, c, c)
        end
        ChunkyPNG::Image.from_rgb_stream(width, height, mem).flip
      end

      # Decode image from RG float binary
      # @param [Integer] width image width
      # @param [Integer] height image height
      # @param [String] bin binary to decode
      # @param [Symbol] endian endianness of binary
      # @return [ChunkyPNG::Image] decoded image
      def self.decode_rgfloat(width, height, bin, endian = :big)
        mem = String.new(capacity: width * height * 3)
        unpackstr = endian == :little ? 'e2' : 'g2'
        (width * height).times do |i|
          r, g = bin.byteslice(i * 8, 8).unpack(unpackstr)
          BinUtils.append_int8!(mem, f2i(r), f2i(g), 0)
        end
        ChunkyPNG::Image.from_rgb_stream(width, height, mem).flip
      end

      # Decode image from RGBA float binary
      # @param [Integer] width image width
      # @param [Integer] height image height
      # @param [String] bin binary to decode
      # @param [Symbol] endian endianness of binary
      # @return [ChunkyPNG::Image] decoded image
      def self.decode_rgbafloat(width, height, bin, endian = :big)
        mem = String.new(capacity: width * height * 4)
        unpackstr = endian == :little ? 'e4' : 'g4'
        (width * height).times do |i|
          r, g, b, a = bin.byteslice(i * 16, 16).unpack(unpackstr)
          BinUtils.append_int8!(mem, f2i(r), f2i(g), f2i(b), f2i(a))
        end
        ChunkyPNG::Image.from_rgba_stream(width, height, mem).flip
      end

      # Decode image from DXT1 compressed binary
      # @param [Integer] width image width
      # @param [Integer] height image height
      # @param [String] bin binary to decode
      # @return [ChunkyPNG::Image] decoded image
      def self.decode_dxt1(width, height, bin)
        ChunkyPNG::Image.from_rgba_stream(width, height, DecodeHelper.decode_dxt1(bin, width, height))
      end

      # Decode image from DXT5 compressed binary
      # @param [Integer] width image width
      # @param [Integer] height image height
      # @param [String] bin binary to decode
      # @return [ChunkyPNG::Image] decoded image
      def self.decode_dxt5(width, height, bin)
        ChunkyPNG::Image.from_rgba_stream(width, height, DecodeHelper.decode_dxt5(bin, width, height))
      end

      # Decode image from PVRTC1 4bpp compressed binary
      # @param [Integer] width image width
      # @param [Integer] height image height
      # @param [String] bin binary to decode
      # @return [ChunkyPNG::Image] decoded image
      def self.decode_pvrtc1_4bpp(width, height, bin)
        ChunkyPNG::Image.from_rgba_stream(width, height, DecodeHelper.decode_pvrtc1_4bpp(bin, width, height))
      end

      # Decode image from PVRTC1 2bpp compressed binary
      # @param [Integer] width image width
      # @param [Integer] height image height
      # @param [String] bin binary to decode
      # @return [ChunkyPNG::Image] decoded image
      def self.decode_pvrtc1_2bpp(width, height, bin)
        ChunkyPNG::Image.from_rgba_stream(width, height, DecodeHelper.decode_pvrtc1_2bpp(bin, width, height))
      end

      # Decode image from ETC1 compressed binary
      # @param [Integer] width image width
      # @param [Integer] height image height
      # @param [String] bin binary to decode
      # @return [ChunkyPNG::Image] decoded image
      def self.decode_etc1(width, height, bin)
        ChunkyPNG::Image.from_rgba_stream(width, height, DecodeHelper.decode_etc1(bin, width, height))
      end

      # Decode image from ETC2 compressed binary
      # @param [Integer] width image width
      # @param [Integer] height image height
      # @param [String] bin binary to decode
      # @return [ChunkyPNG::Image] decoded image
      def self.decode_etc2rgb(width, height, bin)
        ChunkyPNG::Image.from_rgba_stream(width, height, DecodeHelper.decode_etc2(bin, width, height))
      end

      # Decode image from ETC2 Alpha1 compressed binary
      # @param [Integer] width image width
      # @param [Integer] height image height
      # @param [String] bin binary to decode
      # @return [ChunkyPNG::Image] decoded image
      def self.decode_etc2rgba1(width, height, bin)
        ChunkyPNG::Image.from_rgba_stream(width, height, DecodeHelper.decode_etc2a1(bin, width, height))
      end

      # Decode image from ETC2 Alpha8 compressed binary
      # @param [Integer] width image width
      # @param [Integer] height image height
      # @param [String] bin binary to decode
      # @return [ChunkyPNG::Image] decoded image
      def self.decode_etc2rgba8(width, height, bin)
        ChunkyPNG::Image.from_rgba_stream(width, height, DecodeHelper.decode_etc2a8(bin, width, height))
      end

      # Decode image from ASTC compressed binary
      # @param [Integer] width image width
      # @param [Integer] height image height
      # @param [Integer] blocksize block size
      # @param [String] bin binary to decode
      # @return [ChunkyPNG::Image] decoded image
      def self.decode_astc(width, height, blocksize, bin)
        ChunkyPNG::Image.from_rgba_stream(width, height, DecodeHelper.decode_astc(bin, width, height, blocksize, blocksize))
      end

      # Decode image from crunched texture binary
      # @param [Integer] width image width
      # @param [Integer] height image height
      # @param [String] bin binary to decode
      # @return [ChunkyPNG::Image,nil] decoded image
      def self.decode_crunched(width, height, bin)
        file = Mikunyan::DecodeHelper::CrunchStream.new(bin)
        level_info = file.level_info(0)
        case level_info.format
        when Mikunyan::DecodeHelper::CrunchStream::Format::DXT1
          decode_dxt1(width, height, file.unpack_level(0))
        when Mikunyan::DecodeHelper::CrunchStream::Format::DXT5
          decode_dxt5(width, height, file.unpack_level(0))
        when Mikunyan::DecodeHelper::CrunchStream::Format::ETC1
          decode_etc1(width, height, file.unpack_level(0))
        when Mikunyan::DecodeHelper::CrunchStream::Format::ETC2
          decode_etc2rgb(width, height, file.unpack_level(0))
        when Mikunyan::DecodeHelper::CrunchStream::Format::ETC2A
          decode_etc2rgba8(width, height, file.unpack_level(0))
        end
      end

      # Create ASTC file data from ObjectValue
      # @param [Mikunyan::ObjectValue,Hash] object target object
      # @return [String,nil] created file
      def self.create_astc_file(object)
        astc_list = {
          48 => 4, 49 => 5, 50 => 6, 51 => 8, 52 => 10, 53 => 12,
          54 => 4, 55 => 5, 56 => 6, 57 => 8, 58 => 10, 59 => 12,
          66 => 4, 67 => 5, 68 => 6, 69 => 8, 70 => 10, 71 => 12
        }
        width = object['m_Width']&.value
        height = object['m_Height']&.value
        fmt = object['m_TextureFormat']&.value
        bin = object['image data']&.value
        return unless width && height && fmt && bin && astc_list[fmt]
        bin = object['m_StreamData']&.value if bin.empty?
        return unless bin
        header = [0x13, 0xab, 0xa1, 0x5c, astc_list[fmt], astc_list[fmt], 1].pack('C*')
        header << [width].pack('V').byteslice(0, 3)
        header << [height].pack('V').byteslice(0, 3)
        header << [1, 0, 0].pack('C*')
        header + bin
      end

      # convert 16bit float
      def self.n2f(n)
        case n
        when 0x0000
          0.0
        when 0x8000
          -0.0
        when 0x7c00
          Float::INFINITY
        when 0xfc00
          -Float::INFINITY
        else
          s = n & 0x8000 != 0
          e = n & 0x7c00
          f = n & 0x03ff
          case e
          when 0x7c00
            Float::NAN
          when 0
            (s ? -f : f) * 2.0**-24
          else
            (s ? -1 : 1) * (f / 1024.0 + 1) * (2.0**((e >> 10) - 15))
          end
        end
      end

      # [0.0,1.0] -> [0,255]
      def self.f2i(d)
        (d * 255).round.clamp(0, 255)
      end
    end
  end

  class ImageDecoder
    def self.decode_object(object)
      warn 'Warning: Mikunyan::ImageDecoder.decode_object is deprecated and will be removed at a future release. ' \
        'Use Mikunyan::Decoder::ImageDecoder.decode_object or' \
        'Mikunyan::CustomTypes::Texture2D::generate_png instead.'
      Mikunyan::Decoder::ImageDecoder.decode_object(object)
    end
  end
end
