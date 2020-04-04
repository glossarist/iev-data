require "creek"
require "yaml"

module Iev
  def self.root_path
    Pathname.new(File.dirname(__dir__))
  end
end

require "iev/termbase"
require "iev/termbase/cli"
