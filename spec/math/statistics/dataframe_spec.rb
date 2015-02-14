require 'spec_helper.rb'

describe Daru::DataFrame do
  before do
    @df = Daru::DataFrame.new({
      a: ['foo'  ,  'foo',  'foo',  'foo',  'foo',  'bar',  'bar',  'bar',  'bar'], 
      b: ['one'  ,  'one',  'one',  'two',  'two',  'one',  'one',  'two',  'two'],
      c: ['small','large','large','small','small','large','small','large','small'],
      d: [1,2,2,3,3,4,5,6,7],
      e: [2,4,4,6,6,8,10,12,14],
      f: [10,20,20,30,30,40,50,60,70]
    })
  end

  context "#mean" do
    it "calculates mean of single level numeric only vectors and returns values in a Vector" do
      expect(@df.mean.round(2)).to eq(Daru::Vector.new([3.67, 7.33, 36.67], 
        index: [:d, :e, :f]
      ))
    end

    it "calculates mean of multi level numeric only vectors and returns values in a DataFrame" do
      # TODO - pending
    end
  end

  context "#std" do
    it "calculates standard deviation of single leavel numeric only vectors and returns values in a Vector" do
      expect(@df.std).to eq(Daru::Vector.new([2, 4, 20], index: [:d, :e, :f]))
    end
  end

  context "#sum" do
    it "calculates sum of single level numeric only vectors and returns values in a Vector" do
      # TODO - write tests
    end
  end

  context "#count" do
    # TODO
  end

  context "#mode" do
    # TODO
  end

  context "#median" do
    # TODO
  end

  context "#max" do
    # TODO
  end

  context "#min" do
    # TODO
  end

  context "#product" do
    # TODO
  end

  context "#describe" do
    it "generates mean, std, max, min and count of numeric vectors in one shot" do
      expect(@df.describe.round(2)).to eq(Daru::DataFrame.new({
        d: [9.00, 3.67 ,2.00 , 1.00,  7.00],
        e: [9.00, 7.33 ,4.00 , 2.00, 14.00],
        f: [9.00, 36.67,20.00,10.00, 70.00]
        }, index: [:count, :mean, :std, :min, :max]
      ))
    end
  end

  context "#cov" do
    it "calculates the variance covariance of the numeric vectors of DataFrame" do
      expect(@df.cov).to eq(Daru::DataFrame.new({
        d: [4,8,40],
        e: [8,16,80],
        f: [40,80,400]
        }, index: [:d, :e, :f]
      ))
    end
  end

  context "#corr", focus: true do
    it "calculates the correlation between the numeric vectors of DataFrame" do
      expect(@df.corr).to eq(Daru::DataFrame.new({
        d: [1,1,1],
        e: [1,1,1],
        f: [1,1,1]
        }, index: [:d, :e, :f]
      ))
    end
  end
end