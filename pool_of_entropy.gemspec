# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'pool_of_entropy/version'

Gem::Specification.new do |spec|
  spec.name          = 'pool_of_entropy'
  spec.version       = PoolOfEntropy::VERSION
  spec.authors       = ['Neil Slater']
  spec.email         = ['slobo777@gmail.com']
  spec.summary       = 'Random number generator with extra features for gamers.'
  spec.description   = "PoolOfEntropy is a PRNG based on cryptographic secure PRNGs, intended to bring back the feeling of 'personal luck' that some gamers feel when rolling their own dice."
  spec.homepage      = 'https://github.com/neilslater/pool_of_entropy'
  spec.license       = 'MIT'
  spec.required_ruby_version = '>= 3.3'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '>= 2.5', '< 5'
  spec.add_development_dependency 'coveralls_reborn', '~> 1.0'
  spec.add_development_dependency 'rake', '~> 13.2'
  spec.add_development_dependency 'rspec', '~> 3.13'
  spec.add_development_dependency 'yard', '~> 0.9.37'
end
