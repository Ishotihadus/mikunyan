begin; require 'oily_png'; rescue LoadError; require 'chunky_png'; end
require 'bin_utils'

module Mikunyan
    class ImageDecoder
        Etc1ModifierTable = [[2, 8], [5, 17], [9, 29], [13, 42], [18, 60], [24, 80], [33, 106], [47, 183]]
        Etc1SubblockTable = [[0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1], [0, 0, 1, 1, 0, 0, 1, 1, 0, 0, 1, 1, 0, 0, 1, 1]]

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
                decode_rgb888(width, height, bin, endian)
            when 4
                decode_rgba8888(width, height, bin, endian)
            when 5
                decode_argb8888(width, height, bin, endian)
            when 7
                decode_rgb565(width, height, bin, endian)
            when 13
                decode_rgba4444(width, height, bin, endian)
            when 34
                decode_etc1(width, height, bin)
            else
                nil
            end
        end

        def self.decode_etc1(width, height, bin)
            bw = (width + 3) / 4
            bh = (height + 3) / 4
            pixels = "\0" * (64 * bw * bh)
            pixels.force_encoding('ascii-8bit')
            bh.times do |by|
                bw.times do |bx|
                    block = decode_etc1_block(BinUtils.get_sint64_be(bin, (bx + by * bw) * 8)).pack('N16')
                    pixels[( bx * 4      * bh + by) * 16, 16] = block.byteslice( 0, 16)
                    pixels[((bx * 4 + 1) * bh + by) * 16, 16] = block.byteslice(16, 16)
                    pixels[((bx * 4 + 2) * bh + by) * 16, 16] = block.byteslice(32, 16)
                    pixels[((bx * 4 + 3) * bh + by) * 16, 16] = block.byteslice(48, 16)
                end
            end
            ChunkyPNG::Image.from_rgba_stream(bh * 4, bw * 4, pixels).rotate_right!.crop!(0, 0, width, height)
        end

        def self.decode_a8(width, height, bin)
            pixels = bin.unpack('C*').map do |c|
                c << 24 | c << 16 | c << 8 | 0xff
            end
            ChunkyPNG::Image.new(width, height, pixels)
        end

        def self.decode_rgb565(width, height, bin, endian = :big)
            pixels = bin.unpack(endian == :little ? 'v*' : 'n*').map do |c|
                r = (c & 0xf800) >> 8
                g = (c & 0x07e0) >> 3
                b = (c & 0x001f) << 3
                r = r | r >> 5
                g = g | g >> 6
                b = b | b >> 5
                r << 24 | g << 16 | b << 8 | 0xff
            end
            ChunkyPNG::Image.new(width, height, pixels)
        end

        def self.decode_rgb888(width, height, bin, endian = :big)
            if endian == :little
                ChunkyPNG::Image.from_bgr_stream(width, height, bin)
            else
                ChunkyPNG::Image.from_rgb_stream(width, height, bin)
            end
        end

        def self.decode_rgba4444(width, height, bin, endian = :big)
            pixels = bin.unpack(endian == :little ? 'v*' : 'n*').map do |c|
                c = ((c & 0xf000) << 12) | ((c & 0x0f00) << 8) | ((c & 0x00f0) << 4) | (c & 0x000f)
                c << 4 | c
            end
            ChunkyPNG::Image.new(width, height, pixels)
        end

        def self.decode_argb4444(width, height, bin, endian = :big)
            pixels = bin.unpack(endian == :little ? 'v*' : 'n*').map do |c|
                c = ((c & 0x0f00) << 16) | ((c & 0x00f0) << 12) | ((c & 0x000f) << 8) | ((c & 0xf000) >> 12)
                c << 4 | c
            end
            ChunkyPNG::Image.new(width, height, pixels)
        end

        def self.decode_rgba8888(width, height, bin, endian = :big)
            if endian == :little
                ChunkyPNG::Image.from_abgr_stream(width, height, bin)
            else
                ChunkyPNG::Image.from_rgba_stream(width, height, bin)
            end
        end

        def self.decode_argb8888(width, height, bin, endian = :big)
            pixels = bin.unpack(endian == :little ? 'V*' : 'N*').map do |c|
                c = ((c & 0x00ffffff) << 8) | ((c & 0xff000000) >> 24)
            end
            ChunkyPNG::Image.new(width, height, pixels)
        end

        private

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

            ret = Array.new(16, 0)
            16.times do |i|
                modifier = Etc1ModifierTable[codes[subblocks[i]]][bin[i]]
                ret[i] = etc1colormod(colors[subblocks[i]], bin[i + 16] == 0 ? modifier : -modifier)
            end
            ret
        end

        def self.etc1colormod(color, modifier)
            r = (color >> 16 & 0xff) + modifier
            g = (color >> 8 & 0xff) + modifier
            b = (color & 0xff) + modifier
            r = (r > 255 ? 255 : r < 0 ? 0 : r)
            g = (g > 255 ? 255 : g < 0 ? 0 : g)
            b = (b > 255 ? 255 : b < 0 ? 0 : b)
            r << 24 | g << 16 | b << 8 | 0xff
        end
    end
end
