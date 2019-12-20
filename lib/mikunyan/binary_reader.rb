# frozen_string_literal: true

require 'bin_utils'

module Mikunyan
  # Class for manipulating binary string
  # @attr [Symbol] endian endianness
  class BinaryReader
    attr_accessor :endian

    # Constructor
    # @param [IO,String] io binary String or IO
    # @param [Symbol] endian endianness
    def initialize(io, endian = :big)
      @io = io.is_a?(String) ? StringIO.new(io, 'r') : io.dup
      @io.binmode
      @base_pos = @io.pos
      @endian = endian
    end

    # Returns whether little endian or not
    # @return [Boolean]
    def little?
      @endian == :little
    end

    # Tells current potision
    # @return [Integer]
    def pos
      @io.pos - @base_pos
    end

    # Jumps to given position
    # @param [Integer] jmp_pos position
    def jmp(jmp_pos = 0)
      @io.pos = jmp_pos + @base_pos
    end
    alias pos= jmp

    # Advances position given size
    # @param [Integer] size size
    def adv(size = 0)
      @io.seek(size, IO::SEEK_CUR)
    end

    # Rounds up position to multiple of given size
    # @param [Integer] size size
    def align(size)
      rem = pos % size
      adv(size - rem) if rem > 0
    end

    # Reads given size of binary string and seek
    # @param [Integer] size size
    # @return [String] data
    def read(size)
      ret = @io.read(size)
      raise EOFError if ret.nil? || size && ret.bytesize < size
      ret
    end

    # Reads given size of binary string from specified position. This method does not seek.
    # @param [Integer] size size
    # @param [Integer] jmp_pos position
    # @return [String] data
    def read_abs(size, jmp_pos)
      orig_pos = pos
      jmp(jmp_pos)
      ret = read(size)
      jmp(orig_pos)
      ret
    end

    # Reads string until null character
    # @return [String] string
    def cstr
      raise EOFError if @io.eof?
      @io.each_byte.take_while(&:nonzero?).pack('C*')
    end

    # Reads an 8bit bool value
    def bool
      i8u != 0
    end

    # Reads an 8bit signed integer value
    def i8s
      BinUtils.get_sint8(read(1))
    end
    alias i8 i8s

    # Reads an 8bit unsigned integer value
    def i8u
      @io.getbyte
    end

    # Reads a 16bit signed integer value
    def i16s
      little? ? BinUtils.get_sint16_le(read(2)) : BinUtils.get_sint16_be(read(2))
    end
    alias i16 i16s

    # Reads a 16bit unsigned integer value
    def i16u
      little? ? BinUtils.get_int16_le(read(2)) : BinUtils.get_int16_be(read(2))
    end

    # Reads a 32bit signed integer value
    def i32s
      little? ? BinUtils.get_sint32_le(read(4)) : BinUtils.get_sint32_be(read(4))
    end
    alias i32 i32s

    # Reads a 32bit unsigned integer value
    def i32u
      little? ? BinUtils.get_int32_le(read(4)) : BinUtils.get_int32_be(read(4))
    end

    # Reads a 64bit signed integer value
    def i64s
      little? ? BinUtils.get_sint64_le(read(8)) : BinUtils.get_sint64_be(read(8))
    end
    alias i64 i64s

    # Reads a 64bit unsigned integer value
    def i64u
      little? ? BinUtils.get_int64_le(read(8)) : BinUtils.get_int64_be(read(8))
    end

    # Reads a 32bit floating point value
    def float
      little? ? read(4).unpack1('e') : read(4).unpack1('g')
    end

    # Reads a 64bit floating point value
    def double
      little? ? read(8).unpack1('E') : read(8).unpack1('G')
    end
  end
end
