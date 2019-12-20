# frozen_string_literal: true

require 'mikunyan/base_object'
require 'mikunyan/decoders/image_decoder'

module Mikunyan
  module CustomTypes
    class Texture2D < Mikunyan::BaseObject
      Mikunyan::CustomTypes.set_custom_type(self, 'Texture2D')

      # Generates an png image (an instance of {ChunkyPNG::Image}) from the texture data
      def generate_png
        Mikunyan::Decoder::ImageDecoder.decode_object(self)
      end

      def width
        @attr['m_Width']&.value
      end

      def height
        @attr['m_Height']&.value
      end

      def texture_format
        @attr['m_TextureFormat']&.value
      end

      def mipmap_count
        @attr['m_MipCount']&.value
      end
    end
  end
end
