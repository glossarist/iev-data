require "iev/termbase/relaton_db"
require "iev/termbase/country_code"
require "iev/termbase/nested_term_builder"
require 'mathml2asciimath'

module Iev
  module Termbase
    class TermBuilder
      NOTE_REGEX = /Note ?\d? .*?: |<NOTE ?\d? .*?– /i

      def initialize(data:, indices: )
        @data = data
        @indices = indices
      end

      def build
        build_term_object
      end

      def self.build_from(data, indices)
        new(data: data, indices: indices).build
      end

      private

      attr_reader :data, :indices

      def find_value_for(key)
        data.fetch(indices[key], nil)
      end

      def flesh_date(incomplete_date)
        return incomplete_date if incomplete_date.nil? || incomplete_date.empty?

        # FIXME: this is a terrible assumption but the IEV export only provides
        # year and month
        year, month = incomplete_date.split('-')
        DateTime.parse("#{year}-#{month}-01").to_s
      end

      def build_term_object
        Iev::Termbase::Term.new(
          id: find_value_for("IEVREF").gsub("-", ""),
          entry_status: find_value_for("STATUS"),
          classification: find_value_for("SYNONYM1STATUS"),
          date_accepted: flesh_date(find_value_for("PUBLICATIONDATE")),
          release: find_value_for("REPLACES"),
          date_amended: flesh_date(find_value_for("PUBLICATIONDATE")),
          review_date: flesh_date(find_value_for("PUBLICATIONDATE")),
          review_decision_date: flesh_date(find_value_for("PUBLICATIONDATE")),
          review_decision_event: "published",

          # Beautification
          #
          terms: extract_terms,
          notes: definition_values[:notes].map do |note|
            mathml_to_asciimath(note)
          end,
          examples: definition_values[:examples].map do |example|
            mathml_to_asciimath(example)
          end,
          definition: extract_definition_value,
          authoritative_source: extract_authoritative_source,
          language_code: three_char_code(find_value_for("LANGUAGE")),

          # @todo: Unsorted Attributes
          #
          # We need to revisit this attributes and also update
          # the correct mapping with the existing attributes.
          #
          abbrev: nil,
          alt: nil,
          country_code: nil,
          review_indicator: nil,
          authoritative_source_similarity: nil,
          lineage_source: nil,
          review_status: nil,
          review_type: nil,
          review_decision_notes: nil,
        )
      end

      def term_value_text
        term = find_value_for("TERM")
        term == "....." ? "NA" : term
      end

      def definition_values
        @definition_values ||= split_definition
      end

      def split_definition
        definition = find_value_for("DEFINITION")
        definitions = { notes: [], examples: [], definition: nil }

        return definitions unless definition

        definition = definition.gsub("<p>", "\n\n").strip

        # Remove mathml <annotation> tag
        definition = definition.to_s.gsub(/<annotation .*?>.*?<\/annotation>/,"")
        definition = parse_anchor_tag(definition)

        example_block = definition.match(/(EXAMPLE|EXEMPLE) (.*?)\r?$/).to_s

        if example_block && !example_block.strip.empty?
          # We only take the latter captured part
          definitions[:examples] = [Regexp.last_match(2).strip]
        end

        note_split  = definition.split(NOTE_REGEX)
        definitions[:definition] = note_split.first
        definitions[:notes] = note_split[1..-1].map(&:strip) if note_split.size > 1

        definitions
      end

      def find_synonyms
        synonyms = []
        synonyms.push(find_value_for("SYNONYM1"))
        synonyms.push(find_value_for("SYNONYM2"))
        synonyms.push(find_value_for("SYNONYM3"))

        synonyms.select {|item| !item.nil? }
      end

      def three_char_code(code)
        Iev::Termbase::CountryCode.three_char_code(code)
      end

      def extract_terms
        terms = []

        terms.push(nested_term.build(
          type: "expression",
          term: term_value_text,
          data: find_value_for("TERMATTRIBUTE"),
          status: find_value_for("SYNONYM1STATUS"),
        ))

        terms.push(nested_term.build(
          type: "expression",
          term: find_value_for("SYNONYM1"),
          data: find_value_for("SYNONYM1ATTRIBUTE"),
          status: find_value_for("SYNONYM1STATUS"),
        ))

        terms.push(nested_term.build(
          type: "expression",
          term: find_value_for("SYNONYM2"),
          data: find_value_for("SYNONYM2ATTRIBUTE"),
          status: find_value_for("SYNONYM2STATUS"),
        ))


        terms.push(nested_term.build(
          type: "expression",
          term: find_value_for("SYNONYM3"),
          data: find_value_for("SYNONYM3ATTRIBUTE"),
          status: find_value_for("SYNONYM3STATUS"),
        ))

        terms.push(nested_term.build(
          type: "symbol",
          international: true,
          term: mathml_to_asciimath(find_value_for("SYMBOLE")),
        ))

        terms.select { |term| !term.nil? }
      end

      def nested_term
        Iev::Termbase::NestedTermBuilder
      end

      def mathml_to_asciimath(input)
        return input if input.nil? || input.empty?

        text = input.gsub(
            "<math>",
            '<math xmlns="http://www.w3.org/1998/Math/MathML">'
          ).gsub(/<\/?semantics>/,"")

        puts text

        to_asciimath = Nokogiri::XML("<root>#{text}</root>")

        maths = to_asciimath.xpath('//mathml:math', 'mathml' => "http://www.w3.org/1998/Math/MathML")

        maths.each do |math_element|
          asciimath = MathML2AsciiMath.m2a(math_element.to_xml)
          asciimath.gsub!("\n", " ")
          puts "ASCIIMATH!!  #{asciimath}"
          math_element.replace "$$#{asciimath}$$"
        end

        foo = to_asciimath.root.text
        puts "RESULTS ==> #{foo}"

        foo
      end

      def extract_definition_value
        if definition_values[:definition]
          mathml_to_asciimath(definition_values[:definition].strip)
        end
      end

      def extract_authoritative_source
        source = find_value_for("SOURCE")

        if source
          begin
            raw_ref = source.match(/\A[^,\()]+/).to_s
            clean_ref = raw_ref.
              sub(";", ":").
              sub(/\u2011/, "-").
              sub(/IEC\sIEEE/, "IEC/IEEE")

            clause = source.
              gsub(raw_ref, "").
              gsub(/\A,?\s+/,"")

            item = RelatonDb.instance.fetch(clean_ref)

            src = {}
            src["ref"] = clean_ref
            src["clause"] = clause unless clause.empty?
            src["link"] = item.url if item
            src
          rescue RelatonBib::RequestError => e
            warn e.message
            src
          end
        else
          source
        end
      end

      def parse_anchor_tag(text)
        if text
          text.gsub(/<a href=([A-Z]+)\s*(.*?)>(.*?)<\/a>/, '{{\3, \1:\2}}')
        end
      end
    end
  end
end
