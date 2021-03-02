# frozen_string_literal: true

# (c) Copyright 2020 Ribose Inc.
#

module IEV::Termbase
  class ConceptCollection < Hash

    def add_term(term)
      if self[term.id]
        self[term.id].add_term(term)
      else
        self[term.id] = Concept.new(id: term.id, terms: [term])
      end
    end

    def self.build_from_dataset(ds)
      new.tap do |concept_collection|
        ds.each do |row|
          term = TermBuilder.build_from(row)
          concept_collection.add_term(term)
        end
      end
    end

    def to_hash
      self.inject({}) do |acc, (id, concept)|
        acc.merge!(id => concept.to_hash)
      end
    end

    def to_file(filename)
      File.open(filename,"w") do |file|
        file.write(to_hash.to_yaml)
      end
    end
  end
end
