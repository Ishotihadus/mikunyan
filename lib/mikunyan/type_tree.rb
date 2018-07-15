module Mikunyan
    # Class for representing TypeTree
    # @attr [Array<Mikunyan::TypeTree::Node>] nodes list of all nodes
    class TypeTree
        attr_accessor :nodes

        # Struct for representing Node in TypeTree
        # @attr [String] version version string
        # @attr [Integer] depth depth of node (>= 0)
        # @attr [Boolean] array? array node or not
        # @attr [String] type type name
        # @attr [String] name node (attribute) name
        # @attr [Integer] index index in node list
        # @attr [Integer] flags flags of node
        Node = Struct.new(:version, :depth, :array?, :type, :name, :size, :index, :flags)

        # Create TypeTree from binary string (new version)
        # @param [Mikunyan::BinaryReader] br
        # @return [Mikunyan::TypeTree] created TypeTree
        def self.load(br)
            nodes = []
            node_count = br.i32u
            buffer_size = br.i32u
            node_count.times do
                node = Node.new(br.i16u, br.i8u, br.i8u != 0, br.i32, br.i32, br.i32, br.i32u, br.i32u)
                nodes << node
            end
            buffer = br.read(buffer_size)
            nodes.each do |n|
                if n.type >= 0
                    n.type = buffer.unpack("@#{n.type}Z*")[0]
                else
                    n.type = Mikunyan::STRING_TABLE[n.type + 2**31]
                end
                if n.name >= 0
                    n.name = buffer.unpack("@#{n.name}Z*")[0]
                else
                    n.name = Mikunyan::STRING_TABLE[n.name + 2**31]
                end
            end
            r = TypeTree.new
            r.nodes = nodes
            r
        end

        # Create TypeTree from binary string (legacy version)
        # @param [Mikunyan::BinaryReader] br
        # @return [Mikunyan::TypeTree] created TypeTree
        def self.load_legacy(br)
            nodes = []
            stack = [0]
            while stack.size > 0
                depth = stack.pop
                type = br.cstr
                name = br.cstr
                size = br.i32
                index = br.i32u
                is_array = (br.i32 != 0)
                version = br.i32u
                flags = br.i32u
                child_count = br.i32u
                child_count.times{ stack << depth + 1 }
                nodes << Node.new(version, depth, is_array, type, name, size, index, flags)
            end
            r = TypeTree.new
            r.nodes = nodes
            r
        end

        # Create default TypeTree from hash string (if exists)
        # @param [String] hash
        # @return [Mikunyan::TypeTree,nil] created TypeTree
        def self.load_default(hash)
            hash_str = hash.unpack('H*')[0]
            file = File.expand_path("../typetrees/#{hash_str}.dat", __FILE__)
            return nil unless File.file?(file)
            r = TypeTree.new
            r.nodes = Marshal.load(File.binread(file))
            r
        end
    end
end
