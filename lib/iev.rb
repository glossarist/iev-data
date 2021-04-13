# (c) Copyright 2020 Ribose Inc.
#

# frozen_string_literal: true

require "asciimath"
require "benchmark"
require "creek"
require "html2asciimath"
require "mathml2asciimath"
require "relaton"
require "relaton_bib"
require "reverse_adoc"
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
end

require "iev/termbase/cli"
