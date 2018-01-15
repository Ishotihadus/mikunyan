require 'bin_utils'
require 'fiddle'

module Mikunyan
    module DecodeHelper
        # Class for decode ASTC block
        # @attr_reader [String] data decoded data
        class AstcBlockDecoder
            attr_reader :data

            # Decode block
            # @param [String] bin binary
            # @param [Integer] bw block width
            # @param [Integer] bh block height
            def initialize(bin, bw, bh)
                if bin[0].ord == 0xfc && bin[1].ord % 2 == 1
                    @data = (bin[9] + bin[11] + bin[13] + bin[15]) * bw * bh
                else
                    @d2 = BinUtils.get_int64_le(bin)
                    @d1 = BinUtils.get_int64_le(bin, 8)
                    @bw = bw
                    @bh = bh

                    decode_block_params
                    decode_endpoints
                    decode_weights
                    select_partition
                    applicate_color
                end
            end

            private

            WeightPrecTableA = [nil, nil, 0, 3, 0, 5, 3, 0, nil, nil, 5, 3, 0, 5, 3, 0]
            WeightPrecTableB = [nil, nil, 1, 0, 2, 0, 1, 3, nil, nil, 1, 2, 4, 2, 3, 5]

            CemTableA = [0, 0, 3, 0, 5, 3, 0, 5, 3, 0, 5, 3, 0, 5, 3, 0, 5, 3, 0]
            CemTableB = [1, 2, 1, 3, 1, 2, 4, 2, 3, 5, 3, 4, 6, 4, 5, 7, 5, 6, 8]

            TritsTable = [
                [0, 1, 2, 0, 0, 1, 2, 1, 0, 1, 2, 2, 0, 1, 2, 2, 0, 1, 2, 0, 0, 1, 2, 1, 0, 1, 2, 2, 0, 1, 2, 0, 0, 1, 2, 0, 0, 1, 2, 1, 0, 1, 2, 2, 0, 1, 2, 2, 0, 1, 2, 0, 0, 1, 2, 1, 0, 1, 2, 2, 0, 1, 2, 1, 0, 1, 2, 0, 0, 1, 2, 1, 0, 1, 2, 2, 0, 1, 2, 2, 0, 1, 2, 0, 0, 1, 2, 1, 0, 1, 2, 2, 0, 1, 2, 2, 0, 1, 2, 0, 0, 1, 2, 1, 0, 1, 2, 2, 0, 1, 2, 2, 0, 1, 2, 0, 0, 1, 2, 1, 0, 1, 2, 2, 0, 1, 2, 2, 0, 1, 2, 0, 0, 1, 2, 1, 0, 1, 2, 2, 0, 1, 2, 2, 0, 1, 2, 0, 0, 1, 2, 1, 0, 1, 2, 2, 0, 1, 2, 0, 0, 1, 2, 0, 0, 1, 2, 1, 0, 1, 2, 2, 0, 1, 2, 2, 0, 1, 2, 0, 0, 1, 2, 1, 0, 1, 2, 2, 0, 1, 2, 1, 0, 1, 2, 0, 0, 1, 2, 1, 0, 1, 2, 2, 0, 1, 2, 2, 0, 1, 2, 0, 0, 1, 2, 1, 0, 1, 2, 2, 0, 1, 2, 2, 0, 1, 2, 0, 0, 1, 2, 1, 0, 1, 2, 2, 0, 1, 2, 2, 0, 1, 2, 0, 0, 1, 2, 1, 0, 1, 2, 2, 0, 1, 2, 2],
                [0, 0, 0, 0, 1, 1, 1, 0, 2, 2, 2, 0, 2, 2, 2, 0, 0, 0, 0, 1, 1, 1, 1, 1, 2, 2, 2, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 0, 2, 2, 2, 0, 2, 2, 2, 0, 0, 0, 0, 1, 1, 1, 1, 1, 2, 2, 2, 1, 1, 1, 1, 0, 0, 0, 0, 0, 1, 1, 1, 0, 2, 2, 2, 0, 2, 2, 2, 0, 0, 0, 0, 1, 1, 1, 1, 1, 2, 2, 2, 1, 2, 2, 2, 0, 0, 0, 0, 0, 1, 1, 1, 0, 2, 2, 2, 0, 2, 2, 2, 0, 0, 0, 0, 1, 1, 1, 1, 1, 2, 2, 2, 1, 2, 2, 2, 0, 0, 0, 0, 0, 1, 1, 1, 0, 2, 2, 2, 0, 2, 2, 2, 0, 0, 0, 0, 1, 1, 1, 1, 1, 2, 2, 2, 1, 0, 0, 0, 1, 0, 0, 0, 0, 1, 1, 1, 0, 2, 2, 2, 0, 2, 2, 2, 0, 0, 0, 0, 1, 1, 1, 1, 1, 2, 2, 2, 1, 1, 1, 1, 1, 0, 0, 0, 0, 1, 1, 1, 0, 2, 2, 2, 0, 2, 2, 2, 0, 0, 0, 0, 1, 1, 1, 1, 1, 2, 2, 2, 1, 2, 2, 2, 1, 0, 0, 0, 0, 1, 1, 1, 0, 2, 2, 2, 0, 2, 2, 2, 0, 0, 0, 0, 1, 1, 1, 1, 1, 2, 2, 2, 1, 2, 2, 2, 1],
                [0, 0, 0, 2, 0, 0, 0, 2, 0, 0, 0, 2, 2, 2, 2, 2, 1, 1, 1, 2, 1, 1, 1, 2, 1, 1, 1, 2, 0, 0, 0, 2, 0, 0, 0, 2, 0, 0, 0, 2, 0, 0, 0, 2, 2, 2, 2, 2, 1, 1, 1, 2, 1, 1, 1, 2, 1, 1, 1, 2, 0, 0, 0, 2, 0, 0, 0, 2, 0, 0, 0, 2, 0, 0, 0, 2, 2, 2, 2, 2, 1, 1, 1, 2, 1, 1, 1, 2, 1, 1, 1, 2, 0, 0, 0, 2, 0, 0, 0, 2, 0, 0, 0, 2, 0, 0, 0, 2, 2, 2, 2, 2, 1, 1, 1, 2, 1, 1, 1, 2, 1, 1, 1, 2, 2, 2, 2, 2, 0, 0, 0, 2, 0, 0, 0, 2, 0, 0, 0, 2, 2, 2, 2, 2, 1, 1, 1, 2, 1, 1, 1, 2, 1, 1, 1, 2, 1, 1, 1, 2, 0, 0, 0, 2, 0, 0, 0, 2, 0, 0, 0, 2, 2, 2, 2, 2, 1, 1, 1, 2, 1, 1, 1, 2, 1, 1, 1, 2, 1, 1, 1, 2, 0, 0, 0, 2, 0, 0, 0, 2, 0, 0, 0, 2, 2, 2, 2, 2, 1, 1, 1, 2, 1, 1, 1, 2, 1, 1, 1, 2, 1, 1, 1, 2, 0, 0, 0, 2, 0, 0, 0, 2, 0, 0, 0, 2, 2, 2, 2, 2, 1, 1, 1, 2, 1, 1, 1, 2, 1, 1, 1, 2, 2, 2, 2, 2],
                [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 2, 2, 2, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 2, 2, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 2, 2, 2, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2, 2, 2, 2],
                [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 2, 2, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 2, 2, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2, 2, 2, 2, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2, 2, 2, 2, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2]
            ]

            QuintsTable = [
                [0, 1, 2, 3, 4, 0, 4, 4, 0, 1, 2, 3, 4, 1, 4, 4, 0, 1, 2, 3, 4, 2, 4, 4, 0, 1, 2, 3, 4, 3, 4, 4, 0, 1, 2, 3, 4, 0, 4, 0, 0, 1, 2, 3, 4, 1, 4, 1, 0, 1, 2, 3, 4, 2, 4, 2, 0, 1, 2, 3, 4, 3, 4, 3, 0, 1, 2, 3, 4, 0, 2, 3, 0, 1, 2, 3, 4, 1, 2, 3, 0, 1, 2, 3, 4, 2, 2, 3, 0, 1, 2, 3, 4, 3, 2, 3, 0, 1, 2, 3, 4, 0, 0, 1, 0, 1, 2, 3, 4, 1, 0, 1, 0, 1, 2, 3, 4, 2, 0, 1, 0, 1, 2, 3, 4, 3, 0, 1],
                [0, 0, 0, 0, 0, 4, 4, 4, 1, 1, 1, 1, 1, 4, 4, 4, 2, 2, 2, 2, 2, 4, 4, 4, 3, 3, 3, 3, 3, 4, 4, 4, 0, 0, 0, 0, 0, 4, 0, 4, 1, 1, 1, 1, 1, 4, 1, 4, 2, 2, 2, 2, 2, 4, 2, 4, 3, 3, 3, 3, 3, 4, 3, 4, 0, 0, 0, 0, 0, 4, 0, 0, 1, 1, 1, 1, 1, 4, 1, 1, 2, 2, 2, 2, 2, 4, 2, 2, 3, 3, 3, 3, 3, 4, 3, 3, 0, 0, 0, 0, 0, 4, 0, 0, 1, 1, 1, 1, 1, 4, 1, 1, 2, 2, 2, 2, 2, 4, 2, 2, 3, 3, 3, 3, 3, 4, 3, 3],
                [0, 0, 0, 0, 0, 0, 0, 4, 0, 0, 0, 0, 0, 0, 1, 4, 0, 0, 0, 0, 0, 0, 2, 4, 0, 0, 0, 0, 0, 0, 3, 4, 1, 1, 1, 1, 1, 1, 4, 4, 1, 1, 1, 1, 1, 1, 4, 4, 1, 1, 1, 1, 1, 1, 4, 4, 1, 1, 1, 1, 1, 1, 4, 4, 2, 2, 2, 2, 2, 2, 4, 4, 2, 2, 2, 2, 2, 2, 4, 4, 2, 2, 2, 2, 2, 2, 4, 4, 2, 2, 2, 2, 2, 2, 4, 4, 3, 3, 3, 3, 3, 3, 4, 4, 3, 3, 3, 3, 3, 3, 4, 4, 3, 3, 3, 3, 3, 3, 4, 4, 3, 3, 3, 3, 3, 3, 4, 4]
            ]

            def [](i, j = 1)
                if j < 1
                    0
                elsif j == 1
                    i < 64 ? @d2[i] : @d1[i - 64]
                else
                    if i + j <= 64
                        @d2 >> i & (1 << j) - 1
                    elsif i >= 64
                        @d1 >> (i - 64) & (1 << j) - 1
                    else
                        @d2 >> i | (@d1 & (1 << i + j - 64) - 1) << 64 - i
                    end
                end
            end

            def decode_block_params
                # Block Mode
                @weight_range = @d2 >> 4 & 1 | @d2 >> 6 & 8
                @dual_plane = @d2 & 0x400 == 0x400
                if @d2 & 0x3 != 0
                    @weight_range |= @d2 << 1 & 6
                    case @d2 & 0xc
                    when 0
                        @width = (@d2 >> 7 & 3) + 4
                        @height = (@d2 >> 5 & 3) + 2
                    when 0x4
                        @width = (@d2 >> 7 & 3) + 8
                        @height = (@d2 >> 5 & 3) + 2
                    when 0x8
                        @width = (@d2 >> 5 & 3) + 2
                        @height = (@d2 >> 7 & 3) + 8
                    else # 0xc
                        if @d2 & 0x100 == 0
                            @width = (@d2 >> 5 & 3) + 2
                            @height = @d2[7] + 6
                        else
                            @width = @d2[7] + 2
                            @height = (@d2 >> 5 & 3) + 2
                        end
                    end
                else
                    @weight_range |= @d2 >> 1 & 6
                    case @d2 & 0x180
                    when 0
                        @width = 12
                        @height = (@d2 >> 5 & 3) + 2
                    when 0x80
                        @width = (@d2 >> 5 & 3) + 2
                        @height = 12
                    when 0x180
                        @width = (@d2 & 0x20 == 0) ? 6 : 10
                        @height = 16 - @width
                    else # 0x100
                        @width = (@d2 >> 5 & 3) + 6
                        @height = (@d2 >> 9 & 3) + 6
                        @dual_plane = false
                        @weight_range &= 7
                    end
                end

                # Count Partitions
                @part_num = (@d2 >> 11 & 3) + 1

                # Count Weight Bits
                @weight_num = @width * @height
                @weight_num *= 2 if @dual_plane
                case WeightPrecTableA[@weight_range]
                when 3
                    @weight_bit = @weight_num * WeightPrecTableB[@weight_range] + (@weight_num * 8 + 4) / 5
                when 5
                    @weight_bit = @weight_num * WeightPrecTableB[@weight_range] + (@weight_num * 7 + 2) / 3
                else # 0
                    @weight_bit = @weight_num * WeightPrecTableB[@weight_range]
                end

                # CEM
                if @part_num == 1
                    @cem = [@d2 >> 13 & 0xf]
                    config_bit = 17
                else
                    cembase = @d2 >> 23 & 3
                    if cembase == 0
                        @cem = Array.new(@part_num, @d2 >> 25 & 0xf)
                        config_bit = 29
                    else
                        @cem = (0...@part_num).map{|i| ((@d2 >> (25 + i) & 1) + cembase - 1) << 2}

                        case @part_num
                        when 2
                            @cem[0] |= @d2 >> 27 & 3
                            @cem[1] |= self[126 - @weight_bit, 2]
                        when 3
                            @cem[0] |= @d2[28]
                            @cem[0] |= self[123 - @weight_bit] << 1
                            @cem[1] |= self[124 - @weight_bit, 2]
                            @cem[2] |= self[126 - @weight_bit, 2]
                        else # 4
                            4.times do |i|
                                @cem[i] |= self[120 + 2 * i - @weight_bit, 2]
                            end
                        end

                        config_bit = 25 + @part_num * 3
                    end
                end

                # Count Color Endpoint Bits
                config_bit += 2 if @dual_plane
                remain_bit = 128 - config_bit - @weight_bit
                @cem_num = @cem.map{|i| (i >> 1 & 6) + 2}.inject(:+)

                CemTableA.count.times do |n|
                    i = CemTableA.count - n - 1
                    case CemTableA[i]
                    when 3
                        @cem_bit = @cem_num * CemTableB[i] + (@cem_num * 8 + 4) / 5
                    when 5
                        @cem_bit = @cem_num * CemTableB[i] + (@cem_num * 7 + 2) / 3
                    else # 0
                        @cem_bit = @cem_num * CemTableB[i]
                    end

                    if @cem_bit <= remain_bit
                        @cem_range = i
                        break
                    end
                end

                if @dual_plane
                    if @part_num == 1 || cembase == 0
                        @plane_selector = self[126 - @weight_bit, 2]
                    else
                        @plane_selector = self[130 - @weight_bit - @part_num * 3, 2]
                    end
                end
            end

            def decode_endpoints
                values = decode_intseq_raw(self[@part_num == 1 ? 17 : 29, @cem_bit], CemTableA[@cem_range], CemTableB[@cem_range], @cem_num).map do |e|
                    unquantize_endpoint(CemTableA[@cem_range], CemTableB[@cem_range], e[0], e[1])
                end

                @endpoint = @cem.map do |cem|
                    v = values.slice!(0, (cem >> 1 & 6) + 2)
                    case cem
                    when 0
                        [v[0], v[0], v[0], 255, v[1], v[1], v[1], 255]
                    when 1
                        l0 = (v[0] >> 2) | (v[1] & 0xc0)
                        l1 = (l0 + (v[1] & 0x3f)).clamp(0, 255)
                        [l0, l0, l0, 255, l1, l1, l1, 255]
                    when 4
                        [v[0], v[0], v[0], v[2], v[1], v[1], v[1], v[3]]
                    when 5
                        v[1], v[0] = bit_transfer_signed(v[1], v[0])
                        v[3], v[2] = bit_transfer_signed(v[3], v[2])
                        [v[0], v[0], v[0], v[2], v[0] + v[1], v[0] + v[1], v[0] + v[1], v[2] + v[3]].map{|i| i.clamp(0, 255)}
                    when 6
                        [v[0] * v[3] >> 8, v[1] * v[3] >> 8, v[2] * v[3] >> 8, 255, v[0], v[1], v[2], 255]
                    when 8
                        if v[0] + v[2] + v[4] <= v[1] + v[3] + v[5]
                            [v[0], v[2], v[4], 255, v[1], v[3], v[5], 255]
                        else
                            blue_contract(v[1], v[3], v[5], 255, v[0], v[2], v[4], 255)
                        end
                    when 9
                        v[1], v[0] = bit_transfer_signed(v[1], v[0])
                        v[3], v[2] = bit_transfer_signed(v[3], v[2])
                        v[5], v[4] = bit_transfer_signed(v[5], v[4])
                        if v[1] + v[3] + v[5] >= 0
                            [v[0], v[2], v[4], 255, v[0] + v[1], v[2] + v[3], v[4] + v[5], 255].map{|i| i.clamp(0, 255)}
                        else
                            blue_contract(v[0] + v[1], v[2] + v[3], v[4] + v[5], 255, v[0], v[2], v[4], 255).map{|i| i.clamp(0, 255)}
                        end
                    when 10
                        [v[0] * v[3] >> 8, v[1] * v[3] >> 8, v[2] * v[3] >> 8, v[4], v[0], v[1], v[2], v[5]]
                    when 12
                        if v[0] + v[2] + v[4] <= v[1] + v[3] + v[5]
                            [v[0], v[2], v[4], v[6], v[1], v[3], v[5], v[7]]
                        else
                            blue_contract(v[1], v[3], v[5], v[7], v[0], v[2], v[4], v[6])
                        end
                    when 13
                        v[1], v[0] = bit_transfer_signed(v[1], v[0])
                        v[3], v[2] = bit_transfer_signed(v[3], v[2])
                        v[5], v[4] = bit_transfer_signed(v[5], v[4])
                        v[7], v[6] = bit_transfer_signed(v[7], v[6])
                        if v[1] + v[3] + v[5] >= 0
                            [v[0], v[2], v[4], v[6], v[0] + v[1], v[2] + v[3], v[4] + v[5], v[6] + v[7]].map{|i| i.clamp(0, 255)}
                        else
                            blue_contract(v[0] + v[1], v[2] + v[3], v[4] + v[5], v[6] + v[7], v[0], v[2], v[4], v[6]).map{|i| i.clamp(0, 255)}
                        end
                    else
                        throw NotImplementedError.new("HDR image is not supported. (CEM: #{cem})")
                    end
                end
            end

            def bit_transfer_signed(a, b)
                b = (b >> 1) | (a & 0x80)
                a = (a >> 1) & 0x3f
                [a[5] == 1 ? a - 0x40 : a, b]
            end

            def blue_contract(r1, g1, b1, a1, r2, g2, b2, a2)
                [(r1 + b1) >> 1, (g1 + b1) >> 1, b1, a1, (r2 + b2) >> 1, (g2 + b2) >> 1, b2, a2]
            end

            def decode_weights
                data = (0...(@weight_bit + 7) / 8).map{|i| (((self[120 - i * 8, 8]) * 0x80200802) & 0x0884422110) * 0x0101010101 >> 32 & 0xff}
                    .map.with_index{|e, i| e << i * 8}.inject(:|) & (1 << @weight_bit) - 1

                weight_point = decode_intseq_raw(data, WeightPrecTableA[@weight_range], WeightPrecTableB[@weight_range], @weight_num).map do |e|
                    unquantize_weight(WeightPrecTableA[@weight_range], WeightPrecTableB[@weight_range], e[0], e[1])
                end

                ds = (1024 + @bw / 2) / (@bw - 1)
                dt = (1024 + @bh / 2) / (@bh - 1)

                if @dual_plane
                    @weight0 = Fiddle::Pointer.malloc(@bw * @bh)
                    @weight1 = Fiddle::Pointer.malloc(@bw * @bh)

                    for t in 0...@bh
                        for s in 0...@bw
                            gs = (ds * s * (@width - 1) + 32) >> 6
                            gt = (dt * t * (@height - 1) + 32) >> 6
                            fs = gs & 0xf
                            ft = gt & 0xf
                            v = (gs >> 4) + (gt >> 4) * @width
                            w11 = (fs * ft + 8) >> 4
                            w10 = ft - w11
                            w01 = fs - w11
                            w00 = 16 - fs - ft + w11

                            p00 = weight_point[v * 2] || 0
                            p01 = weight_point[(v + 1) * 2] || 0
                            p10 = weight_point[(v + @width) * 2] || 0
                            p11 = weight_point[(v + @width + 1) * 2] || 0
                            @weight0[s + t * @bw] = (p00 * w00 + p01 * w01 + p10 * w10 + p11 * w11 + 8) >> 4

                            p00 = weight_point[v * 2 + 1] || 0
                            p01 = weight_point[(v + 1) * 2 + 1] || 0
                            p10 = weight_point[(v + @width) * 2 + 1] || 0
                            p11 = weight_point[(v + @width + 1) * 2 + 1] || 0
                            @weight1[s + t * @bw] = (p00 * w00 + p01 * w01 + p10 * w10 + p11 * w11 + 8) >> 4
                        end
                    end
                else
                    @weight = Fiddle::Pointer.malloc(@bw * @bh)

                    for t in 0...@bh
                        for s in 0...@bw
                            gs = (ds * s * (@width - 1) + 32) >> 6
                            gt = (dt * t * (@height - 1) + 32) >> 6
                            fs = gs & 0xf
                            ft = gt & 0xf
                            v = (gs >> 4) + (gt >> 4) * @width
                            w11 = (fs * ft + 8) >> 4

                            p00 = weight_point[v] || 0
                            p01 = weight_point[v + 1] || 0
                            p10 = weight_point[v + @width] || 0
                            p11 = weight_point[v + @width + 1] || 0
                            @weight[s + t * @bw] = (p00 * (16 - fs - ft + w11) + p01 * (fs - w11) + p10 * (ft - w11) + p11 * w11 + 8) >> 4
                        end
                    end
                end
            end

            def select_partition
                if @part_num > 1
                    small_block = @bw * @bh < 31

                    seed = (@d2 >> 13 & 0x3ff) | ((@part_num - 1) << 10)

                    rnum = seed
                    rnum ^= (rnum >> 15)
                    rnum = (rnum - (rnum << 17)) & 0xffffffff
                    rnum = (rnum + (rnum << 7)) & 0xffffffff
                    rnum = (rnum + (rnum << 4)) & 0xffffffff
                    rnum ^= rnum >> 5
                    rnum = (rnum + (rnum << 16)) & 0xffffffff
                    rnum ^= rnum >> 7
                    rnum ^= rnum >> 3
                    rnum = (rnum ^ (rnum << 6)) & 0xffffffff
                    rnum = rnum ^ (rnum >> 17)

                    seeds = [0, 4, 8, 12, 16, 20, 24, 28].map{|i| (rnum >> i) & 0xf}.map!{|e| e * e}
                    sh = [seed & 2 == 2 ? 4 : 5, @part_num == 3 ? 6 : 5]
                    sh.reverse! if seed & 1 == 0
                    seeds.map!.with_index{|e, i| e >> sh[i % 2]}

                    @partition = (0...@bw * @bh).map do |i|
                        x = i % @bw
                        y = i / @bw
                        if small_block
                            x <<= 1
                            y <<= 1
                        end

                        a = (seeds[0] * x + seeds[1] * y + (rnum >> 14)) & 0x3f
                        b = (seeds[2] * x + seeds[3] * y + (rnum >> 10)) & 0x3f
                        c = @part_num < 3 ? 0 : (seeds[4] * x + seeds[5] * y + (rnum >> 6)) & 0x3f
                        d = @part_num < 4 ? 0 : (seeds[6] * x + seeds[7] * y + (rnum >> 2)) & 0x3f

                        3 - [d, c, b, a].each_with_index.max[1]
                    end
                end
            end

            def applicate_color
                mem = Fiddle::Pointer.malloc(@bw * @bh * 4)

                if @dual_plane
                    plane_arr = [0, 1, 2, 3]
                    plane_arr.delete_at(@plane_selector)

                    if @partition
                        (@bw * @bh).times do |i|
                            part = @partition[i]
                            plane_arr.each{|c| mem[i * 4 + c] = select_color(@endpoint[part][c], @endpoint[part][4 + c], @weight0[i])}
                            mem[i * 4 + @plane_selector] = select_color(@endpoint[part][@plane_selector], @endpoint[part][4 + @plane_selector], @weight1[i])
                        end
                    else
                        (@bw * @bh).times do |i|
                            plane_arr.each{|c| mem[i * 4 + c] = select_color(@endpoint[0][c], @endpoint[0][4 + c], @weight0[i])}
                            mem[i * 4 + @plane_selector] = select_color(@endpoint[0][@plane_selector], @endpoint[0][4 + @plane_selector], @weight1[i])
                        end
                    end
                elsif @partition
                    (@bw * @bh).times do |i|
                        part = @partition[i]
                        4.times{|c| mem[i * 4 + c] = select_color(@endpoint[part][c], @endpoint[part][4 + c], @weight[i])}
                    end
                else
                    (@bw * @bh).times do |i|
                        4.times{|c| mem[i * 4 + c] = select_color(@endpoint[0][c], @endpoint[0][4 + c], @weight[i])}
                    end
                end

                @data = mem.to_str
            end

            def select_color(v0, v1, weight)
                v0 |= v0 << 8
                v1 |= v1 << 8
                v = (v0 * (64 - weight) + v1 * weight + 32) >> 6
                (v * 255 + 32768) / 65536
            end

            def decode_intseq_raw(data, a, b, count)
                mask = (1 << b) - 1
                case a
                when 3
                    rc = (count + 4) / 5
                    ret = Array.new(rc * 5)
                    m = [0, 2 + b, 4 + b * 2, 5 + b * 3, 7 + b * 4]
                    rc.times do |i|
                        t = (data >> b & 3) | (data >> b * 2 & 0xc) | (data >> b * 3 & 0x10) | (data >> b * 4 & 0x60) | (data >> b * 5 & 0x80)
                        5.times do |j|
                            ret[i * 5 + j] = [data >> m[j] & mask, TritsTable[j][t]]
                        end
                        data >>= b * 5 + 8
                    end
                    ret[0, count]
                when 5
                    rc = (count + 2) / 3
                    ret = Array.new(rc * 3)
                    m = [0, 3 + b, 5 + b * 2]
                    rc.times do |i|
                        q = (data >> b & 7) | (data >> b * 2 & 0x18) | (data >> b * 3 & 0x60)
                        3.times do |j|
                            ret[i * 3 + j] = [data >> m[j] & mask, QuintsTable[j][q]]
                        end
                        data >>= b * 3 + 7
                    end
                    ret[0, count]
                else # 0
                    (0...count).map do |i|
                        [data >> b * i & mask, 0]
                    end
                end
            end

            def unquantize_endpoint(a, b, bit, val_d)
                if a == 0
                    case b
                    when 1
                        bit * 0xff
                    when 2
                        bit * 0x55
                    when 3
                        bit << 5 | bit << 2 | bit >> 1
                    when 4
                        bit << 4 | bit
                    when 5
                        bit << 3 | bit >> 2
                    when 6
                        bit << 2 | bit >> 4
                    when 7
                        bit << 1 | bit >> 6
                    else # 8
                        bit
                    end
                else
                    val_a = (bit & 1) * 0x1ff
                    tmp_b = bit >> 1
                    case b
                    when 1
                        val_b = 0
                        val_c = a == 3 ? 204 : 113
                    when 2
                        val_b = a == 3 ? (0b100010110) * tmp_b : (0b100001100) * tmp_b
                        val_c = a == 3 ? 93 : 54
                    when 3
                        val_b = a == 3 ? tmp_b << 7 | tmp_b << 2 | tmp_b : tmp_b << 7 | tmp_b << 1 | tmp_b >> 1
                        val_c = a == 3 ? 44 : 26
                    when 4
                        val_b = tmp_b << 6 | tmp_b >> (a == 3 ? 0 : 1)
                        val_c = a == 3 ? 22 : 13
                    when 5
                        val_b = tmp_b << 5 | tmp_b >> (a == 3 ? 2 : 3)
                        val_c = a == 3 ? 11 : 6
                    else # 6
                        val_b = tmp_b << 4 | tmp_b >> 4
                        val_c = 5
                    end
                    t = val_d * val_c + val_b
                    t ^= val_a
                    (val_a & 0x80) | (t >> 2)
                end
            end

            def unquantize_weight(a, b, bit, val_d)
                if a == 0
                    case b
                    when 1
                        t = bit == 1 ? 63 : 0
                    when 2
                        t = bit << 4 | bit << 2 | bit
                    when 3
                        t = bit << 3 | bit
                    when 4
                        t = bit << 2 | bit >> 2
                    else # 5
                        t = bit << 1 | bit >> 4
                    end
                elsif b == 0
                    t = (a == 3 ? [0, 32, 63] : [0, 16, 32, 47, 63])[val_d]
                else
                    val_a = (bit & 1) * 0x7f
                    case b
                    when 1
                        val_b = 0
                        val_c = a == 3 ? 50 : 28
                    when 2
                        val_b = (a == 3 ? 0b1000101 : 0b1000010) * bit[1]
                        val_c = a == 3 ? 23 : 13
                    else # 3
                        val_b = (bit << 4 | bit >> 1) & 0b1100011
                        val_c = 11
                    end
                    t = val_d * val_c + val_b
                    t ^= val_a
                    t = (val_a & 0x20) | (t >> 2)
                end
                t > 32 ? t + 1 : t
            end
        end
    end
end
