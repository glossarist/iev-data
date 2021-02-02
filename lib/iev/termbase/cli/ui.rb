module IEV
  module Termbase
    module CLI
      module UI
        module_function

        def progress(message)
          return unless $TERMBASE_PROGRESS
          print "\r#{message} "
        end
      end
    end
  end
end
