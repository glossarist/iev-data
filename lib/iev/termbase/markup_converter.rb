# frozen_string_literal: true

# (c) Copyright 2021 Ribose Inc.
#

module IEV
  module Termbase
    class MarkupConverter
      include CLI::UI

      attr_reader :dom, :source

      def initialize(string)
        @source = string
      end

      def convert
        parse_source
        generate_asciidoc
      end

      private

      def parse_source
        @dom = Oga.parse_html(source)
      end

      def generate_asciidoc(node = dom)
        case node
        when Oga::XML::NodeSet
          node.inject(String.new) do |acc, child|
            acc << generate_asciidoc(child)
          end
        when Oga::XML::Document
          generate_asciidoc(node.children)
        when Oga::XML::Element
          translate_element(node)
        when Oga::XML::Text
          node.text
        else
          warn :markup_conversion, "Unsupported node type: #{node.inspect}"
        end
      end

      def translate_element(node)
        handler = :"on_#{node.name}"

        if respond_to?(handler, true)
          send(handler, node)
        else
          debug :markup_conversion, "Unsupported HTML element: <#{node.name}>"
          generate_asciidoc(node.children)
        end
      end

      def render_inner(node)
        generate_asciidoc(node.children)
      end

      def surround_inner(node, left, right = left)
        [left, render_inner(node), right].join
      end

      def on_b(node)
        surround_inner node, "**"
      end

      def on_i(node)
        surround_inner node, "__"
      end

      def on_sub(node)
        surround_inner node, "~~"
      end

      def on_sup(node)
        surround_inner node, "^^"
      end
    end
  end
end
