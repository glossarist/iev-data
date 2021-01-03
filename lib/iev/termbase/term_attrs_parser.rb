module Iev
  module Termbase
    class TermAttrsParser
      attr_reader :raw_str, :src_str

      attr_reader :gender, :geographical_area, :part_of_speech, :plurality,
        :prefix, :usage_info

      PARTS_OF_SPEECH = {
        "adj" => "adj",
        "noun" => "noun",
        "verb" => "verb",
        "名詞" => "noun",
        "動詞" => "verb",
        "形容詞" => "adj",
        "형용사" => "adj",
        "Adjektiv" => "adj",
      }.freeze

      def initialize(attr_str)
        @raw_str = attr_str.dup.freeze
        @src_str = decode_attrs_string(raw_str).freeze
        parse
      end

      def inspect
        "<ATTRIBUTES: #{src_str}>".freeze
      end

    private

      def parse
        extract_gender
        extract_plurality
        extract_geographical_area
        extract_part_of_speech
        extract_usage_info
        extract_prefix
      end

      def extract_gender
        gender_rx = /\b[mfn]\b/

        if gender_rx =~ src_str
          @gender = $&
        end
      end

      # Must happen after #extract_gender
      def extract_plurality
        plural_rx = /\bpl\b/

        if plural_rx =~ src_str
          @plurality = "plural"
        elsif !gender.nil?
          # TODO Really needed?
          @plurality = "singular"
        end
      end

      def extract_geographical_area
        area = src_str.match(/([A-Z]{2})$/)
        if area && area.size > 1
          @geographical_area = area[1]
        end
      end

      def extract_part_of_speech
        pos_rx = %r{
          \b
          #{Regexp.union(PARTS_OF_SPEECH.keys)}
          \b
        }x.freeze

        if pos_rx =~ src_str
          @part_of_speech = PARTS_OF_SPEECH[$&] || $&
        end
      end

      def extract_usage_info
        info_rx = /<(.*?)>/

        if info_rx =~ src_str
          @usage_info = $~[1].strip
        end
      end

      def extract_prefix
        @prefix = src_str.match(/Präfix|prefix|préfixe|接尾語|접두사|przedrostek|prefixo|词头/) ? true : nil
      end

      def decode_attrs_string(str)
        HTMLEntities.new(:expanded).decode(str) || ""
      end
    end
  end
end
