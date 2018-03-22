require 'bin_utils'
require 'fiddle'

module Mikunyan
    module DecodeHelper
        # Module for decoding DXTC block
        module DxtcBlockDecoder
            def self.decode_dxt1_block(bin)
                c0 = BinUtils.get_int16_le(bin, 0)
                c1 = BinUtils.get_int16_le(bin, 2)
                color = [get_rgb565a(c0), get_rgb565a(c1), nil, nil]
                if c0 > c1
                    color[2] = [(color[0][0] * 2 + color[1][0]) / 3, (color[0][1] * 2 + color[1][1]) / 3, (color[0][2] * 2 + color[1][2]) / 3, 255]
                    color[3] = [(color[0][0] + color[1][0] * 2) / 3, (color[0][1] + color[1][1] * 2) / 3, (color[0][2] + color[1][2] * 2) / 3, 255]
                else
                    color[2] = [(color[0][0] + color[1][0]) / 2, (color[0][1] + color[1][1]) / 2, (color[0][2] + color[1][2]) / 2, 255]
                    color[3] = [0, 0, 0, 0]
                end
                color.map!{|e| e.pack('C4')}
                code = BinUtils.get_int32_le(bin, 4)
                mem = String.new(capacity: 64)
                16.times do
                    mem << color[code & 3]
                    code >>= 2
                end
                mem
            end

            def self.decode_dxt5_block(bin)
                alpha_list, alpha_code = decode_dxt5_alpha(bin)
                color_list, color_code = decode_dxtc_rgb(bin)
                mem = String.new(capacity: 64)
                16.times do
                    mem << color_list[color_code & 3]
                    mem << alpha_list[alpha_code & 7]
                    color_code >>= 2
                    alpha_code >>= 3
                end
                mem
            end

            def self.decode_dxtc_rgb(bin)
                c0 = BinUtils.get_int16_le(bin, 8)
                c1 = BinUtils.get_int16_le(bin, 10)
                color = [get_rgb565(c0), get_rgb565(c1), nil, nil]
                if c0 > c1
                    color[2] = (0...3).map{|i| (color[0][i] * 2 + color[1][i]) / 3}
                    color[3] = (0...3).map{|i| (color[0][i] + color[1][i] * 2) / 3}
                else
                    color[2] = (0...3).map{|i| (color[0][i] + color[1][i]) / 2}
                    color[3] = [0, 0, 0]
                end
                color.map!{|e| e.pack('C3')}
                code = BinUtils.get_int32_le(bin, 12)
                [color, code]
            end

            def self.decode_dxt5_alpha(bin)
                a0 = BinUtils.get_int8(bin, 0)
                a1 = BinUtils.get_int8(bin, 1)
                alpha = [a0, a1, nil, nil, nil, nil, nil, nil]
                if a0 > a1
                    alpha[2, 6] = (1..6).map{|n| (a0 * (7-n) + a1 * n) / 7}
                else
                    alpha[2, 4] = (1..4).map{|n| (a0 * (5-n) + a1 * n) / 5}
                    alpha[6] = 0
                    alpha[7] = 255
                end
                alpha.pack('C8')
                code = BinUtils.get_int64_le(bin) >> 16
                [alpha, code]
            end

            def self.get_rgb565(c)
                r = (c & 0xf800) >> 8
                g = (c & 0x07e0) >> 3
                b = (c & 0x001f) << 3
                [r | r >> 5, g | g >> 6, b | b >> 5]
            end

            def self.get_rgb565a(c)
                r = (c & 0xf800) >> 8
                g = (c & 0x07e0) >> 3
                b = (c & 0x001f) << 3
                [r | r >> 5, g | g >> 6, b | b >> 5, 255]
            end
        end
    end
end
