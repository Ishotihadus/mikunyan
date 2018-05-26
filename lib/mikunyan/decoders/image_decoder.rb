begin; require 'oily_png'; rescue LoadError; require 'chunky_png'; end
require 'bin_utils'
require 'mikunyan/decoders/native'

module Mikunyan
    # Class for image decoding tools
    class ImageDecoder
        # Decode image from Mikunyan::ObjectValue
        # @param [Mikunyan::ObjectValue] object object to decode
        # @return [ChunkyPNG::Image,nil] decoded image
        def self.decode_object(object)
            return nil unless object.class == ObjectValue

            endian = object.endian
            width = object['m_Width']
            height = object['m_Height']
            bin = object['image data']
            fmt = object['m_TextureFormat']
            return nil unless width && height && bin && fmt

            width = width.value
            height = height.value
            bin = bin.value
            fmt = fmt.value

            case fmt
            when 1
                decode_a8(width, height, bin)
            when 2
                decode_argb4444(width, height, bin, endian)
            when 3
                decode_rgb24(width, height, bin)
            when 4
                decode_rgba32(width, height, bin)
            when 5
                decode_argb32(width, height, bin)
            when 7
                decode_rgb565(width, height, bin, endian)
            when 9
                decode_r16(width, height, bin)
            when 10
                decode_dxt1(width, height, bin)
            when 12
                decode_dxt5(width, height, bin)
            when 13
                decode_rgba4444(width, height, bin, endian)
            when 14
                decode_bgra32(width, height, bin)
            when 15
                decode_rhalf(width, height, bin, endian)
            when 16
                decode_rghalf(width, height, bin, endian)
            when 17
                decode_rgbahalf(width, height, bin, endian)
            when 18
                decode_rfloat(width, height, bin, endian)
            when 19
                decode_rgfloat(width, height, bin, endian)
            when 20
                decode_rgbafloat(width, height, bin, endian)
            when 22
                decode_rgb9e5float(width, height, bin, endian)
            when 34
                decode_etc1(width, height, bin)
            when 45
                decode_etc2rgb(width, height, bin)
            when 47
                decode_etc2rgba8(width, height, bin)
            when 48, 54
                decode_astc(width, height, 4, bin)
            when 49, 55
                decode_astc(width, height, 5, bin)
            when 50, 56
                decode_astc(width, height, 6, bin)
            when 51, 57
                decode_astc(width, height, 8, bin)
            when 52, 58
                decode_astc(width, height, 10, bin)
            when 53, 59
                decode_astc(width, height, 12, bin)
            when 62
                decode_rg16(width, height, bin)
            when 63
                decode_r8(width, height, bin)
            else
                nil
            end
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
                c = endian == :little ? BinUtils.get_int16_le(bin, i*2) : BinUtils.get_int16_be(bin, i*2)
                c = ((c & 0xf000) << 12) | ((c & 0x0f00) << 8) | ((c & 0x00f0) << 4) | (c & 0x000f)
                BinUtils.append_int32_be!(mem, c << 4 | c)
            end
            ChunkyPNG::Image.from_rgba_stream(width, height, mem).flip
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
                c = endian == :little ? BinUtils.get_int16_le(bin, i*2) : BinUtils.get_int16_be(bin, i*2)
                c = ((c & 0x0f00) << 16) | ((c & 0x00f0) << 12) | ((c & 0x000f) << 8) | ((c & 0xf000) >> 12)
                BinUtils.append_int32_be!(mem, c << 4 | c)
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
            ChunkyPNG::Image.from_rgba_stream(width, height, DecodeHelper.decode_rgb565(bin, width * height, endian == :big)).flip
        end

        # Decode image from A8 binary
        # @param [Integer] width image width
        # @param [Integer] height image height
        # @param [String] bin binary to decode
        # @return [ChunkyPNG::Image] decoded image
        def self.decode_a8(width, height, bin)
            mem = String.new(capacity: width * height * 3)
            (width * height).times do |i|
                c = BinUtils.get_int8(bin, i)
                BinUtils.append_int8!(mem, c, c, c)
            end
            ChunkyPNG::Image.from_rgb_stream(width, height, mem).flip
        end

        # Decode image from R8 binary
        # @param [Integer] width image width
        # @param [Integer] height image height
        # @param [String] bin binary to decode
        # @return [ChunkyPNG::Image] decoded image
        def self.decode_r8(width, height, bin)
            decode_a8(width, height, bin)
        end

        # Decode image from RG16 binary
        # @param [Integer] width image width
        # @param [Integer] height image height
        # @param [String] bin binary to decode
        # @return [ChunkyPNG::Image] decoded image
        def self.decode_rg16(width, height, bin)
            mem = String.new(capacity: width * height * 3)
            (width * height).times do |i|
                BinUtils.append_int16_int8_be!(mem, BinUtils.get_int16_be(bin, i*2), 0)
            end
            ChunkyPNG::Image.from_rgb_stream(width, height, mem).flip
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
                c = BinUtils.get_int32_be(bin, i*4)
                BinUtils.append_int32_be!(mem, ((c & 0x00ffffff) << 8) | ((c & 0xff000000) >> 24))
            end
            ChunkyPNG::Image.from_rgba_stream(width, height, mem).flip
        end

        # Decode image from BGRA32 binary
        # @param [Integer] width image width
        # @param [Integer] height image height
        # @param [String] bin binary to decode
        # @return [ChunkyPNG::Image] decoded image
        def self.decode_bgra32(width, height, bin)
            mem = String.new(capacity: width * height * 4)
            (width * height).times do |i|
                c = BinUtils.get_int32_le(bin, i*4)
                BinUtils.append_int32_be!(mem, ((c & 0x00ffffff) << 8) | ((c & 0xff000000) >> 24))
            end
            ChunkyPNG::Image.from_rgba_stream(width, height, mem).flip
        end

        # Decode image from R16 binary
        # @param [Integer] width image width
        # @param [Integer] height image height
        # @param [String] bin binary to decode
        # @param [Symbol] endian endianness of binary
        # @return [ChunkyPNG::Image] decoded image
        def self.decode_r16(width, height, bin, endian = :big)
            mem = String.new(capacity: width * height * 3)
            (width * height).times do |i|
                c = endian == :little ? BinUtils.get_int16_le(bin, i*2) : BinUtils.get_int16_be(bin, i*2)
                c = f2i(r / 65535.0)
                BinUtils.append_int8!(mem, c, c, c)
            end
            ChunkyPNG::Image.from_rgb_stream(width, height, mem).flip
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
                n = endian == :little ? BinUtils.get_int32_le(bin, i*4) : BinUtils.get_int32_be(bin, i*4)
                e = (n & 0xf8000000) >> 27
                r = (n & 0x7fc0000) >> 9
                g = (n & 0x3fe00) >> 9
                b = n & 0x1ff
                r = (r / 512r + 1) * (2**(e-15))
                g = (g / 512r + 1) * (2**(e-15))
                b = (b / 512r + 1) * (2**(e-15))
                BinUtils.append_int8!(mem, f2i(r), f2i(g), f2i(b))
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
                c = f2i(n2f(endian == :little ? BinUtils.get_int16_le(bin, i*2) : BinUtils.get_int16_be(bin, i*2)))
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
                r = f2i(n2f(endian == :little ? BinUtils.get_int16_le(bin, i*4) : BinUtils.get_int16_be(bin, i*4)))
                g = f2i(n2f(endian == :little ? BinUtils.get_int16_le(bin, i*4+2) : BinUtils.get_int16_be(bin, i*4+2)))
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
                r = f2i(n2f(endian == :little ? BinUtils.get_int16_le(bin, i*8) : BinUtils.get_int16_be(bin, i*8)))
                g = f2i(n2f(endian == :little ? BinUtils.get_int16_le(bin, i*8+2) : BinUtils.get_int16_be(bin, i*8+2)))
                b = f2i(n2f(endian == :little ? BinUtils.get_int16_le(bin, i*8+4) : BinUtils.get_int16_be(bin, i*8+4)))
                a = f2i(n2f(endian == :little ? BinUtils.get_int16_le(bin, i*8+6) : BinUtils.get_int16_be(bin, i*8+6)))
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
                c = f2i(bin.byteslice(i*4, 4).unpack(unpackstr)[0])
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
                r, g = bin.byteslice(i*8, 8).unpack(unpackstr)
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
                r, g, b, a = bin.byteslice(i*16, 16).unpack(unpackstr)
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

        # Decode image from ETC1 compressed binary
        # @param [Integer] width image width
        # @param [Integer] height image height
        # @param [String] bin binary to decode
        # @return [ChunkyPNG::Image] decoded image
        def self.decode_etc1(width, height, bin)
            bw = (width + 3) / 4
            bh = (height + 3) / 4
            ret = ChunkyPNG::Image.new(bh * 4, bw * 4)
            bh.times do |by|
                bw.times do |bx|
                    block = decode_etc1_block(BinUtils.get_sint64_be(bin, (bx + by * bw) * 8))
                    ret.replace!(ChunkyPNG::Image.from_rgb_stream(4, 4, block), by * 4, bx * 4)
                end
            end
            ret.crop(0, 0, height, width).rotate_left
        end

        # Decode image from ETC2 compressed binary
        # @param [Integer] width image width
        # @param [Integer] height image height
        # @param [String] bin binary to decode
        # @return [ChunkyPNG::Image] decoded image
        def self.decode_etc2rgb(width, height, bin)
            bw = (width + 3) / 4
            bh = (height + 3) / 4
            ret = ChunkyPNG::Image.new(bh * 4, bw * 4)
            bh.times do |by|
                bw.times do |bx|
                    block = decode_etc2_block(BinUtils.get_sint64_be(bin, (bx + by * bw) * 8))
                    ret.replace!(ChunkyPNG::Image.from_rgb_stream(4, 4, block), by * 4, bx * 4)
                end
            end
            ret.crop(0, 0, height, width).rotate_left
        end

        # Decode image from ETC2 Alpha8 compressed binary
        # @param [Integer] width image width
        # @param [Integer] height image height
        # @param [String] bin binary to decode
        # @return [ChunkyPNG::Image] decoded image
        def self.decode_etc2rgba8(width, height, bin)
            bw = (width + 3) / 4
            bh = (height + 3) / 4
            ret = ChunkyPNG::Image.new(bh * 4, bw * 4)
            bh.times do |by|
                bw.times do |bx|
                    alpha = decode_etc2alpha_block(BinUtils.get_int64_be(bin, (bx + by * bw) * 16))
                    block = decode_etc2_block(BinUtils.get_int64_be(bin, (bx + by * bw) * 16 + 8))
                    mem = String.new(capacity: 64)
                    16.times{|i| BinUtils.append_string!(mem, block[i * 3, 3] + alpha[15 - i])}
                    ret.replace!(ChunkyPNG::Image.from_rgba_stream(4, 4, mem), by * 4, bx * 4)
                end
            end
            ret.crop(0, 0, height, width).rotate_left
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

        # Create ASTC file data from ObjectValue
        # @param [Mikunyan::ObjectValue,Hash] object target object
        # @return [String,nil] created file
        def self.create_astc_file(object)
            astc_list = {
                48 => 4, 49 => 5, 50 => 6, 51 => 8, 52 => 10, 53 => 12,
                54 => 4, 55 => 5, 56 => 6, 57 => 8, 58 => 10, 59 => 12
            }
            width = object['m_Width']
            height = object['m_Height']
            fmt = object['m_TextureFormat']
            bin = object['image data']
            width = width.value if width.class == ObjectValue
            height = height.value if height.class == ObjectValue
            fmt = fmt.value if fmt.class == ObjectValue
            bin = bin.value if bin.class == ObjectValue
            if width && height && fmt && astc_list[fmt]
                header = "\x13\xAB\xA1\x5C".force_encoding('ascii-8bit')
                header << [astc_list[fmt], astc_list[fmt], 1].pack("C*")
                header << [width].pack("V").byteslice(0, 3)
                header << [height].pack("V").byteslice(0, 3)
                header << "\x01\x00\x00"
                header + bin
            else
                nil
            end
        end

        private

        Etc1ModifierTable = [[2, 8], [5, 17], [9, 29], [13, 42], [18, 60], [24, 80], [33, 106], [47, 183]]
        Etc1SubblockTable = [[0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1], [0, 0, 1, 1, 0, 0, 1, 1, 0, 0, 1, 1, 0, 0, 1, 1]]
        Etc2DistanceTable = [3, 6, 11, 16, 23, 32, 41, 64]
        Etc2AlphaModTable = [
            [-3, -6,  -9, -15, 2, 5, 8, 14],
            [-3, -7, -10, -13, 2, 6, 9, 12],
            [-2, -5,  -8, -13, 1, 4, 7, 12],
            [-2, -4,  -6, -13, 1, 3, 5, 12],
            [-3, -6,  -8, -12, 2, 5, 7, 11],
            [-3, -7,  -9, -11, 2, 6, 8, 10],
            [-4, -7,  -8, -11, 3, 6, 7, 10],
            [-3, -5,  -8, -11, 2, 4, 7, 10],
            [-2, -6,  -8, -10, 1, 5, 7,  9],
            [-2, -5,  -8, -10, 1, 4, 7,  9],
            [-2, -4,  -8, -10, 1, 3, 7,  9],
            [-2, -5,  -7, -10, 1, 4, 6,  9],
            [-3, -4,  -7, -10, 2, 3, 6,  9],
            [-1, -2,  -3, -10, 0, 1, 2,  9],
            [-4, -6,  -8,  -9, 3, 5, 7,  8],
            [-3, -5,  -7,  -9, 2, 4, 6,  8]
        ]

        def self.decode_etc1_block(bin)
            colors = []
            codes = [bin >> 37 & 7, bin >> 34 & 7]
            subblocks = Etc1SubblockTable[bin[32]]
            if bin[33] == 0
                colors[0] = bin >> 40 & 0xf0f0f0
                colors[0] = colors[0] | colors[0] >> 4
                colors[1] = bin >> 36 & 0xf0f0f0
                colors[1] = colors[1] | colors[1] >> 4
            else
                colors[0] = bin >> 40 & 0xf8f8f8
                dr = (bin >> 56 & 3) - (bin >> 56 & 4)
                dg = (bin >> 48 & 3) - (bin >> 48 & 4)
                db = (bin >> 40 & 3) - (bin >> 40 & 4)
                colors[1] = colors[0] + (dr << 19) + (dg << 11) + (db << 3)
                colors[0] = colors[0] | (colors[0] >> 5 & 0x70707)
                colors[1] = colors[1] | (colors[1] >> 5 & 0x70707)
            end

            mem = String.new(capacity: 48)
            16.times do |i|
                modifier = Etc1ModifierTable[codes[subblocks[i]]][bin[i]]
                etc1colormod_append(mem, colors[subblocks[i]], bin[i + 16] == 0 ? modifier : -modifier)
            end
            mem
        end

        def self.etc1colormod_append(str, color, modifier)
            r = (color >> 16 & 0xff) + modifier
            g = (color >> 8 & 0xff) + modifier
            b = (color & 0xff) + modifier
            BinUtils.append_int8!(str, r.clamp(0, 255), g.clamp(0, 255), b.clamp(0, 255))
        end

        def self.etc1colormod(color, modifier)
            r = (color >> 16 & 0xff) + modifier
            g = (color >> 8 & 0xff) + modifier
            b = (color & 0xff) + modifier
            r.clamp(0, 255).chr + g.clamp(0, 255).chr + b.clamp(0, 255).chr
        end

        def self.decode_etc2_block(bin)
            mem = String.new(capacity: 48)
            if bin[33] == 0
                # individual
                colors = [0, 0]
                colors[0] = bin >> 40 & 0xf0f0f0
                colors[0] = colors[0] | colors[0] >> 4
                colors[1] = bin >> 36 & 0xf0f0f0
                colors[1] = colors[1] | colors[1] >> 4
                codes = [bin >> 37 & 7, bin >> 34 & 7]
                subblocks = Etc1SubblockTable[bin[32]]
                16.times do |i|
                    modifier = Etc1ModifierTable[codes[subblocks[i]]][bin[i]]
                    etc1colormod_append(mem, colors[subblocks[i]], bin[i + 16] == 0 ? modifier : -modifier)
                end
            else
                r = bin >> 59
                dr = (bin >> 56 & 3) - (bin >> 56 & 4)
                g = bin >> 51 & 0x1f
                dg = (bin >> 48 & 3) - (bin >> 48 & 4)
                b = bin >> 43 & 0x1f
                db = (bin >> 40 & 3) - (bin >> 40 & 4)
                if r + dr < 0 || r + dr > 31
                    # T mode
                    base1 = (bin >> 49 & 0xc00) | (bin >> 48 & 0x3ff)
                    base1 = (base1 & 0xf00) << 8 | (base1 & 0xf0) << 4 | (base1 & 0xf)
                    base1 = (base1 << 4) | base1
                    base2 = bin >> 36 & 0xfff
                    base2 = (base2 & 0xf00) << 8 | (base2 & 0xf0) << 4 | (base2 & 0xf)
                    base2 = (base2 << 4) | base2
                    d = Etc2DistanceTable[(bin >> 33 & 6) + bin[32]]
                    colors = [[base1].pack('N')[1,3], etc1colormod(base2, d), [base2].pack('N')[1,3], etc1colormod(base2, -d)]
                    16.times do |i|
                        BinUtils.append_string!(mem, colors[bin[i] + bin[i + 16] * 2])
                    end
                elsif g + dg < 0 || g + dg > 31
                    # H mode
                    base1 = (bin >> 51 & 0xfe0) | (bin >> 48 & 0x18) | (bin >> 47 & 7)
                    base1 = (base1 & 0xf00) << 8 | (base1 & 0xf0) << 4 | (base1 & 0xf)
                    base1 = (base1 << 4) | base1
                    base2 = bin >> 35 & 0xfff
                    base2 = (base2 & 0xf00) << 8 | (base2 & 0xf0) << 4 | (base2 & 0xf)
                    base2 = (base2 << 4) | base2
                    d = Etc2DistanceTable[bin[34] * 2 + bin[32]]
                    colors = [etc1colormod(base1, d), etc1colormod(base1, -d), etc1colormod(base2, d), etc1colormod(base2, -d)]
                    16.times do |i|
                        BinUtils.append_string!(mem, colors[bin[i] + bin[i + 16] * 2])
                    end
                elsif b + db < 0 || b + db > 31
                    # planar mode
                    color_or = (bin >> 55 & 0xfc) | (bin >> 61 & 0x03)
                    color_og = (bin >> 49 & 0x80) | (bin >> 48 & 0x7e) | bin[56]
                    color_ob = (bin >> 41 & 0x80) | (bin >> 38 & 0x60) | (bin >> 37 & 0x1c) | (bin >> 47 & 2) | bin[44]
                    color_hr = (bin >> 31 & 0xf8) | (bin >> 30 & 0x04) | (bin >> 37 & 0x03)
                    color_hg = (bin >> 24 & 0xfe) | bin[31]
                    color_hb = (bin >> 17 & 0xfc) | (bin >> 23 & 0x03)
                    color_vr = (bin >> 11 & 0xfc) | (bin >> 17 & 0x03)
                    color_vg = (bin >>  5 & 0xfe) | bin[12]
                    color_vb = (bin <<  2 & 0xfc) | (bin >>  4 & 0x03)
                    16.times do |i|
                        x = i / 4
                        y = i % 4
                        r = (x * (color_hr - color_or) + y * (color_vr - color_or) + 4 * color_or + 2) >> 2
                        g = (x * (color_hg - color_og) + y * (color_vg - color_og) + 4 * color_og + 2) >> 2
                        b = (x * (color_hb - color_ob) + y * (color_vb - color_ob) + 4 * color_ob + 2) >> 2
                        BinUtils.append_int8!(mem, r.clamp(0, 255), g.clamp(0, 255), b.clamp(0, 255))
                    end
                else
                    # differential mode
                    colors = [0, 0]
                    colors[0] = bin >> 40 & 0xf8f8f8
                    colors[1] = colors[0] + (dr << 19) + (dg << 11) + (db << 3)
                    colors[0] = colors[0] | (colors[0] >> 5 & 0x70707)
                    colors[1] = colors[1] | (colors[1] >> 5 & 0x70707)
                    codes = [bin >> 37 & 7, bin >> 34 & 7]
                    subblocks = Etc1SubblockTable[bin[32]]
                    16.times do |i|
                        modifier = Etc1ModifierTable[codes[subblocks[i]]][bin[i]]
                        etc1colormod_append(mem, colors[subblocks[i]], bin[i + 16] == 0 ? modifier : -modifier)
                    end
                end
            end
            mem
        end

        def self.decode_etc2alpha_block(bin)
            if bin & 0xf0000000000000 == 0
                ((bin >> 56).chr) * 16
            else
                mem = String.new(capacity: 16)
                base = bin >> 56
                mult = bin >> 52 & 0xf
                table = Etc2AlphaModTable[bin >> 48 & 0xf]
                (0...16).each{|i| BinUtils.append_int8!(mem, (base + table[bin >> i*3 & 7] * mult).clamp(0, 255))}
                mem
            end
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
                    (s ? -1 : 1) * (f / 1024.0 + 1) * (2.0 ** ((e >> 10)-15))
                end
            end
        end

        # [0.0,1.0] -> [0,255]
        def self.f2i(d)
            (d * 255).round.clamp(0, 255)
        end
    end
end
