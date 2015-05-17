require 'rspec'
require 'matrix'
require 'awesome_print'

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

ALL_DTYPES = [:nmatrix, :gsl, :array]

# FIXME: This must go! Need to be able to use be_within
def expect_correct_vector_in_delta v1, v2, delta
  expect(v1.size).to eq(v2.size)
  (0...v1.size).each do |v|
    expect(v1[v]).to be_within(delta).of(v2[v])
  end
end