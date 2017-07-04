require 'extlz4'

module Mikunyan
    class AssetBundle
        attr_accessor :signature, :format, :unity_version, :generator_version, :assets

        def self.load(bin)
            r = AssetBundle.new
            r.load(bin)
            r
        end

        def self.file(file)
            AssetBundle.load(File.binread(file))
        end

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

        private

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
                asset = Asset.new(asset_name)
                asset.load(asset_data)
                @assets << asset
            end
        end

        def load_unity_fs(br)
            @assets = []

            file_size = br.i64u
            ci_block_size = br.i32u
            ui_block_size = br.i32u
            flags = br.i32u

            head = BinaryReader.new(uncompress(br.read(ci_block_size), ui_block_size, flags))
            guid = head.read(16)

            blocks = []
            block_count = head.i32u
            block_count.times{ blocks << {:u => head.i32u, :c => head.i32u, :f => head.i16u} }

            asset_blocks = []
            asset_count = head.i32u
            asset_count.times{ asset_blocks << {:offset => head.i64u, :size => head.i64u, :status => head.i32, :name => head.cstr} }

            raw_data = ''
            blocks.each{|b| raw_data << uncompress(br.read(b[:c]), b[:u], b[:f])}

            asset_blocks.each do |b|
                asset = Asset.new(b[:name])
                asset.load(raw_data.byteslice(b[:offset], b[:size]))
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
