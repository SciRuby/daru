require 'spec_helper.rb'

describe Daru::Vector do
  [NMatrix, Array].each do |dtype|
    describe dtype do
      before :each do
        @dv = Daru::Vector.new [1,2,3,4,5], dtype: dtype
      end

      context "#mean" do
        it "calculates mean" do
          expect(@dv.mean).to eq(3)
        end
      end

      context "#sum_of_squares" do

      end

      context "#standard_deviation_sample" do

      end

      context "#variance_sample" do
        
      end
    end
  end
end