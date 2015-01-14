require 'spec_helper.rb'

describe Daru::DataFrame do
  before(:each) do
    @df = Daru::DataFrame.new({a: [1,2,3,4,5], b: ['a','e','i','o','u'], 
      c: [10,20,30,40,50]})
  end

  context "#+" do
    it "adds a number to all numeric vectors" do
      expect(@df + 2).to eq(Daru::DataFrame.new({a: [2,4,5,6,7], b: ['a','e','i','o','u'], 
      c: [12,22,32,42,52] }))
    end
  end

  context "#-" do
    it "subtracts a number from all numeric vectors" do
      expect(@df - 2).to eq(Daru::DataFrame.new({a: [-1,0,1,2,3], b: ['a','e','i','o','u'], 
      c: [8,18,28,38,48]}))
    end
  end

  context "#*" do
  end

  context "#/" do
  end

  context "#%" do
  end

  context "#**" do
  end
end