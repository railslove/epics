# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'epics/version'

Gem::Specification.new do |spec|
  spec.name          = "epics"
  spec.version       = Epics::VERSION
  spec.authors       = ["Lars Brillert"]
  spec.email         = ["lars@railslove.com"]
  spec.summary       = %q{a ruby implementation of the EBICS protocol}
  spec.description   = %q{a ruby implementation of the EBICS protocol}
  spec.homepage      = "https://github.com/railslove/epics"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "nokogiri"
  spec.add_dependency "gyoku"
  spec.add_dependency "multi_json"
  spec.add_dependency "faraday"
  spec.add_dependency "faraday_middleware"
  spec.add_dependency "hex_string"
  spec.add_dependency "activesupport"

  spec.add_development_dependency "bundler", ">= 1.6.2"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "pry"
end
