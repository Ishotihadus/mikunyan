require 'bin_utils'

module Mikunyan
    # Class for manipulating binary string
    # @attr [Symbol] endian endianness
    # @attr [Integer] pos position
    # @attr [Integer] length data size
    class BinaryReader
        attr_accessor :endian, :pos, :length

        # Constructor
        # @param [String] data binary string
        # @param [Symbol] endian endianness
        def initialize(data, endian = :big)
            @data = data
            @pos = 0
            @length = data.bytesize
            @endian = endian
        end

        # Returns whether little endian or not
        # @return [Boolean]
        def little?
            @endian == :little
        end

        # Jump to given position
        # @param [Integer] pos position
        def jmp(pos=0)
            @pos = pos
        end

        # Advance position given size
        # @param [Integer] size size
        def adv(size=0)
            @pos += size
        end

        # Round up position to multiple of given size
        # @param [Integer] size size
        def align(size)
            @pos = (@pos + size - 1) / size * size
        end

        # Read given size of binary string and seek
        # @param [Integer] size size
        # @return [String] data
        def read(size)
            data = @data.byteslice(@pos, size)
            @pos += size
            data
        end

        # Read given size of binary string from specified position. This method does not seek.
        # @param [Integer] size size
        # @param [Integer] pos position
        # @return [String] data
        def read_abs(size, pos)
            @data.byteslice(pos, size)
        end

        # Read string until null character
        # @return [String] string
        def cstr
            r = @data.unpack("@#{pos}Z*")[0]
            @pos += r.bytesize + 1
            r
        end

        # Read 8bit signed integer
        def i8
            i8s
        end

        # Read 8bit signed integer
        def i8s
            r = BinUtils.get_sint8(@data, @pos)
            @pos += 1
            r
        end

        # Read 8bit unsigned integer
        def i8u
            r = BinUtils.get_int8(@data, @pos)
            @pos += 1
            r
        end

        # Read 16bit signed integer
        def i16
            i16s
        end

        # Read 16bit signed integer
        def i16s
            r = little? ? BinUtils.get_sint16_le(@data, @pos) : BinUtils.get_sint16_be(@data, @pos)
            @pos += 2
            r
        end

        # Read 16bit unsigned integer
        def i16u
            r = little? ? BinUtils.get_int16_le(@data, @pos) : BinUtils.get_int16_be(@data, @pos)
            @pos += 2
            r
        end

        # Read 32bit signed integer
        def i32
            i32s
        end

        # Read 32bit signed integer
        def i32s
            r = little? ? BinUtils.get_sint32_le(@data, @pos) : BinUtils.get_sint32_be(@data, @pos)
            @pos += 4
            r
        end

        # Read 32bit unsigned integer
        def i32u
            r = little? ? BinUtils.get_int32_le(@data, @pos) : BinUtils.get_int32_be(@data, @pos)
            @pos += 4
            r
        end

        # Read 64bit signed integer
        def i64
            i64s
        end

        # Read 64bit signed integer
        def i64s
            r = little? ? BinUtils.get_sint64_le(@data, @pos) : BinUtils.get_sint64_be(@data, @pos)
            @pos += 8
            r
        end

        # Read 64bit unsigned integer
        def i64u
            r = little? ? BinUtils.get_int64_le(@data, @pos) : BinUtils.get_int64_be(@data, @pos)
            @pos += 8
            r
        end

        # Read 32bit floating point value
        def float
            r = little? ? @data.byteslice(@pos, 4).unpack('e')[0] : @data.byteslice(@pos, 4).unpack('g')[0]
            @pos += 4
            r
        end

        # Read 64bit floating point value
        def double
            r = little? ? @data.byteslice(@pos, 8).unpack('E')[0] : @data.byteslice(@pos, 8).unpack('G')[0]
            @pos += 8
            r
        end
    end
end
