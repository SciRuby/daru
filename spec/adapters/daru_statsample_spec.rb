require 'spec_helper'
# require_relative 'statsample/lib/statsample.rb'
require 'daru/adapters/statsample'

# describe "daru statsample adapter" do
#   context Statsample::Bivariate do
#     it ".sum_of_squares" do
#       v1 = Daru::Vector.new([1,2,3,4,5,6])
#       v2 = Daru::Vector.new([6,2,4,10,12,8])
#       pending
#       expect(Statsample::Bivariate.sum_of_squares(v1,v2)).to eq(23.0)
#     end

#     it ".covariance" do
#       v1 = Daru::Vector.new(20.times.collect {|a| rand()})
#       v2 = Daru::Vector.new(20.times.collect {|a| rand()})
#       pending
#       expect(Statsample::Bivariate.covariance(v1,v2)).to be_within(0.001).of(
#         Statsample::Bivariate.covariance_slow(v1,v2))
#     end
#   end

#   context Statsample::Regression::Simple do
#     it ".from_new_vectors" do
#       a = Daru::Vector.new([1,2,3,4,5,6])
#       b = Daru::Vector.new([6,2,4,10,12,8])
#       reg = Statsample::Regression::Simple.new_from_vectors(a,b)

#       expect((reg.ssr+reg.sse).to_f).to be_within(0.001).of(reg.sst)
#     end
#   end
# end