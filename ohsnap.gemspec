# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'ohsnap/version'

Gem::Specification.new do |gem|
  gem.name          = 'ohsnap'
  gem.version       = Ohsnap::VERSION
  gem.authors       = ['Jason Wadsworth']
  gem.email         = ['jdwadsworth@gmail.com']
  gem.description   = %q{
    Ohsnap simplifies moving and processing data snapshots between development,
    testing and production environements.
  }
  gem.summary       = %q{Moves PostgreSQL data from here to there.}
  gem.homepage      = 'https://github.com/subakva/ohsnap'

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ['lib']

  gem.add_dependency('thor')
  gem.add_development_dependency('rake', ['~> 0.9.2'])
  gem.add_development_dependency('rspec', ['~> 2.11.0'])
  gem.add_development_dependency('rspec-fire', ['~> 1.1.3'])
  gem.add_development_dependency('cane', ['~> 2.3.0'])
  gem.add_development_dependency('simplecov', ['~> 0.7.1'])

end
