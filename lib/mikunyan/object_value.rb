module Mikunyan
    class ObjectValue
        attr_accessor :name, :type, :value, :endian, :is_struct

        def initialize(name, type, endian, value = nil)
            @name = name
            @type = type
            @endian = endian
            @value = value
            @is_struct = false
            @attr = {}
        end

        def array?
            value && value.class == Array
        end

        def value?
            value && value.class != Array
        end

        def struct?
            is_struct
        end

        def keys
            @attr.keys
        end

        def key?(key)
            @attr.key?(key)
        end

        def []
            @value
        end

        def [](name)
            if array? && name.class == Integer
                @value[name]
            else
                @attr[name]
            end
        end

        def []=(name, value)
            @attr[name] = value
        end

        def method_missing(name, *args)
            @attr[name.to_s]
        end

        def respond_to_missing?(symbol, include_private)
            @attr.key?(symbol.to_s)
        end
    end
end
