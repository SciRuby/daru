require 'spec_helper.rb'

describe Daru::Vector do
<<<<<<< HEAD
  [NMatrix, Array].each do |stype|
    describe stype do
      before :each do
        @dv = Daru::Vector.new [1,2,3,4,5], stype: stype
      end

      context "#mean" do
        it "calculates mean" do
          expect(@dv.mean).to eq(3)
        end
      end
    end
=======

  context "#mean" do

  end

  context "#median" do

>>>>>>> parent of 3816c8b... started array wrapper statistics
  end
end