# frozen_string_literal: true

# (c) Copyright 2021 Ribose Inc.
#

# require "reverse_adoc_config"

module IEV
  module Termbase
    class MarkupConverter
      include CLI::UI

      attr_reader :source

      def initialize(string)
        @source = string
      end

      def convert
        return nil if source.nil?

        str = source
        str = process_html_math(str)
        str = html_to_asciidoc(str)
        str = str.strip
        str
      end

      private

      # @todo
      def process_html_math(str)
        str
      end

      def html_to_asciidoc(str)
        ReverseAdoc.convert(str)
      end

      module ReverseAdocConverters
        class A < ReverseAdoc::Converters::A
          def convert(node, state = {})
            if node["href"]&.start_with?("IEV")
              link_caption = treat_children(node, state)
              ievref = node["href"][/\d{3}-\d{2,3}-\d{2,3}\w?\Z/]
              " {{%s, IEV:%s}}" % [link_caption, ievref]
            else
              super
            end
          end
        end

        ReverseAdoc::Converters.register :a, A.new
      end
    end
  end
end

ReverseAdoc.config do |config|
  config.unknown_tags = :bypass
  config.mathml2asciimath = true
end
