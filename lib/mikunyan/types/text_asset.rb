# frozen_string_literal: true

require 'mikunyan/base_object'

module Mikunyan
  module CustomTypes
    class TextAsset < Mikunyan::BaseObject
      Mikunyan::CustomTypes.set_custom_type(self, 'TextAsset')

      def text
        @attr['m_Script']&.value
      end

      def bytes
        @attr['m_Script']&.value.dup.force_encoding('ASCII-8BIT')
      end
    end
  end
end
