lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "iev/termbase/version"

Gem::Specification.new do |spec|
  spec.name          = "iev-termbase"
  spec.version       = Iev::Termbase::VERSION
  spec.authors       = ["Ribose"]
  spec.email         = ["open.source@ribose.com"]

  spec.summary       = %q{Build scripts for the ISO/TC 211 Termbase}
  spec.description   = %q{Build scripts for the ISO/TC 211 Termbase}
  spec.homepage      = "https://open.ribose.com"

  spec.require_paths = ["lib"]
  spec.bindir        = "exe"
  spec.files         = `git ls-files`.split("\n")
  spec.test_files    = `git ls-files -- {spec}/*`.split("\n")
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }

  spec.add_runtime_dependency "creek"
  spec.add_runtime_dependency "relaton", "~> 0.5"

  spec.add_development_dependency "bundler", "~> 2.0.1"
  spec.add_development_dependency "debase"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "ruby-debug-ide"
end
