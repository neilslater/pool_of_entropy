# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'pool_of_entropy/version'

Gem::Specification.new do |spec|
  spec.name          = "pool_of_entropy"
  spec.version       = PoolOfEntropy::VERSION
  spec.authors       = ["Neil Slater"]
  spec.email         = ["slobo777@gmail.com"]
  spec.summary       = %q{Random number generator with extra features for gamers.}
  spec.description   = %q{PoolOfEntropy is a PRNG based on cryptographic secure PRNGs, intended to bring back the feeling of 'personal luck' that some gamers feel when rolling their own dice.}
  spec.homepage      = "https://github.com/neilslater/pool_of_entropy"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "yard", ">= 0.8.7.2"
  spec.add_development_dependency "bundler", ">= 1.3"
  spec.add_development_dependency "rspec", ">= 2.13.0"
  spec.add_development_dependency "rake", ">= 1.9.1"
  spec.add_development_dependency "coveralls", ">= 0.6.7"
end
