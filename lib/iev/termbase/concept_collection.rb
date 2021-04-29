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
      Profiler.measure("building-collection") do
        new.tap do |concept_collection|
          ds.each do |row|
            term = TermBuilder.build_from(row)
            concept_collection.add_term(term)
          end
        end
      end
    end
  end
end
