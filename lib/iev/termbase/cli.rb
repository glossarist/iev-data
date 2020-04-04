require "thor"
require "iev/termbase/cli/command"

module Iev
  module Termbase
    module Cli
      def self.start(arguments)
        Iev::Termbase::Cli::Command.start(arguments)
      end
    end
  end
end
