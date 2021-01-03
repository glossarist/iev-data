require "iev/termbase/term_attrs_parser"

module Iev
  module Termbase
    class NestedTermBuilder
      def initialize(options = {})
        @options = options
        @data = options.fetch(:data, nil)
      end

      def build
        if options[:term]
          build_nested_term.compact
        end
      end

      def self.build(options)
        new(options).build
      end

      private

      attr_reader :data, :options

      def term_attributes
        @term_attributes ||= TermAttrsParser.new(data.to_s)
      end

      def build_nested_term
        {
          "type" => options[:type],
          "prefix" => term_attributes.prefix,
          "normative_status" => options.fetch(:status, nil)&.downcase,
          "usage_info" => term_attributes.usage_info,
          "designation" => options[:term],
          "part_of_speech" => term_attributes.part_of_speech,
          "geographical_area" => term_attributes.geographical_area,
          "international" => options.fetch(:international, nil),
          "gender" => term_attributes.gender,
          "plurality" => term_attributes.plurality,
        }
      end
    end
  end
end
