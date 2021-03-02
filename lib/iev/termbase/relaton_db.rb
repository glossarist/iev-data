# frozen_string_literal: true

# (c) Copyright 2020 Ribose Inc.
#

require "singleton"

module IEV
  module Termbase
    # Relaton cach singleton.
    class RelatonDb
      include Singleton

      def initialize
        @db = Relaton::Db.new "db", nil
      end

      # @param code [String] reference
      # @return [RelatonIso::IsoBibliongraphicItem]
      def fetch(code)
        retrying_on_failures do
          @db.fetch code
        end
      end

      private

      def retrying_on_failures(attempts: 4)
        curr_attempt = 1

        begin
          yield

        rescue
          if curr_attempt <= attempts
            sleep(2 ** curr_attempt * 0.1)
            curr_attempt += 1
            retry
          else
            raise
          end
        end
      end
    end
  end
end
