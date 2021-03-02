# frozen_string_literal: true

module IEV
  module Termbase
    module CLI
      def self.start(arguments)
        IEV::Termbase::CLI::Command.start(arguments)
      end
    end
  end
end
