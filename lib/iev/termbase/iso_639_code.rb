require 'yaml'

module Iev
  module Termbase
    class Iso639Code
      COUNTRY_CODES = YAML.load(IO.read(File.join(__dir__, "iso_639_2.yaml")))

      def initialize(two_char_code)
        @code = two_char_code
      end

      def find(code_type)
        country_codes.detect do |key, value|
          key if value["iso_639_1"] == @code.to_s && value[code_type]
        end
      end

      def self.three_char_code(two_char_code, code_type="terminology")
        new(two_char_code).find(code_type)
      end

      private

      def country_codes
        COUNTRY_CODES
      end

    end
  end
end

