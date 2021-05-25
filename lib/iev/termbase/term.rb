# frozen_string_literal: true

# (c) Copyright 2020 Ribose Inc.
#

module IEV::Termbase
  class Term
    ATTRIBS = %i(
    id
    alt
    terms
    abbrev
    synonyms
    definition
    country_code
    language_code
    notes examples
    entry_status
    classification
    review_indicator
    authoritative_source
    authoritative_source_similarity
    lineage_source
    lineage_source_similarity
    date_accepted
    date_amended
    review_date
    review_status
    review_type
    review_decision
    review_decision_date
    review_decision_event
    review_decision_notes
    )

    attr_accessor *ATTRIBS

    attr_accessor :superseded_concepts

    def initialize(options = {})
      initialize_from_options(options)
      # @examples = []
      # @notes = []
      #
      # # puts "options #{options.inspect}"
      #
      # options.each_pair do |k, v|
      #   v = v.strip if v.is_a?(String)
      #   next unless v
      #   case k
      #   when /^example/
      #     add_example(v)
      #   when /^note/
      #     add_note(v)
      #   else
      #     # puts"Key #{k}"
      #     key = k.to_s.gsub("-", "_")
      #     self.send("#{key}=", v)
      #   end
      # end
      # self
    end

    def initialize_from_options(options)
      options.each_pair do |key, value|
        next unless value

        if value.is_a?(String)
          value = value.strip
        end

        key = key.to_s.gsub("-", "_")
        self.send("#{key}=", value)
      end
    end

    def to_hash
      ATTRIBS.inject({}) do |acc, attrib|
        value = self.send(attrib)
        unless value.nil?
          acc.merge(attrib.to_s => value)
        else
          acc
        end
      end
    end

    # entry-status
    ## Must be one of notValid valid superseded retired
    def entry_status=(value)
      case value
      when "有效的", "käytössä", "действующий", "válido"
        value = "valid"
      when "korvattu", "reemplazado"
        value = "superseded"
      when "информация отсутствует" # "information absent"!?
        value = "retired"
      when %w(notValid valid superseded retired)
        # do nothing
      end
      @entry_status = value
    end

    # classification
    ## Must be one of the following: preferred admitted deprecated
    def classification=(value)
      case value
      when ""
        value = "admitted"
      when "认可的", "допустимый", "admitido"
        value = "admitted"
      when "首选的", "suositettava", "suositeltava", "рекомендуемый", "preferente"
        value = "preferred"
      when %w(preferred admitted deprecated)
        # do nothing
      end
      @classification = value
    end

    def related_concepts
      # TODO someday other relation types too
      arr = [superseded_concepts].flatten.compact
      arr.empty? ? nil : arr
    end
  end

end
