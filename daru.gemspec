# coding: utf-8
$:.unshift File.expand_path("../lib", __FILE__)

require 'version.rb'

DESCRIPTION = <<MSG
Daru (Data Analysis in RUby) is a library for storage, analysis and manipulation
of data.
MSG

Gem::Specification.new do |spec|
  spec.name          = 'daru'
  spec.version       = Daru::VERSION
  spec.authors       = ['Sameer Deshmukh']
  spec.email         = ['sameer.deshmukh93@gmail.com']
  spec.summary       = %q{Data Analysis in RUby}
  spec.description   = DESCRIPTION
  spec.homepage      = "http://github.com/v0dro/daru"
  spec.license       = 'BSD-2'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'awesome_print'
  if RUBY_ENGINE != 'jruby'
    spec.add_development_dependency 'nmatrix', '~> 0.1.0.rc5'
  end
end