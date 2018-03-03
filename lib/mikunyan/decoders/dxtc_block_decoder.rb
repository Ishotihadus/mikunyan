require 'bin_utils'
require 'fiddle'

module Mikunyan
    module DecodeHelper
        # Module for decoding DXTC block
        module DxtcBlockDecoder
            def self.decode_dxt1_block(bin)
                c0 = BinUtils.get_int16_le(bin, 0)
                c1 = BinUtils.get_int16_le(bin, 2)
                color = [get_rgb565(c0), get_rgb565(c1), nil, nil]
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

            def self.get_rgb565(c)
                r = (c & 0xf800) >> 8
                g = (c & 0x07e0) >> 3
                b = (c & 0x001f) << 3
                [r | r >> 5, g | g >> 6, b | b >> 5, 255]
            end
        end
    end
end
