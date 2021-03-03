# frozen_string_literal: true

# (c) Copyright 2020 Ribose Inc.
#

module IEV
  module Termbase
    module CLI
      module UI
        module_function

        # Prints progress message which will be replaced on next call.
        def progress(message)
          return unless $TERMBASE_PROGRESS
          print "#{Helper.clear_progress}#{message} "
        end

        # Prints generic message.
        def info(message)
          print "#{Helper.clear_progress}#{message}\n"
        end

        module Helper
          module_function

          def clear_progress
            $TERMBASE_PROGRESS ? "\r#{" " * 40}\r" : ""
          end
        end
      end
    end
  end
end
