# frozen_string_literal: true

require 'json'
require 'mikunyan/binary_reader'

module Mikunyan
  # Class for representing TypeTree
  # @attr [Array<Mikunyan::TypeTree::Node>] nodes list of all nodes
  class TypeTree
    attr_accessor :nodes

    # Struct for representing Node in TypeTree
    # @attr [String] version version string
    # @attr [Integer] level level of node (>= 0)
    # @attr [Boolean] array? array node or not
    # @attr [String] type type name
    # @attr [String] name node (attribute) name
    # @attr [Integer] index index in node list
    # @attr [Integer] flags flags of node
    # @attr [Integer,nil] v18meta
    # @attr [Mikunyan::TypeTree::Node,nil] parent ̑
    # @attr [Array<Mikunyan::TypeTree::Node>] children
    Node = Struct.new(:version, :level, :array?, :type, :name, :size, :index, :flags, :v18meta, :parent, :children,
                      keyword_init: true) do
      def need_align?
        flags & 0x4000 != 0
      end
    end

    # Returns the root node of the typetree
    # @return [Mikunyan::TypeTree::Node,nil]
    def tree
      nodes&.[](0)
    end

    # Generates JSON-compatible serialized representation of typetree information
    def serialize
      {
        'nodes' =>
          nodes.map do |e|
            {
              'version' => e.version,
              'level' => e.level,
              'is_array' => e.array?,
              'type' => e.type,
              'name' => e.name,
              'size' => e.size,
              'flags' => e.flags,
              'v18meta' => e.v18meta
            }
          end
      }
    end

    # Creates TypeTree from binary string
    # @param [Mikunyan::BinaryReader] br
    # @param [Integer] version asset format version
    # @return [Mikunyan::TypeTree] created TypeTree
    def self.load(br, version)
      if version == 10 || version >= 12
        node_count = br.i32u
        buffer_size = br.i32u
        nodes = Array.new(node_count) do
          Node.new(
            version: br.i16u,
            level: br.i8u,
            array?: br.bool,
            type: br.i32u,
            name: br.i32u,
            size: br.i32s,
            index: br.i32u,
            flags: br.i32u,
            v18meta: version >= 18 ? br.i64u : nil,
            children: []
          )
        end
        buffer = br.read(buffer_size)
        stack = []
        nodes.each do |n|
          n.type = Mikunyan::Constants.get_string_or_default(n.type, buffer)
          n.name = Mikunyan::Constants.get_string_or_default(n.name, buffer)
          if n.level > 0
            n.parent = stack[n.level - 1]
            n.parent.children << n
          end
          stack[n.level] = n
        end
        br.adv(4) if version >= 21
      else
        nodes = []
        stack = []
        until stack.empty? && !nodes.empty?
          parent = stack.pop
          node = Node.new(
            type: br.cstr,
            name: br.cstr,
            size: br.i32s,
            index: br.i32u,
            array?: br.i32 != 0,
            version: br.i32u,
            flags: br.i32u,
            level: parent ? parent.level + 1 : 0,
            parent: parent,
            children: []
          )
          nodes << node
          parent.children << node if parent
          stack += Array.new(br.i32u, node)
        end
      end
      ret = TypeTree.new
      ret.nodes = nodes
      ret
    end

    # Create default TypeTree from hash string (if exists)
    # @param [Integer] class_id
    # @param [String] hash
    # @return [Mikunyan::TypeTree,nil] created TypeTree
    def self.load_default(class_id, hash)
      file = File.expand_path("../typetrees/#{class_id}/#{hash.unpack1('H*')}.json", __FILE__)
      return nil unless File.file?(file)

      TypeTree.deserialize(JSON.parse(File.read(file)))
    end

    # Creates TypeTree from serialized object
    # @param [Hash] obj
    def self.deserialize(obj)
      stack = []
      ret = TypeTree.new
      ret.nodes = obj['nodes'].map.with_index do |e, index|
        level = e['level'] || e['depth']
        parent = level > 0 ? stack[level - 1] : nil
        n = Node.new(
          version: e['version'],
          level: level,
          array?: e['is_array'],
          type: e['type'],
          name: e['name'],
          size: e['size'],
          index: index,
          flags: e['flags'],
          v18meta: e['v18meta'],
          parent: parent,
          children: []
        )
        parent.children << n if parent
        stack[level] = n
      end
      ret
    end
  end
end
