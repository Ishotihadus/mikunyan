# frozen_string_literal: true

require 'extlz4'
require 'extlzma'
require 'mikunyan/asset'
require 'mikunyan/binary_reader'

module Mikunyan
  # Class for representing Unity AssetBundle
  # @attr_reader [String] signature file signature (UnityRaw or UnityFS)
  # @attr_reader [Integer] format file format number
  # @attr_reader [String] unity_version version string of Unity for this AssetBundle
  # @attr_reader [String] generator_version version string of generator
  # @attr_reader [String] guid unique identifier (can be zero)
  # @attr_reader [Array<Mikunyan::Asset>] assets contained Assets
  class AssetBundle
    attr_reader :signature, :format, :unity_version, :generator_version, :guid, :assets, :blobs

    AssetEntry = Struct.new(:name, :data, :blob?, :status, keyword_init: true)

    # @param [String,Integer] index
    # @return [Mikunyan::Asset,nil]
    def [](index)
      index.is_a?(String) ? @assets.find{|e| e.name == index} : @assets[index]
    end

    # Same as assets.each
    # @return [Enumerator<Mikunyan::Asset>,Array<Mikunyan::Asset>]
    def each_asset(&block)
      @assets.each(&block)
    end

    # Loads AssetBundle from binary string
    # @param [String,IO] bin binary data
    # @return [Mikunyan::AssetBundle] deserialized AssetBundle object
    def self.load(bin)
      r = AssetBundle.new
      r.send(:load, bin)
      r
    end

    # Loads AssetBundle from file
    # @param [String] file file name
    # @return [Mikunyan::AssetBundle] deserialized AssetBundle object
    def self.file(file)
      File.open(file, 'rb') do |io|
        AssetBundle.load(io)
      end
    end

    private

    def load(bin)
      br = BinaryReader.new(bin)
      @signature = br.cstr
      raise("Invalid signature: #{@signature}") unless @signature.start_with?('Unity')

      @format = br.i32
      @unity_version = br.cstr
      @generator_version = br.cstr

      @format < 6 ? load_unity_raw(br) : load_unity_fs(br)
    end

    # @param [Mikunyan::BinaryReader] br
    def load_unity_raw(br)
      @assets = []

      _file_size = br.i32u
      header_size = br.i32u
      br.pos = header_size
      # この部分全然わからん（ファイルの最後まで読まないとダメらしい?）
      block = br.read(nil)
      data = @signature == 'UnityRaw' ? block : uncompress_lzma(block, true)
      br = BinaryReader.new(data)

      asset_count = br.i32u
      asset_entries = Array.new(asset_count) do
        name = br.cstr
        offset = br.i32u
        size = br.i32u
        is_asset = ['', '.assets'].include?(split_name(name)[1]) && size > 16
        AssetEntry.new(name: name, data: br.read_abs(size, offset), blob?: !is_asset)
      end
      process_asset_entries(asset_entries)
    end

    # @param [Mikunyan::BinaryReader] br
    def load_unity_fs(br)
      file_size = br.i64u
      ci_block_size = br.i32u
      ui_block_size = br.i32u
      flags = br.i32u

      head = BinaryReader.new(uncompress(flags & 0x80 == 0 ? br.read(ci_block_size) : br.read_abs(ci_block_size, file_size - ci_block_size), ui_block_size, flags))
      @guid = head.read(16)

      block_count = head.i32u
      raw_data = Array.new(block_count) do
        u_size = head.i32u
        c_size = head.i32u
        flags = head.i16u
        uncompress(br.read(c_size), u_size, flags)
      end.join

      asset_count = head.i32u
      asset_entries = Array.new(asset_count) do
        offset = head.i64u
        size = head.i64u
        status = head.i32
        AssetEntry.new(name: head.cstr, data: raw_data.byteslice(offset, size), blob?: status != 4, status: status)
      end
      process_asset_entries(asset_entries)
    end

    def process_asset_entries(asset_entries)
      @blobs = asset_entries.select(&:blob?).map{|e| [e.name, e.data]}.to_h
      @assets = asset_entries.reject(&:blob?).map do |e|
        Asset.load(e.data, e.name, self)
      end
    end

    def uncompress(block, max_dest_size, flags)
      case flags & 0x3f
      when 0
        block
      when 1
        uncompress_lzma(block)
      when 2, 3
        LZ4.block_decode(block, max_dest_size)
      # when 4
      # LZHMA
      else
        warn("Unknown compression flag: #{flags}")
        block
      end
    end

    def uncompress_lzma(block, with_max_len = false)
      prop = block.ord
      filter = LZMA.lzma1(dictsize: block.unpack1('@1V'), lc: prop % 9, lp: (prop / 9) % 5, pb: prop / 45)
      max_len = block.unpack1('@5V') | block.unpack1('@9V') << 32 if with_max_len
      StringIO.open(block) do |io|
        io.seek(with_max_len ? 13 : 5)
        LZMA.raw_decode(io, filter) do |lzma|
          lzma.read(max_len)
        end
      end
    end

    def split_name(str)
      m = str.match(/\A(.*?)(\.[^.]*)?\z/)
      [m[1], m[2] || '']
    end
  end
end
