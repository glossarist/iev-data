# frozen_string_literal: true

# (c) Copyright 2020 Ribose Inc.
#

module IEV
  module Termbase
    module DataConversions
      HTML_ENTITIES_DECODER = HTMLEntities.new(:expanded)

      refine String do
        def decode_html!
          replace(decode_html)
          nil
        end

        def decode_html
          HTML_ENTITIES_DECODER.decode(self)
        end

        # Normalize various encoding anomalies like `\uFEFF` in strings
        def sanitize!
          unicode_normalize!
          gsub!("\uFEFF", "")
          gsub!("\u2011", "-")
          gsub!("\u00a0", " ")
          gsub!(/[\u2000-\u2006]/, " ")
          strip!
          nil
        end

        # @see sanitize!
        def sanitize
          dup.tap(&:sanitize!)
        end

        def to_three_char_code
          IEV::Termbase::Iso639Code.three_char_code(self).first
        end
      end
    end
  end
end
