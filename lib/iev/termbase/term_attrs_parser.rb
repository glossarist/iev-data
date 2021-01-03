module Iev
  module Termbase
    class TermAttrsParser
      attr_reader :raw_str, :src_str

      def initialize(attr_str)
        @raw_str = attr_str.dup.freeze
        @src_str = (HTMLEntities.new(:expanded).decode(attr_str) || "").freeze
      end

      def inspect
        "<ATTRIBUTES: #{src_str}>".freeze
      end

      def extract_gender
        genders = src_str.match(/\s([m|f|n])$|^([m|f|n])[\s,]?|([m|f|n]) (pl)/)

        if genders
          plurality = "singular"
          gender = genders[1..3].join('')
          plurality = "plural" if genders.size > 1 && genders[4] == "pl"

          { "gender" => gender, "plurality" => plurality }
        end
      end

      def parts_hash
        @parts_hash ||= {
          "名詞" => "noun",
          "動詞" => "verb",
          "形容詞" => "adj",
          "형용사" => "adj",
          "Adjektiv" => "adj",
        }
      end

      def extract_geographical_area
        area = src_str.match(/([A-Z]{2})$/)
        if area && area.size > 1
          area[1]
        end
      end

      def extract_part_of_speech
        parts_regex = /noun|名詞|verb|動詞|Adjektiv|adj|形容詞|형용사/
        part_of_speeches = src_str.match(parts_regex)

        if part_of_speeches
          part_of_speech = part_of_speeches[1]
          parts_hash[part_of_speech] || part_of_speech
        end
      end

      def extract_usage_info
        usage_info = src_str.match(/<(.*?)>/)

        if usage_info && usage_info.size > 1
          usage_info[1].strip
        end
      end

      def extract_prefix
        src_str.match(/Präfix|prefix|préfixe|接尾語|접두사|przedrostek|prefixo|词头/) ? true : nil
      end
    end
  end
end
