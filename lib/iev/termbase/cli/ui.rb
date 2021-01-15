module IEV
  module Termbase
    module CLI
      module UI
        module_function

        def progress(message)
          print "\r#{message} "
        end
      end
    end
  end
end
