require "iev/termbase/relaton_db"
require "iev/termbase/country_code"
require "iev/termbase/nested_term_builder"

module Iev
  module Termbase
    class TermBuilder
      NOTE_REGEX = /Note \d .*?: /

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

      def build_term_object
        Iev::Termbase::Term.new(
          id: find_value_for("IEVREF").gsub("-", ""),
          entry_status: find_value_for("STATUS"),
          classification: find_value_for("SYNONYM1STATUS"),
          date_accepted: find_value_for("PUBLICATIONDATE"),
          release: find_value_for("REPLACES"),
          date_amended: find_value_for("PUBLICATIONDATE"),
          review_date: find_value_for("PUBLICATIONDATE"),
          review_decision_date: find_value_for("PUBLICATIONDATE"),
          review_decision_event: "published",

          # Beautification
          #
          terms: extract_terms,
          notes: definition_values[:notes],
          examples: definition_values[:examples],
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

        if definition
          definition = definition.to_s.gsub(/<annotation .*?>.*?<\/annotation>/,"")
          definition = parse_anchor_tag(definition)

          example_block = definition.match(/Examples:(.*?)\r?$/).to_s
          definitions[:examples] = [Regexp.last_match(1)] if example_block

          note_split  = definition.split(NOTE_REGEX)
          definitions[:definition] = note_split.first
          definitions[:notes] = note_split[1..-1] if note_split.size > 1
        end

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
          term: find_value_for("SYMBOLE"),
        ))

        terms.select { |term| !term.nil? }
      end

      def nested_term
        Iev::Termbase::NestedTermBuilder
      end

      require 'mathml2asciimath'
      def extract_definition_value
        if definition_values[:definition]
          prep_string = definition_values[:definition].gsub("<p>", "").strip

          prep_string = prep_string.gsub(
              "<math>",
              '<math xmlns="http://www.w3.org/1998/Math/MathML">'
            ).gsub(/<\/?semantics>/,"")

          puts prep_string

          to_asciimath = Nokogiri::XML("<root>#{prep_string}</root>")

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
