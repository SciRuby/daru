require 'spec_helper.rb'

describe Daru::Vector do
  before :each do
    @dv1 = Daru::Vector.new [1,2,3,4], name: :boozy, index: [:bud, :kf, :henie, :corona]
    @dv2 = Daru::Vector.new [1,2,3,4], name: :mayer, index: [:obi, :wan, :kf, :corona]
    @with_md1 = Daru::Vector.new [1,2,3,nil,5,nil], name: :missing, index: [:a, :b, :c, :obi, :wan, :corona]
    @with_md2 = Daru::Vector.new [1,2,3,nil,5,nil], name: :missing, index: [:obi, :wan, :corona, :a, :b, :c]
  end

  context "#+" do
    it "adds matching indexes of the other vector" do
      expect(@dv1 + @dv2).to eq(Daru::Vector.new([nil,8,nil,5,nil,nil], name: :boozy, index: [:bud,:corona,:henie,:kf,:obi,:wan]))
    end

    it "adds number to each element of the entire vector" do
      expect(@dv1 + 5).to eq(Daru::Vector.new [6,7,8,9], name: :boozy, index: [:bud, :kf, :henie, :corona])
    end

    it "does not add when a number is being added" do
      expect(@with_md1 + 1).to eq(Daru::Vector.new([2,3,4,nil,6,nil], name: :missing, index: [:a, :b, :c, :obi, :wan, :corona]))
    end

    it "puts a nil when one of the operands is nil" do
      expect(@with_md1 + @with_md2).to eq(Daru::Vector.new([nil,7,nil,nil,nil,7], name: :missing, index: [:a, :b, :c, :corona, :obi, :wan]))
    end
  end

  context "#-" do
    it "subtracts matching indexes of the other vector" do
      expect(@dv1 - @dv2).to eq(Daru::Vector.new([nil,0,nil,-1,nil,nil], name: :boozy, index: [:bud,:corona,:henie,:kf,:obi,:wan]))
    end

    it "subtracts number from each element of the entire vector" do
      expect(@dv1 - 5).to eq(Daru::Vector.new [-4,-3,-2,-1], name: :boozy, index: [:bud, :kf, :henie, :corona])
    end
  end

  context "#*" do
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

  context "#**" do
    
  end

  context "#exp", focus: true do
    it "calculates exp of all numbers" do
      expect(@with_md1.exp.round(3)).to eq(Daru::Vector.new([2.718281828459045, 
        7.38905609893065, 20.085536923187668, nil, 148.4131591025766, nil], index: 
        [:a, :b, :c, :obi, :wan, :corona], name: :missing).round(3))
    end
  end

  context "#abs" do
    it "calculates abs value" do
      @with_md1.abs
    end
  end

  context "#sqrt" do
    it "calculates sqrt" do
      @with_md1.sqrt
    end
  end

  context "#round" do
    it "rounds to given precision" do
      @with_md1.round(2)
    end 
  end
end