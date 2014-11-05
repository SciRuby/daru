require 'spec_helper.rb'

describe Daru::Vector do
  before :each do
    @dv1 = Daru::Vector.new [1,2,3,4], name: :boozy, index: [:bud, :kf, :henie, :corona]
    @dv2 = Daru::Vector.new [1,2,3,4], name: :mayer, index: [:obi, :wan, :kf, :corona]
  end

  context "#+" do
    it "adds matching indexes of the other vector" do
      expect(@dv1 + @dv2).to eq(Daru::Vector.new([5, 8], name: :boozy, index: [:kf, :corona]))
    end

    it "adds number to each element of the entire vector" do
      expect(@dv1 + 5).to eq(Daru::Vector.new [6,7,8,9], name: :boozy, index: [:bud, :kf, :henie, :corona])
    end
  end

  context "#-" do
    it "subtracts matching indexes of the other vector" do
      expect(@dv1 - @dv2).to eq(Daru::Vector.new([-1,0], name: :boozy, index: [:kf, :corona]))
    end

    it "subtracts number from each element of the entire vector" do
      expect(@dv1 - 5).to eq(Daru::Vector.new [-4,-3,-2,-1], name: :boozy, index: [:bud, :kf, :henie, :corona])
    end
  end

  context "#*"
    it "multiplies matching indexes of the other vector" do

    end

    it "multiplies number to each element of the entire vector" do
      
    end
  end

  context "#\/" do
    it "divides matching indexes of the other vector" do

    end

    it "divides number from each element of the entire vector" do
      
    end
  end

  context "#%" do

  end