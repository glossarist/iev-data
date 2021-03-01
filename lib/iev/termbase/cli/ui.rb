module IEV
  module Termbase
    module CLI
      module UI
        module_function

        def progress(message, persistent: false)
          return unless $TERMBASE_PROGRESS
          print "\r#{" " * 40}\r" # clear line
          print persistent ? "#{message}\n" : "#{message} "
        end
      end
    end
  end
end
