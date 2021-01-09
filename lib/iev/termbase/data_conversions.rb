module Iev
  module Termbase
    module DataConversions
      refine String do
        def decode_html!
          replace(decode_html)
          nil
        end

        def decode_html
          HTMLEntities.new(:expanded).decode(self)
        end

        # Normalize various encoding anomalies like `\uFEFF` in strings
        def sanitize!
          unicode_normalize!
          gsub!("\uFEFF", "")
          gsub!("\u2011", "-")
          gsub!("\u00a0", " ")
          strip!
          nil
        end

        # @see sanitize!
        def sanitize
          dup.tap(&:sanitize!)
        end
      end
    end
  end
end
