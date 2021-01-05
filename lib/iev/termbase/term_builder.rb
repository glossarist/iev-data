require 'pp'

require "iev/termbase/relaton_db"
require "iev/termbase/iso_639_code"
require "iev/termbase/nested_term_builder"
require 'mathml2asciimath'
require 'relaton_bib'

module Iev
  module Termbase
    class TermBuilder
      NOTE_REGEX_1 = /Note[\s ]*\d+[\s ]to entry:\s+|Note[\s ]*\d+?[\s ]à l['’]article:[\s ]*|<NOTE\/?>?[\s ]*\d?[\s ]+.*?–\s+|NOTE[\s ]+-[\s ]+/i
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

      attr_reader :data, :indices

      def find_value_for(key)
        clean_string(data.fetch(indices[key], nil))
      end

      def flesh_date(incomplete_date)
        return incomplete_date if incomplete_date.nil? || incomplete_date.empty?

        # FIXME: this is a terrible assumption but the IEV export only provides
        # year and month
        year, month = incomplete_date.split('-')
        DateTime.parse("#{year}-#{month}-01").to_s
      end

      # Some IEV fields have the string `\uFEFF` polluting them
      def clean_string(val)
        return unless val

        # u2011: issue iev-data#51
        # u00a0: issue iev-data#50
        val.unicode_normalize
          .gsub("\uFEFF", "")
          .gsub("\u2011", "-")
          .gsub("\u00a0", " ")
          .strip
      end

      def build_term_object
        row_term_id = find_value_for("IEVREF")
        row_lang = three_char_code(find_value_for("LANGUAGE"))

        print "\rProcessing term #{row_term_id} (#{row_lang})... "

        Iev::Termbase::Term.new(
          id: row_term_id,
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
          language_code: row_lang,

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
        input.gsub('\n', "\n\n").gsub(/<[pbr]+>/, "\n\n").gsub(/\s*\n[\n\s]+/, "\n\n").strip
      end

      def split_definition
        definition = parse_anchor_tag(find_value_for("DEFINITION"))
        definitions = { notes: [], examples: [], definition: nil }

        return definitions unless definition

        definition = replace_newlines(definition)

        # Remove mathml <annotation> tag
        # puts "DDDD"*10
        # # puts definition
        # puts "DDDD"*10
        # definition = parse_anchor_tag(definition)
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
          term: mathml_to_asciimath(parse_anchor_tag(term_value_text)),
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
              term: mathml_to_asciimath(parse_anchor_tag(value)),
              data: find_value_for("SYNONYM#{num}ATTRIBUTE"),
              status: find_value_for("SYNONYM#{num}STATUS"),
            ))
          end
        end

        terms.push(nested_term.build(
          type: "symbol",
          international: true,
          term: mathml_to_asciimath(parse_anchor_tag(find_value_for("SYMBOLE"))),
        ))

        terms.select { |term| !term.nil? }
      end

      def nested_term
        Iev::Termbase::NestedTermBuilder
      end

      def text_to_asciimath(text)
        html_entities_to_asciimath(HTMLEntities.new(:expanded).decode(text))
      end

      def html_to_asciimath(input)
        return input if input.nil? || input.empty?

        to_asciimath = Nokogiri::HTML.fragment(input, "UTF-8")

        to_asciimath.css('i').each do |math_element|
          # puts "HTML MATH!!  #{math_element.to_xml}"
          # puts "HTML MATH!!  #{math_element.text}"
          decoded = text_to_asciimath(math_element.text)
          case decoded.length
          when 1..12
            # puts "(#{math_element.text} to => #{decoded})"
            math_element.replace "stem:[#{decoded}]"
          when 0
            math_element.remove
          else
            math_element.replace "_#{decoded}_"
          end
        end

        to_asciimath.css('sub').each do |math_element|
          case math_element.text.length
          when 0
            math_element.remove
          else
            math_element.replace "~#{text_to_asciimath(math_element.text)}~"
          end
        end

        to_asciimath.css('sup').each do |math_element|
          case math_element.text.length
          when 0
            math_element.remove
          else
            math_element.replace "^#{text_to_asciimath(math_element.text)}^"
          end
        end

        to_asciimath.css('ol').each do |element|
          element.css('li').each do |li|
            li.replace ". #{li.text}"
          end
        end

        to_asciimath.css('ul').each do |element|
          element.css('li').each do |li|
            li.replace "* #{li.text}"
          end
        end

        # Replace sans-serif font with monospace
        to_asciimath.css('font[style*="sans-serif"]').each do |x|
          x.replace "`#{x.text}`"
        end

        html_entities_to_stem(
          to_asciimath.children.to_s.gsub(/\]stem:\[/, '').gsub(/<\/?[uo]l>/, '')
        )
      end

      def html_entities_to_asciimath(x)
        x.gsub("&alpha;", "alpha").
          gsub("&beta;", "beta").
          gsub("&gamma;", "gamma").
          gsub("&Gamma;", "Gamma").
          gsub("&delta;", "delta").
          gsub("&Delta;", "Delta").
          gsub("&epsilon;", "epsilon").
          gsub("&varepsilon;", "varepsilon").
          gsub("&zeta;", "zeta").
          gsub("&eta;", "eta").
          gsub("&theta;", "theta").
          gsub("&Theta;", "Theta").
          gsub("&vartheta;", "vartheta").
          gsub("&iota;", "iota").
          gsub("&kappa;", "kappa").
          gsub("&lambda;", "lambda").
          gsub("&Lambda;", "Lambda").
          gsub("&mu;", "mu").
          gsub("&nu;", "nu").
          gsub("&xi;", "xi").
          gsub("&Xi;", "Xi").
          gsub("&pi;", "pi").
          gsub("&Pi;", "Pi").
          gsub("&rho;", "rho").
          gsub("&beta;", "beta").
          gsub("&sigma;", "sigma").
          gsub("&Sigma;", "Sigma").
          gsub("&tau;", "tau").
          gsub("&upsilon;", "upsilon").
          gsub("&phi;", "phi").
          gsub("&Phi;", "Phi").
          gsub("&varphi;", "varphi").
          gsub("&chi;", "chi").
          gsub("&psi;", "psi").
          gsub("&Psi;", "Psi").
          gsub("&omega;", "omega")
      end

      def html_entities_to_stem(x)
        x.gsub("&alpha;", "stem:[alpha]").
          gsub("&beta;", "stem:[beta]").
          gsub("&gamma;", "stem:[gamma]").
          gsub("&Gamma;", "stem:[Gamma]").
          gsub("&delta;", "stem:[delta]").
          gsub("&Delta;", "stem:[Delta]").
          gsub("&epsilon;", "stem:[epsilon]").
          gsub("&varepsilon;", "stem:[varepsilon]").
          gsub("&zeta;", "stem:[zeta]").
          gsub("&eta;", "stem:[eta]").
          gsub("&theta;", "stem:[theta]").
          gsub("&Theta;", "stem:[Theta]").
          gsub("&vartheta;", "stem:[vartheta]").
          gsub("&iota;", "stem:[iota]").
          gsub("&kappa;", "stem:[kappa]").
          gsub("&lambda;", "stem:[lambda]").
          gsub("&Lambda;", "stem:[Lambda]").
          gsub("&mu;", "stem:[mu]").
          gsub("&nu;", "stem:[nu]").
          gsub("&xi;", "stem:[xi]").
          gsub("&Xi;", "stem:[Xi]").
          gsub("&pi;", "stem:[pi]").
          gsub("&Pi;", "stem:[Pi]").
          gsub("&rho;", "stem:[rho]").
          gsub("&beta;", "stem:[beta]").
          gsub("&sigma;", "stem:[sigma]").
          gsub("&Sigma;", "stem:[Sigma]").
          gsub("&tau;", "stem:[tau]").
          gsub("&upsilon;", "stem:[upsilon]").
          gsub("&phi;", "stem:[phi]").
          gsub("&Phi;", "stem:[Phi]").
          gsub("&varphi;", "stem:[varphi]").
          gsub("&chi;", "stem:[chi]").
          gsub("&psi;", "stem:[psi]").
          gsub("&Psi;", "stem:[Psi]").
          gsub("&omega;", "stem:[omega]")
      end

      def mathml_to_asciimath(input)
        return input if input.nil? || input.empty?

        unless input.match?(/<math>/)
          return html_to_asciimath(input)
        end

        # puts "GOING TO MATHML MATH"
        # puts input
        to_asciimath = Nokogiri::HTML.fragment(input, "UTF-8")
        # to_asciimath.remove_namespaces!

        to_asciimath.css('math').each do |math_element|
          asciimath = MathML2AsciiMath.m2a(text_to_asciimath(math_element.to_xml)).strip
          # puts"ASCIIMATH!!  #{asciimath}"

          if asciimath.empty?
            math_element.remove
          else
            math_element.replace "stem:[#{asciimath}]"
          end
        end

        html_to_asciimath(
          to_asciimath.children.to_s
        )
      end

      def extract_definition_value
        if definition_values[:definition]
          mathml_to_asciimath(definition_values[:definition].strip)
        end
      end

      def extract_source_ref(str)
        case str
        when /SI Brochure/, /Brochure sur le SI/
          # SI Brochure, 9th edition, 2019, 2.3.1
          # SI Brochure, 9th edition, 2019, Appendix 1
          # Brochure sur le SI, 9<sup>e</sup> édition, 2019, Annexe 1
          "BBIPM SI Brochure TEMP DISABLED DUE TO RELATON"

        when /VIM/
          "JCGM VIM"
        # IEC 60050-121, 151-12-05
        when /IEC 60050-(\d+), (\d{2,3}-\d{2,3}-\d{2,3})/
          "IEC 60050-#{$LAST_MATCH_INFO[1]}"
        when /IEC 60050-(\d+):(\d+), (\d{2,3}-\d{2,3}-\d{2,3})/
          "IEC 60050-#{$LAST_MATCH_INFO[1]}:#{$LAST_MATCH_INFO[2]}"
        when /(AIEA|IAEA) (\d+)/
          "IAEA #{$LAST_MATCH_INFO[2]}"
        when /IEC\sIEEE ([\d\:\-]+)/
          "IEC/IEEE #{$LAST_MATCH_INFO[1]}".sub(/:\Z/, "")
        when /CISPR ([\d\:\-]+)/
          "IEC CISPR #{$LAST_MATCH_INFO[1]}"
        when /RR (\d+)/
          "ITU RR"
        # IEC 50(845)
        when /IEC (\d+)\((\d+)\)/
          "IEC 600#{$LAST_MATCH_INFO[1]}-#{$LAST_MATCH_INFO[1]}"
        when /(ISO|IEC)[\/\ ](PAS|TR|TS) ([\d\:\-]+)/
          "#{$LAST_MATCH_INFO[1]}/#{$LAST_MATCH_INFO[2]} #{$LAST_MATCH_INFO[3]}".sub(/:\Z/, "")
        when /ISO\/IEC ([\d\:\-]+)/
          "ISO/IEC #{$LAST_MATCH_INFO[1]}".sub(/:\Z/, "")
        when /ISO\/IEC\/IEEE ([\d\:\-]+)/
          "ISO/IEC/IEEE #{$LAST_MATCH_INFO[1]}".sub(/:\Z/, "")

        # ISO 140/4
        when /ISO (\d+)\/(\d+)/
          "ISO #{$LAST_MATCH_INFO[1]}-#{$LAST_MATCH_INFO[2]}"
        when /Norme ISO (\d+)-(\d+)/
          "ISO #{$LAST_MATCH_INFO[1]}:#{$LAST_MATCH_INFO[2]}"
        when /ISO\/IEC Guide ([\d\:\-]+)/i
          "ISO/IEC Guide #{$LAST_MATCH_INFO[1]}".sub(/:\Z/, "")
        when /(ISO|IEC) Guide ([\d\:\-]+)/i
          "#{$LAST_MATCH_INFO[1]} Guide #{$LAST_MATCH_INFO[2]}".sub(/:\Z/, "")

        # ITU-T Recommendation F.791 (11/2015)
        when /ITU-T Recommendation (\w.\d+) \((\d+\/\d+)\)/i
          "ITU-T Recommendation #{$LAST_MATCH_INFO[1]} (#{$LAST_MATCH_INFO[2]})"

        # ITU-T Recommendation F.791:2015
        when /ITU-T Recommendation (\w.\d+):(\d+)/i
          "ITU-T Recommendation #{$LAST_MATCH_INFO[1]} (#{$LAST_MATCH_INFO[2]})"

        when /ITU-T Recommendation (\w\.\d+)/i
          "ITU-T Recommendation #{$LAST_MATCH_INFO[1]}"

        # ITU-R Recommendation 592 MOD
        when /ITU-R Recommendation (\d+)/i
          "ITU-R Recommendation #{$LAST_MATCH_INFO[1]}"
        # ISO 669: 2000 3.1.16
        when /ISO ([\d\-]+:\s?\d{4})/
          "ISO #{$LAST_MATCH_INFO[1]}".sub(/:\Z/, "")
        when /ISO ([\d\:\-]+)/
          "ISO #{$LAST_MATCH_INFO[1]}".sub(/:\Z/, "")
        when /IEC ([\d\:\-]+)/
          "IEC #{$LAST_MATCH_INFO[1]}".sub(/:\Z/, "")
        when /definition (\d\.[\d\.]+) of ([\d\-])/
          "IEC #{$LAST_MATCH_INFO[2]}".sub(/:\Z/, "")
        when /définition (\d\.[\d\.]+) de la ([\d\-])/
          "IEC #{$LAST_MATCH_INFO[2]}".sub(/:\Z/, "")

        when /IEV (\d{2,3}-\d{2,3}-\d{2,3})/, /(\d{2,3}-\d{2,3}-\d{2,3})/
          "IEV"
        when /IEV part\s+(\d+)/, /partie\s+(\d+)\s+de l'IEV/
          "IEC 60050-#{$LAST_MATCH_INFO[1]}"

        when /International Telecommunication Union (ITU) Constitution/,
          /Constitution de l’Union internationale des télécommunications (UIT)/
          "International Telecommunication Union (ITU) Constitution (Ed. 2015)"
        else
          puts "[FAILED TO PARSE SOURCE] #{str}"
          str
        end

      end

      def extract_source_clause(str)
        # Strip out the modifications
        str = str.sub(/[,\ ]*modif.+\s[-–].*\Z/, "")

        # Strip these:
        # see figure 466-6
        # voir fig. 4.9
        str = str.gsub(/\A(see|voir) fig. [\d\.]+/, "")
        str = str.gsub(/\A(see|voir) figure [\d\.]+/, "")

        # str = 'ITU-T Recommendation F.791:2015, 3.14,'
        results = [
          [/RR (\d+)/, "1"],
          [/VIM (.+)/, "1"],
          [/item (\d\.[\d\.]+)/, "1"],
          [/d[eé]finition (\d[\d\.]+)/, "1"],
          [/figure ([\d\.\-]+)/, "figure 1"],
          [/fig\. ([\d\.\-]+)/, "figure 1"],
          [/IEV (\d{2,3}-\d{2,3}-\d{2,3})/, "1"],
          [/(\d{2,3}-\d{2,3}-\d{2,3})/, "1"],

          # 221 04 03
          [/(\d{3}\ \d{2}\ \d{2})/, "1"],
          # ", 1.1"

          # "SI Brochure, 9th edition, 2019, 2.3.1,"
          [/,\s?(\d+\.[\d\.]+)/, "1"],
          #  SI Brochure, 9th edition, 2019, Appendix 1, modified
          #  Brochure sur le SI, 9<sup>e</sup> édition, 2019, Annexe 1,
          [/\d{4}, (Appendix \d)/, "1"],
          [/\d{4}, (Annexe \d)/, "1"],

          # International Telecommunication Union (ITU) Constitution (Ed. 2015), No. 1012 of the Annex,
          # Constitution de l’Union internationale des télécommunications (UIT) (Ed. 2015), N° 1012 de l’Annexe,
          [/, (No. \d{4} of the Annex)/, "1"],
          [/, (N° \d{4} 1012 de l’Annexe)/, "1"],

          # ISO/IEC 2382:2015 (https://www.iso.org/obp/ui/#iso:std:iso-iec:2382:ed-1:v1:en), 2126371
          [/\), (\d{7}),/, "1"],

          # " 1.1 "
          [/\s(\d+\.[\d\.]+)\s?/, "1"],
          # "ISO/IEC Guide 2 (14.1)"
          [/\((\d+\.[\d\.]+)\)/, "1"],

          # "ISO/IEC Guide 2 (14.5 MOD)"
          [/\((\d+\.[\d\.]+)\ MOD\)/, "1"],

          # ISO 80000-10:2009, item 10-2.b,
          # ISO 80000-10:2009, point 10-2.b,

          [/\AISO 80000-10:2009, (item [\d\.\-]+\w?)/, "1"],
          [/\AISO 80000-10:2009, (point [\d\.\-]+\w?)/, "1"],

          # IEC 80000-13:2008, 13-9,
          [/\AIEC 80000-13:2008, ([\d\.\-]+\w?),/, "1"],
          [/\AIEC 80000-13:2008, ([\d\.\-]+\w?)\Z/, "1"],

          # ISO 921:1997, definition 6,
          # ISO 921:1997, définition 6,
          [/\AISO [\d:]+, (d[ée]finition \d+)/, "1"],

          # "ISO/IEC/IEEE 24765:2010,  <i>Systems and software engineering – Vocabulary</i>, 3.234 (2)
          [/, ([\d\.\w]+ \(\d+\))/, "1"]
        ].map do |regex, rule|
          res = []
          # puts "str is '#{str}'"
          # puts "regex is '#{regex.to_s}'"
          str.scan(regex).each do |result|
            # puts "result is #{result.first}"
            res << {
              index: $~.offset(0)[0],
              clause: result.first.strip
            }
          end
          res
          # sort by index and also the length of match
        end.flatten.sort_by { |hash| [hash[:index], -hash[:clause].length] }

        pp results

        if results.first
          results.first[:clause]
        else
          nil
        end
      end

      def extract_source_relationship(str)
        type = case str
        when /≠/
          :not_equal
        when /≈/
          :similar
        when /^([Ss]ee)|([Vv]oir)/
          :related
        when /MOD/, /ИЗМ/
          :modified
        when /modified/, /modifié/
          :modified
        when /^(from|d'après)/,
          /^(definition (.+) of)|(définition (.+) de la)/
          :identical
        else
          :identical
        end

        case str
        when /^MOD ([\d\-])/
          {
            type: type
          }
        when /(modified|modifié|modifiée|modifiés|MOD)\s*[–-–]?\s+(.+)\Z/
          {
            type: type,
            modification: $LAST_MATCH_INFO[2]
          }
        else
          {
            type: type
          }
        end
      end

      def extract_single_source(raw_ref)
        # source = "ISO/IEC GUIDE 99:2007 1.26"
        # raw_ref = str.match(/\A[^,\()]+/).to_s

        puts "[extract_single_source] #{raw_ref}"

        relation_type = extract_source_relationship(raw_ref)

        # définition 3.60 de la 62127-1
        # definition 3.60 of 62127-1
        # définition 3.60 de la 62127-1
        # definition 3.7 of IEC 62127-1 MOD, adapted from 4.2.9 of IEC 61828 and 3.6 of IEC 61102
        # définition 3.7 de la CEI 62127-1 MOD, adaptées sur la base du 4.2.9 de la CEI 61828 et du 3.6 de la CEI 61102
        # definition 3.54 of 62127-1 MOD
        # définition 3.54 de la CEI 62127-1 MOD
        # IEC 62313:2009, 3.6, modified
        # IEC 62313:2009, 3.6, modifié

        clean_ref = raw_ref
          .gsub(/CEI/, "IEC")
          .gsub(/Guide IEC/, "IEC Guide")
          .gsub(/Guide ISO\/IEC/, "ISO/IEC Guide")
          .gsub(/VEI/, "IEV")
          .gsub(/UIT/, "ITU")
          .gsub(/IUT-R/, "ITU-R")
          .gsub(/UTI-R/, "ITU-R")
          .gsub(/Recomm[ea]ndation ITU-T/, "ITU-T Recommendation")
          .gsub(/ITU-T (\w.\d{3}):(\d{4})/, 'ITU-T Recommendation \1 (\2)')
          .gsub(/ITU-R Rec. (\d+)/, 'ITU-R Recommendation \1')
          .gsub(/[≈≠]\s+/, "")
          .sub(/ИЗМ\Z/, "MOD")
          .sub(/definition ([\d\.]+) of ([\d\-\:]+) MOD/, 'IEC \2, \1, modified - ')
          .sub(/definition ([\d\.]+) of IEC ([\d\-\:]+) MOD/, 'IEC \2, \1, modified - ')
          .sub(/définition ([\d\.]+) de la ([\d\-\:]+) MOD/, 'IEC \2, \1, modified - ')
          .sub(/définition ([\d\.]+) de la IEC ([\d\-\:]+) MOD/, 'IEC \2, \1, modified - ')
          .sub(/(\d{3})\ (\d{2})\ (\d{2})/, '\1-\2-\3')  # for 221 04 03

          # .sub(/\A(from|d'après|voir la|see|See|voir|Voir)\s+/, "")

        source_ref = extract_source_ref(clean_ref)
          .sub(/, modifi(ed|é)\Z/, "")
          .strip

        clause = extract_source_clause(clean_ref)

        # puts "CLAUSENIL!!! #{raw_ref}" if clause.nil?
        # puts "SOURCE!!! #{raw_ref}" if source_ref.nil?

        # puts "[RAW] #{raw_ref}"
        h = {
          source_ref: source_ref,
          clause: clause,
          relation_type: relation_type
        }

        pp h

        item = ::Iev::Termbase::RelatonDb.instance.fetch(source_ref)

        src = {}

        src["ref"] = source_ref
        src["clause"] = clause if clause
        src["link"] = item.url if item
        src["relationship"] = relation_type
        src["original"] = raw_ref

        src
      rescue ::RelatonBib::RequestError => e
        warn e.message
      end

      def split_source_field(source)
        # IEC 62047-22:2014, 3.1.1, modified – In the definition, ...
        source = source
          .gsub(/;\s?([A-Z][A-Z])/, ';; \1')
          .gsub(/MOD[,\.]/, 'MOD;;')

        # 702-01-02 MOD,ITU-R Rec. 431 MOD
        # 161-06-01 MOD. ITU RR 139 MOD
        source = source
          .gsub(/MOD,\s*([UIC\d])/, 'MOD;; \1')
          .gsub(/MOD[,\.]/, 'MOD;;')

        # 702-09-44 MOD, 723-07-47, voir 723-10-91
        source = source
          .gsub(/MOD,\s*(\d{3})/, 'MOD;; \1')
          .gsub(/,\s*see\s*(\d{3})/, ';;see \1')
          .gsub(/,\s*voir\s*(\d{3})/, ';;voir \1')

        # IEC 62303:2008, 3.1, modified and IEC 62302:2007, 3.2; IAEA 4
        # CEI 62303:2008, 3.1, modifiée et CEI 62302:2007, 3.2; AIEA 4
        source = source
          .gsub(/modified and ([ISOECUT])/, 'modified;; \1')
          .gsub(/modifiée et ([ISOECUT])/, 'modifiée;; \1')

        # 725-12-50, ITU RR 11
        source = source.gsub(/,\s+ITU/, ";; ITU")

        # 705-02-01, 702-02-07
        source = source.gsub(/(\d{2,3}-\d{2,3}-\d{2,3}),\s*(\d{2,3}-\d{2,3}-\d{2,3})/, '\1;; \2')

        source.split(';;').map(&:strip)
      end

      def extract_authoritative_source
        source_val = find_value_for("SOURCE")

        return nil if source_val.nil?

        source_val = HTMLEntities.new.decode(source_val).gsub("\u00a0", " ")

        puts "[RAW] #{source_val}"

        split_source_field(source_val).map do |src|
          extract_single_source(src)
        end
      end

      SIMG_PATH_REGEX = "<simg .*\\/\\$file\\/([\\d\\-\\w\.]+)>"
      FIGURE_ONE_REGEX = "<p><b>\\s*Figure\\s+(\\d)\\s+[–-]\\s+(.+)\\s*<\\/b>(<\\/p>)?"
      FIGURE_TWO_REGEX = "#{FIGURE_ONE_REGEX}\\s*#{FIGURE_ONE_REGEX}"
      def parse_anchor_tag(text)
        if text
          part_number = find_value_for("IEVREF").slice(0,3)

          # Convert IEV term references
          # Convert href links
          # Need to take care of this pattern: `inverse de la <a href="IEV103-06-01">période<a>`
          text.
            gsub(/<a href="?(IEV)\s*(\d\d\d-\d\d-\d\d)"?>(.*?)<\/?a>/, '{{\3, \1:\2}}').
            gsub(/<a href="?\s*(\d\d\d-\d\d-\d\d)"?>(.*?)<\/?a>/, '{{\3, IEV:\2}}').
            gsub(/<a href="(.*?)">(.*?)<\/a>/, '\1[\2]').
            gsub(Regexp.new([SIMG_PATH_REGEX, "\\s*", FIGURE_TWO_REGEX].join('')), "image::/assets/images/parts/#{part_number}/\\1[Figure \\2 - \\3; \\6]").
            gsub(Regexp.new([SIMG_PATH_REGEX, "\\s*", FIGURE_ONE_REGEX].join('')), "image::/assets/images/parts/#{part_number}/\\1[Figure \\2 - \\3]").
            gsub(/<img\s+(.+?)\s*>/, "image::/assets/images/parts/#{part_number}/\\1[]").
            gsub(/<br>/, "\n").
            gsub(/<b>(.*?)<\/b>/, "*\\1*")

        end
      end
    end
  end
end
