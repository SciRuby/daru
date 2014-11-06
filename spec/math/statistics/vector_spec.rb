require 'spec_helper.rb'

describe Daru::Vector do
  before :each do
    @dv = Daru::Vector.new [1,2,3,4,5]
  end

  context "#mean" do
    it "calculates the mean" do
      expect(@dv.mean).to eq(3)
    end
  end

  context "#median" do
    it "calculates median" do
    end
  end
end