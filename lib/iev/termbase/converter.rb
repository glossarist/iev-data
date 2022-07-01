# frozen_string_literal: true

module IEV
  module Termbase
    module Converter
      def self.mathml_to_asciimath(input)
        IEV::Termbase::Converter::MathmlToAsciimath.convert(input)
      end
    end
  end
end
