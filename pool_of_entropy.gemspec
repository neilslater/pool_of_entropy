# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'pool_of_entropy/version'

Gem::Specification.new do |spec|
  spec.name          = "pool_of_entropy"
  spec.version       = PoolOfEntropy::VERSION
  spec.authors       = ["Neil Slater"]
  spec.email         = ["slobo777@gmail.com"]
  spec.summary       = %q{Random number generator with features for gamers.}
  spec.description   = %q{PoolOfEntropy is a PRNG based on cryptographic secure PRNGs, intended to bring back the feeling of 'personal luck' that some gamers feel when rolling their own dice.}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.5"
  spec.add_development_dependency "rake"
end
