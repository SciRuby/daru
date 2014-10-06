require 'rspec'

if RUBY_ENGINE == 'jruby'
  require 'mdarray'
else
  require 'nmatrix'
end

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'daru'