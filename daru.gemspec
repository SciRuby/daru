# coding: utf-8
$:.unshift File.expand_path("../lib", __FILE__)

require 'daru/version.rb'

Daru::DESCRIPTION = <<MSG
Daru (Data Analysis in RUby) is a library for analysis, manipulation and visualization
of data.

Daru works with Ruby arrays and NMatrix, thus working seamlessly accross
ruby interpreters, at the same time providing speed for those who need it, while 
making working with data super simple and intuitive.
MSG

Gem::Specification.new do |spec|
  spec.name          = 'daru'
  spec.version       = Daru::VERSION
  spec.authors       = ['Sameer Deshmukh']
  spec.email         = ['sameer.deshmukh93@gmail.com']
  spec.summary       = %q{Data Analysis in RUby}
  spec.description   = Daru::DESCRIPTION
  spec.homepage      = "http://github.com/v0dro/daru"
  spec.license       = 'BSD-2'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency 'reportbuilder', '~> 1.4'
  spec.add_runtime_dependency 'spreadsheet', '~> 1.0.3'

  spec.add_development_dependency 'bundler', '~> 1.10'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'pry', '~> 0.10'
  spec.add_development_dependency 'pry-byebug'
  spec.add_development_dependency 'rserve-client', '~> 0.3'
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'awesome_print'
  spec.add_development_dependency 'nyaplot', '~> 0.1.5'
  spec.add_development_dependency 'nmatrix', '~> 0.1.0'
  spec.add_development_dependency 'distribution', '~> 0.7'
  spec.add_development_dependency 'rb-gsl', '~>1.16'
end