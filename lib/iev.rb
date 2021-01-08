require "creek"
require "yaml"
require "zeitwerk"

loader = Zeitwerk::Loader.for_gem
loader.inflector.inflect(
  "ui" => "UI",
)
loader.setup

module Iev
  def self.root_path
    Pathname.new(File.dirname(__dir__))
  end
end

require "iev/termbase"
require "iev/termbase/cli"
