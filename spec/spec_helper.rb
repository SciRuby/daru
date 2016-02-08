require 'rspec'
require 'matrix'
require 'awesome_print'
require 'distribution'
require 'tempfile'
require 'pry-byebug'

def mri?
  RUBY_ENGINE == 'ruby'
end

def jruby?
  RUBY_ENGINE == 'jruby'
end

if jruby?
  require 'mdarray'
else
  require 'nmatrix/nmatrix'
end

RSpec::Expectations.configuration.warn_about_potential_false_positives = false


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

def expect_correct_df_in_delta df1, df2, delta
  df1.each_vector_with_index do |vector, i|
    expect_correct_vector_in_delta vector, df2[i], delta
  end
end

Dir[File.expand_path('../support/**/*.rb', __FILE__)].each {|f| require f }
