# frozen_string_literal: true

require 'mikunyan/object_value'

module Mikunyan
  # Class for representing decoded base object
  class BaseObject < Mikunyan::ObjectValue
    attr_accessor :object_entry

    def path_id
      @object_entry&.path_id
    end

    def object_name
      @attr['m_Name']&.value
    end
  end

  module CustomTypes
    def self.get_custom_type(name, class_id = nil)
      class_id ||= Mikunyan::Constants::CLASS_NAME2ID[name]
      @custom_types&.[]([class_id, name]) || Mikunyan::BaseObject
    end

    def self.set_custom_type(klass, name, class_id = nil)
      class_id ||= Mikunyan::Constants::CLASS_NAME2ID[name]
      @custom_types ||= {}
      @custom_types[[class_id, name].freeze] = klass
    end
  end
end

require 'mikunyan/types/text_asset'
require 'mikunyan/types/texture2d'
