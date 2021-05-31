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
  end
end
