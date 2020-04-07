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
        @term_attributes ||= data.to_s.split("; ")
      end

      def build_nested_term
        {
          "type" => options[:type],
          "normativeStatus" => term_status,
          "designation" => options[:term],
          "partOfSpeech" => extract_part_of_speach,
          "geographicalArea" => extract_geographical_area,
          "international" => options.fetch(:international, nil),
        }.merge(extract_gender || {})
      end

      def term_status
        status.downcase if status
      end

      def extract_gender
        genders = term_attributes.grep(/[m|f|n]$|[m|f|n] pl/)

        unless genders.empty?
          plurality = "singular"
          genders = genders.first.split(" ")
          plurality = "plural" if genders.size > 1 && genders[1] == "pl" 

          { "gender" => genders[0], "plurality" => plurality }
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
        term_attributes.grep(/[A-Z]{2}$/).first
      end

      def extract_part_of_speach
        parts_regex = /noun|名詞|verb|動詞|Adjektiv|adj|形容詞|형용사/
        part_of_speaches = term_attributes.grep(parts_regex)

        unless part_of_speaches.empty?
          part_of_speach = part_of_speaches.first
          parts_hash[part_of_speach] || part_of_speach
        end
      end
    end
  end
end
