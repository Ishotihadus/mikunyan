require 'extlz4'

module Mikunyan
    # Class for representing Unity AssetBundle
    # @attr_reader [String] signature file signature (UnityRaw or UnityFS)
    # @attr_reader [Integer] format file format number
    # @attr_reader [String] unity_version version string of Unity to use this AssetBundle
    # @attr_reader [String] generator_version version string of generator
    # @attr_reader [Array<Mikunyan::Asset>] assets included Assets
    class AssetBundle
        attr_reader :signature, :format, :unity_version, :generator_version, :assets

        # Load AssetBundle from binary string
        # @param [String] bin binary data
        # @return [Mikunyan::AssetBundle] deserialized AssetBundle object
        def self.load(bin)
            r = AssetBundle.new
            r.send(:load, bin)
            r
        end

        # Load AssetBundle from file
        # @param [String] file file name
        # @return [Mikunyan::AssetBundle] deserialized AssetBundle object
        def self.file(file)
            AssetBundle.load(File.binread(file))
        end

        private

        def load(bin)
            br = BinaryReader.new(bin)
            @signature = br.cstr
            @format = br.i32
            @unity_version = br.cstr
            @generator_version = br.cstr

            case @signature
            when 'UnityRaw'
                load_unity_raw(br)
            when 'UnityFS'
                load_unity_fs(br)
            else
                warn("Unknown signature: #{@signature}")
            end
        end

        def load_unity_raw(br)
            @assets = []

            file_size = br.i32u
            header_size = br.i32u

            br.jmp(header_size)
            asset_count = br.i32u
            asset_count.times do
                asset_pos = br.pos
                asset_name = br.cstr
                asset_header_size = br.i32u
                asset_size = br.i32u
                br.jmp(asset_pos + asset_header_size - 4)
                asset_data = br.read(asset_size)
                asset = Asset.load(asset_data, asset_name)
                @assets << asset
            end
        end

        def load_unity_fs(br)
            @assets = []

            file_size = br.i64u
            ci_block_size = br.i32u
            ui_block_size = br.i32u
            flags = br.i32u

            head = BinaryReader.new(uncompress(flags & 0x80 == 0 ? br.read(ci_block_size) : br.read_abs(ci_block_size, file_size - ci_block_size), ui_block_size, flags))
            guid = head.read(16)

            blocks = []
            block_count = head.i32u
            block_count.times{ blocks << {:u => head.i32u, :c => head.i32u, :f => head.i16u} }

            asset_blocks = []
            asset_count = head.i32u
            asset_count.times{ asset_blocks << {:offset => head.i64u, :size => head.i64u, :status => head.i32, :name => head.cstr} }

            raw_data = String.new
            blocks.each{|b| raw_data << uncompress(br.read(b[:c]), b[:u], b[:f])}

            asset_blocks.each do |b|
                next if b[:name].end_with?('.resS')
                res_s = asset_blocks.find{|e| e[:name] == "#{b[:name]}.resS"}
                asset = Asset.load(raw_data.byteslice(b[:offset], b[:size]), b[:name], res_s && raw_data.byteslice(res_s[:offset], res_s[:size]))
                @assets << asset
            end
        end

        def uncompress(block, max_dest_size, flags)
            case flags & 0x3f
            when 0
                block
            when 2, 3
                LZ4::raw_decode(block, max_dest_size)
            else
                warn("Unknown compression flag: #{@flags}")
                block
            end
        end
    end
end
