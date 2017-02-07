require 'rspec'
require 'rspec/its'
require 'matrix'
require 'awesome_print'
require 'distribution'
require 'tempfile'
require 'pry-byebug'
require 'nokogiri'
require 'gruff'
require 'webmock/rspec'

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

require 'simplecov'
SimpleCov.start do
  add_filter 'vendor'
  add_filter 'spec'
  minimum_coverage_by_file 95
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

def expect_correct_df_in_delta df1, df2, delta
  df1.each_vector_with_index do |vector, i|
    expect_correct_vector_in_delta vector, df2[i], delta
  end
end

class String
  # allows to pretty test agains multiline strings:
  #   %Q{
  #     |test
  #     |me
  #   }.unindent # =>
  # "test
  # me"
  def unindent
    gsub(/\n\s+?\|/, "\n")    # for all lines looking like "<spaces>|" -- remove this.
    .gsub(/\|\n/, "\n")       # allow to write trailing space not removed by editor
    .gsub(/^\n|\n\s+$/, '')   # remove empty strings before and after
  end
end

Dir[File.expand_path('../support/**/*.rb', __FILE__)].each {|f| require f }

RSpec.configure do |config|
  config.before(:each) do 
    stub_request(:get,'https://raw.githubusercontent.com/anshuman23/ruBayes/master/test/sample.csv').
      to_return(status: 200, body: "a,b,c,d,e\n4.8,3.4,1.9,0.2,Iris-setosa\n5.0,3.0,1.6,0.2,Iris-setosa\n5.0,3.4,1.6,0.4,Iris-setosa\n5.2,3.5,1.5,0.2,Iris-setosa\n6.6,3.0,4.4,1.4,Iris-versicolor\n6.8,2.8,4.8,1.4,Iris-versicolor\n6.7,3.0,5.0,1.7,Iris-versicolor\n6.0,2.9,4.5,1.5,Iris-versicolor\n6.4,3.1,5.5,1.8,Iris-virginica\n6.0,3.0,4.8,1.8,Iris-virginica\n6.9,3.1,5.4,2.1,Iris-virginica\n6.7,3.1,5.6,2.4,Iris-virginica\n")
  end
end
