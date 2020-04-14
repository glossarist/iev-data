require "iev/termbase/relaton_db"
require "iev/termbase/iso_639_code"
require "iev/termbase/nested_term_builder"
require 'mathml2asciimath'

module Iev
  module Termbase
    class TermBuilder
      NOTE_REGEX_1 = /Note[\s ]*\d+[\s ]to entry:\s+|Note[\s ]*\d+?[\s ]à l['’]article:\s+|<NOTE\/?>?[\s ]*\d?[\s ]+.*?–\s+|NOTE[\s ]+-[\s ]+/i
      NOTE_REGEX_2 = /\nNOTE\s+/

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
        # puts "====== ID #{find_value_for("IEVREF").gsub("-", "")}"

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

      def replace_newlines(input)
        input.gsub('\n', "\n\n").gsub(/<[pbr]+>/, "\n\n").gsub(/\n+/, "\n\n").strip
      end

      def split_definition
        definition = find_value_for("DEFINITION")
        definitions = { notes: [], examples: [], definition: nil }

        return definitions unless definition

        definition = replace_newlines(definition)

        # Remove mathml <annotation> tag
        # puts "DDDD"*10
        # # puts definition
        # puts "DDDD"*10
        definition = parse_anchor_tag(definition)
        # #.to_s.gsub(/<annotation.*?>.*?<\/annotation>/,"").gsub(/<\/?semantics>/,"")
        # puts definition
        # puts "EEEE"*10

        example_block = definition.match(/[\r\n](EXAMPLE|EXEMPLE) (.*?)\r?$/).to_s

        if example_block && !example_block.strip.empty?
          # We only take the latter captured part
          definitions[:examples] = [Regexp.last_match(2).strip]
          definition = definition.gsub("#{Regexp.last_match(1)} #{Regexp.last_match(2)}", "")
        end

        note_split  = definition.split(NOTE_REGEX_1).map do |note|
          note.split(NOTE_REGEX_2)
        end.flatten

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
        Iev::Termbase::Iso639Code.three_char_code(code).first
      end

      def extract_terms
        terms = []

        terms.push(nested_term.build(
          type: "expression",
          term: mathml_to_asciimath(term_value_text),
          data: find_value_for("TERMATTRIBUTE"),
          status: 'Preferred',
        ))

        (1..3).each do |num|
          # Some synonyms have more than one entry
          values = find_value_for("SYNONYM#{num}")
          next if values.nil?

          # puts "X"*50
          # puts values
          values = values.split(/<[pbr]+>/)
          # puts values.inspect
          # puts "Y"*50

          values.each do |value|
            terms.push(nested_term.build(
              type: "expression",
              term: mathml_to_asciimath(value),
              data: find_value_for("SYNONYM#{num}ATTRIBUTE"),
              status: find_value_for("SYNONYM1STATUS"),
            ))
          end
        end

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

      def html_to_asciimath(input)
        return input if input.nil? || input.empty?

        to_asciimath = Nokogiri::HTML.fragment(input, "UTF-8")

        to_asciimath.css('i').each do |math_element|
          # puts "HTML MATH!!  #{math_element.to_xml}"
          # puts "HTML MATH!!  #{math_element.text}"
          case math_element.text.length
          when 1..8
            # puts "(#{math_element.text} to => #{HTMLEntities.new.decode(math_element.text)})"
            math_element.replace "$$#{HTMLEntities.new.decode(math_element.text)}$$"
          when 0
            math_element.remove
          end
        end

        to_asciimath.children.to_s
      end

      def mathml_to_asciimath(input)
        return input if input.nil? || input.empty?

        unless input.match?(/<math>/)
          return html_to_asciimath(input)
        end

        # puts "GOING TO MATHML MATH"
        # puts input
        input = html_to_asciimath(input)
        to_asciimath = Nokogiri::HTML.fragment(input, "UTF-8")
        # to_asciimath.remove_namespaces!

        to_asciimath.css('math').each do |math_element|
          asciimath = MathML2AsciiMath.m2a(math_element.to_xml).strip
          # puts "ASCIIMATH!!  #{asciimath}"

          if asciimath.empty?
            math_element.remove
          else
            math_element.replace "$$#{asciimath}$$"
          end
        end

        to_asciimath.children.to_s
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
            # source = "ISO/IEC GUIDE 99:2007 1.26"
            raw_ref = source.match(/\A[^,\()]+/).to_s

            clean_ref = raw_ref.
              sub(";", ":").
              sub(/\u2011/, "-").
              sub(/IEC\sIEEE/, "IEC/IEEE").
              sub(/\d\.[\d\.]+/, "").
              strip

            clause = source.
              gsub(clean_ref, "").
              gsub(/\A,?\s+/,"").
              strip

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
          part_number = find_value_for("IEVREF").slice(0,3)

          # Convert IEV term references
          # Convert href links
          text.
            gsub(/<a href=(IEV)\s*(.*?)>(.*?)<\/a>/, '{{\3, \1:\2}}').
            gsub(/<a href="(.*?)">(.*?)<\/a>/, '\1[\2]').
            gsub(/<simg .*\/\$file\/([\d\-\w\.]+)>\s*Figure\s+(\d)\s+[–-]\s+(.+?)\s*<\/b>\s+Figure\s+(\d)\s+[–-]\s(.+)\s*<\/b>/, "image::assets/images/parts/#{part_number}/\\1[Figure \\2 - \\3; \\5]").
            gsub(/<simg .*\/\$file\/([\d\-\w\.]+)>\s*Figure\s+(\d)\s+[–-]\s+(.+?)\s*<\/b>/, "image::assets/images/parts/#{part_number}/\\1[Figure \\2 - \\3]")
        end
      end
    end
  end
end
