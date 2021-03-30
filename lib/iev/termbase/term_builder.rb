# frozen_string_literal: true

# (c) Copyright 2020 Ribose Inc.
#

require "pp"

module IEV
  module Termbase
    class TermBuilder
      include CLI::UI
      using DataConversions

      def initialize(data)
        @data = data
      end

      def build
        build_term_object
      end

      def self.build_from(data)
        new(data).build
      end

      attr_reader :data

      def find_value_for(key)
        data.fetch(key.to_sym, nil)&.sanitize
      end

      def flesh_date(incomplete_date)
        return incomplete_date if incomplete_date.nil? || incomplete_date.empty?

        # FIXME: this is a terrible assumption but the IEV export only provides
        # year and month
        year, month = incomplete_date.split("-")
        DateTime.parse("#{year}-#{month}-01").to_s
      end

      def build_term_object
        set_ui_tag "#{term_id} (#{term_language})"
        progress "Processing term #{term_id} (#{term_language})..."

        split_definition

        IEV::Termbase::Term.new(
          id: term_id,
          entry_status: extract_entry_status,
          classification: find_value_for("SYNONYM1STATUS"),
          date_accepted: flesh_date(find_value_for("PUBLICATIONDATE")),
          date_amended: flesh_date(find_value_for("PUBLICATIONDATE")),
          review_date: flesh_date(find_value_for("PUBLICATIONDATE")),
          review_decision_date: flesh_date(find_value_for("PUBLICATIONDATE")),
          review_decision_event: "published",

          # Beautification
          #
          terms: extract_terms,
          notes: extract_notes,
          examples: extract_examples,
          definition: extract_definition_value,
          authoritative_source: extract_authoritative_source,
          language_code: term_language,
          superseded_concepts: extract_superseded_concepts,

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

      def term_id
        @term_id ||= find_value_for("IEVREF")
      end

      def term_domain
        @term_domain ||= term_id.slice(0, 3)
      end

      def term_language
        @term_language ||= find_value_for("LANGUAGE").to_three_char_code
      end

      def replace_newlines(input)
        input.gsub('\n', "\n\n").gsub(/<[pbr]+>/, "\n\n").gsub(/\s*\n[\n\s]+/, "\n\n").strip
      end

      # Splits unified definition (from the spreadsheet) into separate
      # definition, examples, and notes strings (for YAMLs).
      #
      # Sets +@definition+, +@examples+ and +@notes+ variables.
      def split_definition
        slicer_rx = %r{
          \s*
          (?:<p>\s*)?
          (
            (?<example>
              \bEXAMPLE\b |
              \bEXEMPLE\b
            )
            |
            (?<note>
              Note\s*\d+\sto\sentry: |
              Note\s*\d+?\sà\sl['’]article: |
              <NOTE\/?>?\s*\d?\s+.*?– |
              NOTE(?:\s+-)?
            )
          )
          \s*
        }x

        @examples = []
        @notes = []
        definition_arr = [] # here array for consistent interface

        next_part_arr = definition_arr
        remaining_str = find_value_for("DEFINITION")

        while md = remaining_str&.match(slicer_rx)
          next_part_arr.push(md.pre_match)
          next_part_arr = md[:example] ? @examples : @notes
          remaining_str = md.post_match
        end

        next_part_arr.push(remaining_str)
        @definition = definition_arr.first
        @definition = nil if @definition&.empty?
      end

      def extract_terms
        [
          extract_primary_designation,
          *extract_synonymous_designations,
          extract_international_symbol_designation,
        ].compact
      end

      def extract_primary_designation
        raw_term = find_value_for("TERM")
        raw_term = "NA" if raw_term == "....."

        term = MarkupConverter.new(raw_term).convert

        IEV::Termbase::NestedTermBuilder.build(
          type: "expression",
          term: term,
          data: find_value_for("TERMATTRIBUTE"),
          status: "Preferred",
        )
      end

      def extract_synonymous_designations
        retval = (1..3).map do |num|
          designations = find_value_for("SYNONYM#{num}") || ""

          # Some synonyms have more than one entry
          designations.split(/<[pbr]+>/).map do |raw_term|
            term = MarkupConverter.new(raw_term).convert

            IEV::Termbase::NestedTermBuilder.build(
              type: "expression",
              term: term,
              data: find_value_for("SYNONYM#{num}ATTRIBUTE"),
              status: find_value_for("SYNONYM#{num}STATUS"),
            )
          end
        end

        retval.flatten.compact
      end

      def extract_international_symbol_designation
        term = MarkupConverter.new(find_value_for("SYMBOLE")).convert

        IEV::Termbase::NestedTermBuilder.build(
          type: "symbol",
          international: true,
          term: term,
        )
      end

      def extract_definition_value
        MarkupConverter.new(@definition).convert if @definition
      end

      def extract_examples
        @examples.map do |str|
          MarkupConverter.new(str).convert
        end
      end

      def extract_notes
        @notes.map do |str|
          MarkupConverter.new(str).convert
        end
      end

      def extract_entry_status
        case find_value_for("STATUS").downcase
        when "standard" then "valid"
        else nil
        end
      end

      def extract_authoritative_source
        source_val = find_value_for("SOURCE")
        return nil if source_val.nil?
        SourceParser.new(source_val).parsed_sources
      end

      def extract_superseded_concepts
        replaces_val = find_value_for("REPLACES")
        return nil if replaces_val.nil?
        SupersessionParser.new(replaces_val).supersessions
      end
    end
  end
end
