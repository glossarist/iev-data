# frozen_string_literal: true

module IEV
  module Termbase
    module Utilities

      SIMG_PATH_REGEX = "<simg .*\\/\\$file\\/([\\d\\-\\w\.]+)>"
      FIGURE_ONE_REGEX = "<p><b>\\s*Figure\\s+(\\d)\\s+[–-]\\s+(.+)\\s*<\\/b>(<\\/p>)?"
      FIGURE_TWO_REGEX = "#{FIGURE_ONE_REGEX}\\s*#{FIGURE_ONE_REGEX}"

      def parse_anchor_tag(text)
        if text
          # Convert IEV term references
          # Convert href links
          # Need to take care of this pattern: `inverse de la <a href="IEV103-06-01">période<a>`
          text.
            gsub(/<a href="?(IEV)\s*(\d\d\d-\d\d-\d\d)"?>(.*?)<\/?a>/, '{{\3, \1:\2}}').
            gsub(/<a href="?\s*(\d\d\d-\d\d-\d\d)"?>(.*?)<\/?a>/, '{{\3, IEV:\2}}').
            gsub(/<a href="(.*?)">(.*?)<\/a>/, '\1[\2]').
            gsub(Regexp.new([SIMG_PATH_REGEX, "\\s*", FIGURE_TWO_REGEX].join("")), "image::/assets/images/parts/#{term_domain}/\\1[Figure \\2 - \\3; \\6]").
            gsub(Regexp.new([SIMG_PATH_REGEX, "\\s*", FIGURE_ONE_REGEX].join("")), "image::/assets/images/parts/#{term_domain}/\\1[Figure \\2 - \\3]").
            gsub(/<img\s+(.+?)\s*>/, "image::/assets/images/parts/#{term_domain}/\\1[]").
            gsub(/<br>/, "\n").
            gsub(/<b>(.*?)<\/b>/, "*\\1*")

        end
      end

      def replace_newlines(input)
        input.gsub('\n', "\n\n").gsub(/<[pbr]+>/, "\n\n").gsub(/\s*\n[\n\s]+/, "\n\n").strip
      end
    end
  end
end
