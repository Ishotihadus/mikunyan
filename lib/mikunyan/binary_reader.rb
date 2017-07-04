require 'bin_utils'

module Mikunyan
    class BinaryReader
        attr_accessor :endian, :pos, :length

        def initialize(data, endian = :big)
            @data = data
            @pos = 0
            @length = data.bytesize
            @endian = endian
        end

        def little?
            @endian == :little
        end

        def jmp(pos = 0)
            @pos = pos
        end

        def adv(size = 0)
            @pos += size
        end

        def align(size)
            @pos = (@pos + size - 1) / size * size
        end

        def read(size)
            data = @data.byteslice(@pos, size)
            @pos += size
            data
        end

        def cstr
            r = @data.unpack("@#{pos}Z*")[0]
            @pos += r.bytesize + 1
            r
        end

        def i8
            i8s
        end

        def i8s
            r = BinUtils.get_sint8(@data, @pos)
            @pos += 1
            r
        end

        def i8u
            r = BinUtils.get_int8(@data, @pos)
            @pos += 1
            r
        end

        def i16
            i16s
        end

        def i16s
            r = little? ? BinUtils.get_sint16_le(@data, @pos) : BinUtils.get_sint16_be(@data, @pos)
            @pos += 2
            r
        end

        def i16u
            r = little? ? BinUtils.get_int16_le(@data, @pos) : BinUtils.get_int16_be(@data, @pos)
            @pos += 2
            r
        end

        def i32
            i32s
        end

        def i32s
            r = little? ? BinUtils.get_sint32_le(@data, @pos) : BinUtils.get_sint32_be(@data, @pos)
            @pos += 4
            r
        end

        def i32u
            r = little? ? BinUtils.get_int32_le(@data, @pos) : BinUtils.get_int32_be(@data, @pos)
            @pos += 4
            r
        end

        def i64
            i64s
        end

        def i64s
            r = little? ? BinUtils.get_sint64_le(@data, @pos) : BinUtils.get_sint64_be(@data, @pos)
            @pos += 8
            r
        end

        def i64u
            r = little? ? BinUtils.get_int64_le(@data, @pos) : BinUtils.get_int64_be(@data, @pos)
            @pos += 8
            r
        end

        def float
            r = little? ? @data.byteslice(@pos, 4).unpack('e')[0] : @data.byteslice(@pos, 4).unpack('g')[0]
            @pos += 4
            r
        end

        def double
            r = little? ? @data.byteslice(@pos, 8).unpack('E')[0] : @data.byteslice(@pos, 8).unpack('G')[0]
            @pos += 8
            r
        end
    end
end
