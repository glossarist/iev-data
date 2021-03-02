# frozen_string_literal: true

# (c) Copyright 2020 Ribose Inc.
#

module IEV
  module Termbase
    module CLI
      def self.start(arguments)
        IEV::Termbase::CLI::Command.start(arguments)
      end
    end
  end
end
