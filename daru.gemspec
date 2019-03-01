# coding: utf-8
$:.unshift File.expand_path("../lib", __FILE__)

require 'daru/version.rb'

Daru::DESCRIPTION = <<MSG
Daru (Data Analysis in RUby) is a library for analysis, manipulation and visualization
of data. Daru works seamlessly accross interpreters and leverages interpreter-specific
optimizations whenever they are available.

It is the default data storage gem for all the statsample gems (glm, timeseries, etc.)
and can be used with many others like mixed_models, gnuplotrb, nyaplot and iruby.
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

  spec.add_runtime_dependency 'backports'

  # it is required by NMatrix, yet we want to specify clearly which minimal version is OK
  spec.add_runtime_dependency 'packable', '~> 1.3.9'

  spec.add_development_dependency 'spreadsheet', '~> 1.1.1'
  spec.add_development_dependency 'bundler', '>= 1.10'
  spec.add_development_dependency 'rake', '~>10.5'
  spec.add_development_dependency 'pry', '~> 0.10'
  spec.add_development_dependency 'pry-byebug'
  spec.add_development_dependency 'rserve-client', '~> 0.3'
  spec.add_development_dependency 'rspec', '~> 3.4'
  spec.add_development_dependency 'rspec-its'
  spec.add_development_dependency 'awesome_print'
  spec.add_development_dependency 'nyaplot', '~> 0.1.5'
  spec.add_development_dependency 'nmatrix', '~> 0.2.1'
  spec.add_development_dependency 'distribution', '~> 0.7'
  spec.add_development_dependency 'gsl', '~>2.1.0.2'
  spec.add_development_dependency 'dbd-sqlite3'
  spec.add_development_dependency 'dbi'
  spec.add_development_dependency 'activerecord', '~> 4.0'
  spec.add_development_dependency 'mechanize'
  # issue : https://github.com/SciRuby/daru/issues/493 occured 
  # with latest version of sqlite3
  spec.add_development_dependency  'sqlite3', '~> 1.3.13'
  spec.add_development_dependency 'rubocop', '~> 0.49.0'
  spec.add_development_dependency 'ruby-prof'
  spec.add_development_dependency 'simplecov'
  spec.add_development_dependency 'gruff'
  spec.add_development_dependency 'webmock'

  if RUBY_VERSION < '2.1.0'
    spec.add_development_dependency 'nokogiri', '<= 1.6.8.1'
  else
    spec.add_development_dependency 'nokogiri'
  end
  if RUBY_VERSION >= '2.2.5'
    spec.add_development_dependency 'guard-rspec'
  end
end
