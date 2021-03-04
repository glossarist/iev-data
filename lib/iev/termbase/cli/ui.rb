# frozen_string_literal: true

# (c) Copyright 2020 Ribose Inc.
#

module IEV
  module Termbase
    module CLI
      module UI
        module_function

        def debug(*args)
          Helper.cli_out(:debug, *args)
        end

        def warn(*args)
          Helper.cli_out(:warn, *args)
        end

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

          def cli_out(_level, *args)
            message = args.map(&:to_s).join(" ").chomp

            print [
              clear_progress,
              message,
              "\n",
            ].join
          end
        end
      end
    end
  end
end
