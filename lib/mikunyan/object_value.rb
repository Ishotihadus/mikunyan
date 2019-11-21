# frozen_string_literal: true

module Mikunyan
  # Class for representing decoded object
  # @attr [String] name object name
  # @attr [String] type object type name
  # @attr [Object] value object
  # @attr [Symbol] endian endianness
  # @attr [Boolean] is_struct
  class ObjectValue
    attr_accessor :name, :type, :value, :endian, :is_struct

    # Constructor
    # @param [String] name object name
    # @param [String] type object type name
    # @param [Symbol] endian endianness
    # @param [Object] value object
    def initialize(name, type, endian, value = nil)
      @name = name
      @type = type
      @endian = endian
      @value = value
      @is_struct = false
      @attr = {}
    end

    # Return whether object is array or not
    # @return [Boolean]
    def array?
      value && value.class == Array
    end

    # Return whether object is value or not
    # @return [Boolean]
    def value?
      value && value.class != Array
    end

    # Return whether object is struct or not
    # @return [Boolean]
    def struct?
      is_struct
    end

    # Return all keys
    # @return [Array] list of keys
    def keys
      @attr.keys
    end

    # Return whether object contains key
    # @param [String] key
    # @return [Boolean]
    def key?(key)
      @attr.key?(key)
    end

    # Return value
    # @return [Object] value
    def []
      @value
    end

    # Return value of selected index or key
    # @param [Integer,String] i index or key
    # @return [Object] value
    def [](i)
      if array? && i.class == Integer
        @value[i]
      else
        @attr[i]
      end
    end

    # Set value of selected key
    # @param [String] name key
    # @param [Object] value value
    # @return [Object] value
    def []=(name, value)
      @attr[name] = value
    end

    # Return value of called key
    # @param [String] name key
    # @return [Object] value
    def method_missing(name, *_args)
      @attr[name.to_s]
    end

    # Implementation of respond_to_missing?
    def respond_to_missing?(symbol, _include_private)
      @attr.key?(symbol.to_s)
    end
  end
end
