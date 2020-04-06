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
          notes: extract_node_value,
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
          example: nil,
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
        definitions = []

        if definition
          definition = definition.to_s.gsub(/<annotation .*?>.*?<\/annotation>/,"")
          definitions = definition.split(NOTE_REGEX)
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

      def extract_node_value
        if definition_values.size > 1
          definition_values[1..-1]
        end
      end

      def extract_definition_value
        unless definition_values.empty?
          definition_values.first.gsub("<p>", "").strip
        end
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

        terms.select { |term| !term.nil? }
      end

      def nested_term
        Iev::Termbase::NestedTermBuilder
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
    end
  end
end
