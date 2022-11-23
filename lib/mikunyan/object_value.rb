# frozen_string_literal: true

module Mikunyan
  # Class for representing decoded object
  # @attr [String] name object name
  # @attr [String] type object type name
  # @attr [Hash<String,Mikunyan::ObjectValue>] attr
  # @attr [Object] value object
  # @attr [Symbol] endian endianness
  # @attr [Boolean] is_struct
  class ObjectValue
    attr_accessor :name, :type, :attr, :value, :endian, :is_struct

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
      value&.is_a?(Array)
    end

    # Return whether object is value or not
    # @return [Boolean]
    def value?
      value && !value.is_a?(Array)
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

    # Return value of selected index or key
    # @param [Integer,String] key index or key
    # @return [Object] value
    def [](key = nil)
      if key.nil?
        @value
      elsif array? && key.is_a?(Integer)
        @value[key]
      else
        @attr[key]
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
    def method_missing(name, *args)
      n = name.to_s
      @attr.key?(n) ? @attr[n] : super
    end

    # Implementation of respond_to_missing?
    def respond_to_missing?(symbol, _include_private)
      @attr.key?(symbol.to_s)
    end

    # Simplifies self, or serializes self with ruby primitive types
    def simplify
      if @type == 'pair'
        [@attr['first'].simplify, @attr['second'].simplify]
      elsif @type == 'map' && @value.is_a?(Array)
        @value.map {|e| [e['first'].simplify, e['second'].simplify]}.to_h
      elsif is_struct
        @attr.transform_values(&:simplify)
      elsif @value.is_a?(Array)
        @value.map {|e| e.is_a?(ObjectValue) ? e.simplify : e}
      elsif @value.is_a?(ObjectValue)
        @value.simplify
      else
        @value
      end
    end
  end
end
