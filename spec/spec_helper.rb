require 'rspec'
require 'rspec/its'
require 'rspec/expectations'
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
  # minimum_coverage_by_file 95 -- too strict for now. Reconsider after specs redesign.
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

RSpec::Matchers.define :be_all_within do |delta|
  match do |actual|
    expect(@expected).to_not be_nil
    expect(actual.size).to equal(actual.size)
    (@act, @exp), @idx = actual.zip(@expected).each_with_index.detect { |(a, e), _| (a - e).abs > delta }
    @idx.nil?
  end

  chain :of do |expected|
    @expected = expected
  end

  failure_message do |actual|
    return "expected value must be provided using '.of'." if @expected.nil?
    return "expected.size must equal actual.size." if @expected.size != actual.size
    "at index=[#{@idx}], expected '#{actual[@idx]}' to be within '#{delta}' of '#{@expected[@idx]}'."
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
