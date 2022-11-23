# frozen_string_literal: true

require 'mikunyan/type_tree'
require 'mikunyan/constants'
require 'mikunyan/object_value'
require 'mikunyan/base_object'

module Mikunyan
  # Class for representing Unity Asset
  # @attr_reader [String] name Asset name
  # @attr_reader [Integer] format file format number
  # @attr_reader [String] generator_version version string of generator
  # @attr_reader [Integer] target_platform target platform number
  # @attr_reader [Symbol] endian data endianness (:little or :big)
  # @attr_reader [Array<Mikunyan::Asset::Klass>] klasses defined classes
  # @attr_reader [Array<Mikunyan::Asset::ObjectEntry>] objects contained objects
  # @attr_reader [Array<Mikunyan::Asset::LocalObjectEntry>] add_ids ?
  # @attr_reader [Array<Mikunyan::Asset::Reference>] references reference data
  class Asset
    attr_reader :name, :format, :generator_version, :target_platform, :endian, :klasses, :objects, :add_ids, :references

    # Struct for representing Asset class definition
    # @attr [Integer] class_id class ID
    # @attr [Boolean] stripped?
    # @attr [Integer,nil] script_id script ID
    # @attr [String] hash hash value (16 or 32 bytes)
    # @attr [Mikunyan::TypeTree, nil] type_tree given TypeTree
    Klass = Struct.new(:class_id, :stripped?, :script_id, :hash, :type_tree)

    # Struct for representing Asset object information
    # @attr [Integer] path_id path ID
    # @attr [Integer] offset data offset
    # @attr [Integer] size data size
    # @attr [Integer,nil] type_id type ID
    # @attr [Integer,nil] class_id class ID
    # @attr [Integer,nil] class_idx class definition index
    # @attr [Boolean] destroyed? destroyed or not
    # @attr [String] data binary data of object
    # @attr [Mikunyan::Asset] parent_asset
    # @attr [Klass] klass
    ObjectEntry = Struct.new(
      :path_id, :offset, :size, :type_id, :class_id, :class_idx, :destroyed?, :stripped?,
      :data, :parent_asset, :klass,
      keyword_init: true
    ) do
      # Alias to {Asset#parse_object}
      def parse
        parent_asset.parse_object(self)
      end

      # Alias to {Asset#parse_object_simple}
      def parse_simple
        parent_asset.parse_object_simple(self)
      end

      # Returns object type name string
      # @return [String,nil] type name
      def type
        klass&.type_tree&.tree&.type || Mikunyan::Constants::CLASS_ID2NAME[class_id || klass&.class_id]
      end
    end

    LocalObjectEntry = Struct.new(:file_id, :local_id)

    # Struct for representing Asset reference information
    # @attr [String] path path
    # @attr [String] guid GUID (16 bytes)
    # @attr [Integer] type ?
    # @attr [String] file_path Asset name
    Reference = Struct.new(:path, :guid, :type, :file_path)

    # Strcut for container information
    # @attr [String] name
    # @attr [Integer] preload_index
    # @attr [Integer] path_id
    ContainerInfo = Struct.new(:name, :preload_index, :preload_size, :file_id, :path_id)

    # Load Asset from binary string
    # @param [String,IO] bin binary data
    # @param [String] name Asset name
    # @param [Mikunyan::AssetBundle] parent_bundle Parent AssetBundle
    # @return [Mikunyan::Asset] deserialized Asset object
    def self.load(bin, name, parent_bundle = nil)
      r = Asset.new(name, parent_bundle)
      r.send(:load, bin)
      r
    end

    # Load Asset from file
    # @param [String] file file name
    # @param [String] name Asset name (automatically generated if not specified)
    # @return [Mikunyan::Asset] deserialized Asset object
    def self.file(file, name = nil)
      name ||= File.basename(name, '.*')
      File.open(file, 'rb') do |io|
        Asset.load(io, name)
      end
    end

    # Same as objects.each
    # @return [Enumerator<Mikunyan::Asset::ObjectEntry>,Array<Mikunyan::Asset::ObjectEntry>]
    def each_object(&block)
      @objects.each(&block)
    end

    # Returns object with specified path ID
    # @return [ObjectEntry,nil]
    def path_id(id)
      @path_id_table[id]
    end

    # Returns list of all path IDs
    # @return [Array<Integer>] list of all path IDs
    def path_ids
      @objects.map(&:path_id)
    end

    # Returns list of containers
    # @return [Array<Hash>,nil] list of all containers
    def containers
      obj = @path_id_table[1]
      return nil unless obj.klass&.type_tree&.tree&.type == 'AssetBundle'

      parse_object(obj).m_Container.value.map do |e|
        ContainerInfo.new(e.first.value, e.second.preloadIndex.value, e.second.preloadSize.value,
                          e.second.asset.m_FileID.value, e.second.asset.m_PathID.value)
      end
    end

    # Parse object of given path ID
    # @param [Integer,ObjectEntry] obj path ID or object
    # @return [Mikunyan::BaseObject,nil] parsed object
    def parse_object(obj)
      obj = @path_id_table[obj] if obj.instance_of?(Integer)
      return nil unless obj.klass&.type_tree

      value_klass = Mikunyan::CustomTypes.get_custom_type(obj.klass.type_tree.tree.type, obj.class_id)
      ret = parse_object_private(BinaryReader.new(obj.data, @endian), obj.klass.type_tree.tree, value_klass)
      ret.object_entry = obj
      ret
    end

    # Parse object of given path ID and simplify it
    # @param [Integer,ObjectEntry] obj path ID or object
    # @return [Hash,nil] parsed object
    def parse_object_simple(obj)
      parse_object(obj)&.simplify
    end

    # Returns object type name string
    # @param [Integer,ObjectEntry] obj path ID or object
    # @return [String,nil] type name
    def object_type(obj)
      obj = @path_id_table[obj] if obj.instance_of?(Integer)
      obj&.type
    end

    # Alias to {ObjectValue#simplify} (for compatibility)
    def self.object_simplify(obj)
      obj.is_a?(ObjectValue) ? obj.simplify : obj
    end

    private

    # @param [Mikunyan::AssetBundle] bundle
    def initialize(name, bundle = nil)
      @name = name
      @endian = :big
      @bundle = bundle
    end

    def load(bin)
      br = BinaryReader.new(bin)

      meta_size = br.i32u
      file_size = br.i32u
      @format = br.i32u
      data_offset = br.i32u

      if @format >= 9
        @endian = br.bool ? :big : :little
        br.adv(3)
      else
        br.pos = file_size - meta_size
        @endian = br.bool ? :big : :little
      end

      if @format >= 22
        _meta_size = br.i32u
        _file_size = br.i64u
        data_offset = br.i64u
        br.adv(8)
      end

      br.endian = @endian

      @generator_version = br.cstr if @format >= 7
      @target_platform = br.i32 if @format >= 8
      has_type_trees = @format >= 13 ? br.bool : true
      type_count = br.i32u

      @klasses = Array.new(type_count) do
        class_id = br.i32s
        stripped = br.bool if @format >= 16
        script_id = br.i16 if @format >= 17
        hash = br.read(@format < 16 && class_id < 0 || @format >= 16 && class_id == 114 ? 32 : 16) if @format >= 13
        type_tree = has_type_trees ? TypeTree.load(br, @format) : TypeTree.load_default(class_id, hash)
        Klass.new(class_id, stripped, script_id, hash, type_tree)
      end

      wide_path_id = @format >= 14 || @format >= 7 && br.i32 != 0

      object_count = br.i32u
      @objects = Array.new(object_count) do
        br.align(4) if @format >= 14
        if @format >= 16
          ObjectEntry.new(
            path_id: wide_path_id ? br.i64s : br.i32s,
            offset: @format >= 22 ? br.i64u : br.i32u, size: br.i32u,
            class_idx: br.i32u, stripped?: @format == 16 ? br.bool : nil,
            parent_asset: self
          )
        else
          ObjectEntry.new(
            path_id: wide_path_id ? br.i64s : br.i32s, offset: br.i32u, size: br.i32u,
            type_id: br.i32, class_id: br.i16, destroyed?: br.i16 == 1, stripped?: @format == 15 ? br.bool : nil,
            parent_asset: self
          )
        end
      end

      @path_id_table = @objects.map {|e| [e.path_id, e]}.to_h

      if @format >= 11
        add_id_count = br.i32u
        @add_ids = Array.new(add_id_count) do
          br.align(4) if @format >= 14
          LocalObjectEntry.new(br.i32u, wide_path_id ? br.i64s : br.i32s)
        end
      end

      reference_count = br.i32u
      @references = Array.new(reference_count) do
        Reference.new(@format >= 6 ? br.cstr : nil, @format >= 5 ? br.read(16) : nil, @format >= 5 ? br.i32s : nil,
                      br.cstr)
      end

      @comment = br.cstr if @format >= 5
      # _ = br.i32 if @format >= 21

      @objects.each do |e|
        br.jmp(data_offset + e.offset)
        e.data = br.read(e.size)
        e.klass = if e.class_idx
                    @klasses[e.class_idx]
                  else
                    @klasses.find {|e2| e2.class_id == e.class_id} || @klasses.find {|e2| e2.class_id == e.type_id}
                  end
      end
    end

    # @param [Mikunyan::BinaryReader] br
    # @param [Mikunyan::TypeTree::Node] node
    def parse_object_private(br, node, klass = ObjectValue)
      ret = klass.new(node.name, node.type, br.endian)
      children = node.children

      if children.empty?
        pos = br.pos
        ret.value =
          case node.type
          when 'bool'
            br.bool
          when 'SInt8'
            br.i8s
          when 'UInt8'
            br.i8u
          when 'SInt16', 'short'
            br.i16s
          when 'UInt16', 'unsigned short'
            br.i16u
          when 'SInt32', 'int'
            br.i32s
          when 'UInt32', 'unsigned int', 'Type*'
            br.i32u
          when 'SInt64', 'long long'
            br.i64s
          when 'UInt64', 'unsigned long long'
            br.i64u
          when 'float'
            br.float
          when 'double'
            br.double
          else
            br.read(node.size)
          end
        br.jmp(pos + node.size) if node.size >= 0
      elsif node.array?
        children.each do |child|
          next ret[child.name] = parse_object_private(br, child) unless child.name == 'data'

          size = ret['size']&.value || raise('`size` node must appear before `data` node in array node')
          ret.value =
            if child.children.empty? && (!child.need_align? || br.pos % 4 == 0 && child.size % 4 == 0)
              if node.type == 'TypelessData'
                br.read(size * child.size)
              elsif child.type == 'char'
                # string
                br.read(size * child.size).force_encoding('utf-8')
              end
            end
          ret.value ||= Array.new(size) {parse_object_private(br, child)}
          ret['data'] = ret.value
        end
      elsif children.size == 1 && children[0].array? && children[0].type == 'Array' && children[0].name == 'Array'
        ret = parse_object_private(br, children[0])
        ret.name = node.name
        ret.type = node.type
      else
        ret.attr = children.map {|c| [c.name, parse_object_private(br, c)]}.to_h
        if node.type == 'StreamingInfo'
          ret.value = get_stream_blob(ret['path'].value, ret['offset'].value, ret['size'].value)
        else
          ret.is_struct = true
        end
      end
      br.align(4) if node.need_align?
      ret
    end

    def get_stream_blob(path, offset, size)
      return nil unless path && @bundle
      return nil if path.empty?

      path["archive:/#{@name}/"] = '' if path.start_with?("archive:/#{@name}/")
      @bundle.blobs[path]&.byteslice(offset, size)
    end
  end
end
