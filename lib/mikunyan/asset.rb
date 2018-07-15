module Mikunyan
    # Class for representing Unity Asset
    # @attr_reader [String] name Asset name
    # @attr_reader [Integer] format file format number
    # @attr_reader [String] generator_version version string of generator
    # @attr_reader [Integer] target_platform target platform number
    # @attr_reader [Symbol] endian data endianness (:little or :big)
    # @attr_reader [Array<Mikunyan::Asset::Klass>] klasses defined classes
    # @attr_reader [Array<Mikunyan::Asset::ObjectData>] objects included objects
    # @attr_reader [Array<Integer>] add_ids ?
    # @attr_reader [Array<Mikunyan::Asset::Reference>] references reference data
    class Asset
        attr_reader :name, :format, :generator_version, :target_platform, :endian, :klasses, :objects, :add_ids, :references, :res_s

        # Struct for representing Asset class definition
        # @attr [Integer] class_id class ID
        # @attr [Integer,nil] script_id script ID
        # @attr [String] hash hash value (16 or 32 bytes)
        # @attr [Mikunyan::TypeTree, nil] type_tree given TypeTree
        Klass = Struct.new(:class_id, :script_id, :hash, :type_tree)

        # Struct for representing Asset object information
        # @attr [Integer] path_id path ID
        # @attr [Integer] offset data offset
        # @attr [Integer] size data size
        # @attr [Integer,nil] type_id type ID
        # @attr [Integer,nil] class_id class ID
        # @attr [Integer,nil] class_idx class definition index
        # @attr [Boolean] destroyed? destroyed or not
        # @attr [String] data binary data of object
        ObjectData = Struct.new(:path_id, :offset, :size, :type_id, :class_id, :class_idx, :destroyed?, :data)

        # Struct for representing Asset reference information
        # @attr [String] path path
        # @attr [String] guid GUID (16 bytes)
        # @attr [Integer] type ?
        # @attr [String] file_path Asset name
        Reference = Struct.new(:path, :guid, :type, :file_path)

        # Load Asset from binary string
        # @param [String] bin binary data
        # @param [String] name Asset name
        # @param [String] res_s resS data
        # @return [Mikunyan::Asset] deserialized Asset object
        def self.load(bin, name, res_s = nil)
            r = Asset.new(name, res_s)
            r.send(:load, bin)
            r
        end

        # Load Asset from file
        # @param [String] file file name
        # @param [String] name Asset name (automatically generated if not specified)
        # @return [Mikunyan::Asset] deserialized Asset object
        def self.file(file, name=nil)
            name = File.basename(name, '.*') unless name
            Asset.load(File.binread(file), name)
        end

        # Returns list of all path IDs
        # @return [Array<Integer>] list of all path IDs
        def path_ids
            @objects.map{|e| e.path_id}
        end

        # Returns list of containers
        # @return [Array<Hash>,nil] list of all containers
        def containers
            obj = parse_object(1)
            return nil unless obj && obj.m_Container && obj.m_Container.array?
            obj.m_Container.value.map do |e|
                {:name => e.first.value, :preload_index => e.second.preloadIndex.value, :path_id => e.second.asset.m_PathID.value}
            end
        end

        # Parse object of given path ID
        # @param [Integer,ObjectData] path_id path ID or object
        # @return [Mikunyan::ObjectValue,nil] parsed object
        def parse_object(path_id)
            if path_id.class == Integer
                obj = @objects.find{|e| e.path_id == path_id}
                return nil unless obj
            elsif path_id.class == ObjectData
                obj = path_id
            else
                return nil
            end

            klass = (obj.class_idx ? @klasses[obj.class_idx] : @klasses.find{|e| e.class_id == obj.class_id} || @klasses.find{|e| e.class_id == obj.type_id})
            type_tree = Asset.parse_type_tree(klass)
            return nil unless type_tree

            parse_object_private(BinaryReader.new(obj.data, @endian), type_tree)
        end

        # Parse object of given path ID and simplify it
        # @param [Integer,ObjectData] path_id path ID or object
        # @return [Hash,nil] parsed object
        def parse_object_simple(path_id)
            Asset.object_simplify(parse_object(path_id))
        end

        # Returns object type name string
        # @param [Integer,ObjectData] path_id path ID or object
        # @return [String,nil] type name
        def object_type(path_id)
            if path_id.class == Integer
                obj = @objects.find{|e| e.path_id == path_id}
                return nil unless obj
            elsif path_id.class == ObjectData
                obj = path_id
            else
                return nil
            end
            klass = (obj.class_idx ? @klasses[obj.class_idx] : @klasses.find{|e| e.class_id == obj.class_id} || @klasses.find{|e| e.class_id == obj.type_id})
            if klass && klass.type_tree && klass.type_tree.nodes[0]
                klass.type_tree.nodes[0].type
            elsif klass
                Mikunyan::CLASS_ID[klass.class_id]
            else
                nil
            end
        end

        private

        def initialize(name, res_s = nil)
            @name = name
            @endian = :big
            @res_s = res_s
        end

        def load(bin)
            br = BinaryReader.new(bin)
            metadata_size = br.i32u
            size = br.i32u
            @format = br.i32u
            data_offset = br.i32u

            if @format >= 9
                @endian = :little if br.i32 == 0
                br.endian = @endian
            end

            @generator_version = br.cstr
            @target_platform = br.i32
            @klasses = []

            if @format >= 17
                has_type_trees = (br.i8 != 0)
                type_tree_count = br.i32u
                type_tree_count.times do
                    class_id = br.i32
                    br.adv(1)
                    script_id = br.i16
                    if class_id < 0 || class_id == 114
                        hash = br.read(32)
                    else
                        hash = br.read(16)
                    end
                    @klasses << Klass.new(class_id, script_id, hash, has_type_trees ? TypeTree.load(br) : TypeTree.load_default(hash))
                end
            elsif @format >= 13
                has_type_trees = (br.i8 != 0)
                type_tree_count = br.i32u
                type_tree_count.times do
                    class_id = br.i32
                    if class_id < 0
                        hash = br.read(32)
                    else
                        hash = br.read(16)
                    end
                    @klasses << Klass.new(class_id, nil, hash, has_type_trees ? TypeTree.load(br) : TypeTree.load_default(hash))
                end
            else
                @type_trees = {}
                type_tree_count = br.i32u
                type_tree_count.times do
                    class_id = br.i32
                    @klasses << Klass.new(class_id, nil, nil, @format == 10 || @format == 12 ? TypeTree.load(br) : TypeTree.load_legacy(br))
                end
            end

            long_object_ids = (@format >= 14 || (7 <= @format && @format <= 13 && br.i32 != 0))

            @objects = []
            object_count = br.i32u
            object_count.times do
                br.align(4) if @format >= 14
                path_id = long_object_ids ? br.i64 : br.i32
                offset = br.i32u
                size = br.i32u
                if @format >= 17
                    @objects << ObjectData.new(path_id, offset, size, nil, nil, br.i32u, @format <= 10 && br.i16 != 0)
                else
                    @objects << ObjectData.new(path_id, offset, size, br.i32, br.i16, nil, @format <= 10 && br.i16 != 0)
                end
                br.adv(2) if 11 <= @format && @format <= 16
                br.adv(1) if 15 <= @format && @format <= 16
            end

            if @format >= 11
                @add_ids = []
                add_id_count = br.i32u
                add_id_count.times do
                    br.align(4) if @format >= 14
                    @add_ids << [(long_object_ids ? br.i64 : br.i32), br.i32]
                end
            end

            if @format >= 6
                @references = []
                reference_count = br.i32u
                reference_count.times do
                    @references << Reference.new(br.cstr, br.read(16), br.i32, br.cstr)
                end
            end

            @objects.each do |e|
                br.jmp(data_offset + e.offset)
                e.data = br.read(e.size)
            end
        end

        def parse_object_private(br, type_tree)
            r = nil
            node = type_tree[:node]
            children = type_tree[:children]

            if node.array?
                data = nil
                size = parse_object_private(br, children.find{|e| e[:name] == 'size'}).value
                data_type_tree = children.find{|e| e[:name] == 'data'}
                if node.type == 'TypelessData'
                    data = br.read(size * data_type_tree[:node].size)
                else
                    data = size.times.map{ parse_object_private(br, data_type_tree) }
                end
                r = ObjectValue.new(node.name, node.type, br.endian, data)
            elsif node.size == -1
                r = ObjectValue.new(node.name, node.type, br.endian)
                if children.size == 1 && children[0][:name] == 'Array' && children[0][:node].type == 'Array' && children[0][:node].array?
                    if node.type == 'string'
                        size = parse_object_private(br, children[0][:children].find{|e| e[:name] == 'size'}).value
                        r.value = br.read(size * children[0][:children].find{|e| e[:name] == 'data'}[:node].size).force_encoding("utf-8")
                        br.align(4) if children[0][:node].flags & 0x4000 != 0
                    else
                        r.value = parse_object_private(br, children[0]).value
                    end
                elsif node.type == 'StreamingInfo'
                    children.each{|child| r[child[:name]] = parse_object_private(br, child)}
                    r.value = @res_s.byteslice(r['offset'].value, r['size'].value) if r['path'].value == "archive:/#{name}/#{name}.resS"
                else
                    children.each do |child|
                        r[child[:name]] = parse_object_private(br, child)
                    end
                end
            elsif children.size > 0
                pos = br.pos
                r = ObjectValue.new(node.name, node.type, br.endian)
                r.is_struct = true
                children.each do |child|
                    r[child[:name]] = parse_object_private(br, child)
                end
            else
                pos = br.pos
                value = nil
                case node.type
                when 'bool'
                    value = (br.i8 != 0)
                when 'SInt8'
                    value = br.i8s
                when 'UInt8', 'char'
                    value = br.i8u
                when 'SInt16', 'short'
                    value = br.i16s
                when 'UInt16', 'unsigned short'
                    value = br.i16u
                when 'SInt32', 'int'
                    value = br.i32s
                when 'UInt32', 'unsigned int'
                    value = br.i32u
                when 'SInt64', 'long long'
                    value = br.i64s
                when 'UInt64', 'unsigned long long'
                    value = br.i64u
                when 'float'
                    value = br.float
                when 'double'
                    value = br.double
                when 'ColorRGBA'
                    value = [br.i8u, br.i8u, br.i8u, br.i8u]
                else
                    value = br.read(node.size)
                end
                br.jmp(pos + node.size)
                r = ObjectValue.new(node.name, node.type, br.endian, value)
            end
            br.align(4) if node.flags & 0x4000 != 0
            r
        end

        def self.object_simplify(obj)
            if obj.class != ObjectValue
                obj
            elsif obj.type == 'pair'
                [object_simplify(obj['first']), object_simplify(obj['second'])]
            elsif obj.type == 'map' && obj.array?
                obj.value.map{|e| [object_simplify(e['first']), object_simplify(e['second'])] }.to_h
            elsif obj.value?
                object_simplify(obj.value)
            elsif obj.array?
                obj.value.map{|e| object_simplify(e)}
            else
                hash = {}
                obj.keys.each do |key|
                    hash[key] = object_simplify(obj[key])
                end
                hash
            end
        end

        def self.parse_type_tree(klass)
            return nil unless klass.type_tree
            nodes = klass.type_tree.nodes
            tree = {}
            stack = []
            nodes.each do |node|
                this = {:name => node.name, :node => node, :children => []}
                if node.depth == 0
                    tree = this
                else
                    stack[node.depth - 1][:children] << this
                end
                stack[node.depth] = this
            end
            tree
        end
    end
end
