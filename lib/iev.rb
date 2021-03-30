# (c) Copyright 2020 Ribose Inc.
#

# frozen_string_literal: true

require "benchmark"
require "creek"
require "mathml2asciimath"
require "oga"
require "relaton"
require "relaton_bib"
require "ruby-prof"
require "sequel"
require "thor"
require "yaml"
require "zeitwerk"

loader = Zeitwerk::Loader.for_gem
loader.inflector.inflect(
  "cli" => "CLI",
  "iev" => "IEV",
  "ui" => "UI",
)
loader.setup

module IEV
  def self.root_path
    Pathname.new(File.dirname(__dir__))
  end
end

require "iev/termbase/cli"
