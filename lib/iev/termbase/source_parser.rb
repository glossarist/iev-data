module Iev
  module Termbase
    class SourceParser
      using DataConversions

      attr_reader :src_split, :parsed_sources, :raw_str, :src_str

      def initialize(source_str)
        @raw_str = source_str.dup.freeze
        @src_str = raw_str.decode_html.sanitize.freeze
        parse
      end

      private

      def parse
        @src_split = split_source_field(src_str)
        @parsed_sources = src_split.map { |src| extract_single_source(src) }
      end
    end
  end
end
