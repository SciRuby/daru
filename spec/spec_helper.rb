require 'rspec'
require 'awesome_print'
require 'matrix'

def mri?
  RUBY_ENGINE == 'ruby'
end

def jruby?
  RUBY_ENGINE == 'jruby'
end

if jruby?
  require 'mdarray'
else
  require 'nmatrix'
end

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'daru'