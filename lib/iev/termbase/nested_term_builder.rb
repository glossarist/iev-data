module Iev
  module Termbase
    class NestedTermBuilder
      def initialize(options = {})
        @options = options
        @data = options.fetch(:data, nil)
        @status = options.fetch(:status, nil)
      end

      def build
        if options[:term]
          build_nested_term.select {|_k, value| !value.nil? }
        end
      end

      def self.build(options)
        new(options).build
      end

      private

      attr_reader :data, :status, :options

      def term_attributes
        @term_attributes ||= HTMLEntities.new(:expanded).decode(data.to_s) || ""
      end

      def build_nested_term
        {
          "type" => options[:type],
          "prefix" => extract_prefix,
          "normative_status" => term_status,
          "usage_info" => extract_usage_info,
          "designation" => options[:term],
          "part_of_speech" => extract_part_of_speech,
          "geographical_area" => extract_geographical_area,
          "international" => options.fetch(:international, nil),
        }.merge(extract_gender || {})
      end

      def term_status
        status.downcase if status
      end

      def extract_gender
        genders = term_attributes.match(/\s([m|f|n])$|^([m|f|n])[\s,]?|([m|f|n]) (pl)/)

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
        area = term_attributes.match(/([A-Z]{2})$/)
        if area && area.size > 1
          area[1]
        end
      end

      def extract_part_of_speech
        parts_regex = /noun|名詞|verb|動詞|Adjektiv|adj|形容詞|형용사/
        part_of_speeches = term_attributes.match(parts_regex)

        if part_of_speeches
          part_of_speech = part_of_speeches[1]
          parts_hash[part_of_speech] || part_of_speech
        end
      end

      def extract_usage_info
        usage_info = term_attributes.match(/<(.*?)>/)

        if usage_info && usage_info.size > 1
          usage_info[1].strip
        end
      end

      def extract_prefix
        term_attributes.match(/Präfix|prefix|préfixe|接尾語|접두사|przedrostek|prefixo|词头/) ? true : nil
      end
    end
  end
end
