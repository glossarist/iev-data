require "iev/termbase/term_attrs_parser"

module Iev
  module Termbase
    class NestedTermBuilder
      def initialize(options = {})
        @options = options
        @data = options.fetch(:data, nil)
        @status = options.fetch(:status, nil)
      end

      def build
        if options[:term]
          build_nested_term.select {|_k, value| !value.nil? }
        end
      end

      def self.build(options)
        new(options).build
      end

      private

      attr_reader :data, :status, :options

      def term_attributes
        @term_attributes ||= TermAttrsParser.new(data.to_s)
      end

      def build_nested_term
        {
          "type" => options[:type],
          "prefix" => term_attributes.extract_prefix,
          "normative_status" => term_status,
          "usage_info" => term_attributes.extract_usage_info,
          "designation" => options[:term],
          "part_of_speech" => term_attributes.extract_part_of_speech,
          "geographical_area" => term_attributes.extract_geographical_area,
          "international" => options.fetch(:international, nil),
        }.merge(term_attributes.extract_gender || {})
      end

      def term_status
        status.downcase if status
      end
    end
  end
end
