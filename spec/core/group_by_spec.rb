require 'spec_helper.rb'

describe Daru::Core::GroupBy do
  before do
    @df = Daru::DataFrame.new({
      a: %w{foo bar foo bar   foo bar foo foo},
      b: %w{one one two three two two one three},
      c:   [1  ,2  ,3  ,1    ,3  ,6  ,3  ,8],
      d:   [11 ,22 ,33 ,44   ,55 ,66 ,77 ,88]
    })

    @sl_group = @df.group_by(:a)
    @dl_group = @df.group_by([:a, :b])
    @tl_group = @df.group_by([:a,:b,:c])

    @dl_multi_index = Daru::MultiIndex.new([
      [:bar, :one],
      [:bar, :three],
      [:bar, :two],
      [:foo, :one],
      [:foo, :three],
      [:foo, :two]
    ])

    @tl_multi_index = Daru::MultiIndex.new([
      [:bar, :one  , 2],
      [:bar, :three, 1],
      [:bar, :two  , 6],
      [:foo, :one  , 1],
      [:foo, :one  , 3],
      [:foo, :three, 8],
      [:foo, :two  , 3]
    ])
  end

  context "#initialize" do
    it "groups by a single tuple" do
      expect(@sl_group.groups).to eq({
        ['bar'] => [1,3,5],
        ['foo'] => [0,2,4,6,7]
      })
    end

    it "groups by a double layer hierarchy" do
      expect(@dl_group.groups).to eq({
        ['foo', 'one']   => [0,6],
        ['bar', 'one']   => [1],
        ['foo', 'two']   => [2,4],
        ['bar', 'three'] => [3],
        ['bar', 'two']   => [5],
        ['foo', 'three'] => [7]
      })
    end

    it "groups by a triple layer hierarchy" do
      expect(@tl_group.groups).to eq({
        ['bar', 'one'  , 2] => [1],
        ['bar', 'three', 1] => [3],
        ['bar', 'two'  , 6] => [5],
        ['foo', 'one'  , 1] => [0],
        ['foo', 'one'  , 3] => [6],
        ['foo', 'three', 8] => [7],
        ['foo', 'two'  , 3] => [2,4]
      })
    end

    it "raises error if a non-existent vector is passed as args" do
      expect {
        @df.group_by([:a, :ted])
      }.to raise_error
    end
  end

  context "#size" do
    it "returns the size of each group" do
      # TODO
    end
  end

  context "#get_group" do

  end

  context "#aggregate" do

  end

  context "#mean" do
    it "computes mean of the numeric columns of a single layer group" do
      expect(@sl_group.mean).to eq(Daru::DataFrame.new({
        :c => [3.0, 3.6],
        :d => [44.0, 52.8]
        }, index: [:bar, :foo]
      ))
    end

    it "computes mean of the numeric columns of a double layer group" do
      expect(@dl_group.mean).to eq(Daru::DataFrame.new({
        c: [2,1,6,2,8,3],
        d: [22,44,66,44,88,44]
        }, index: @dl_multi_index))
    end

    it "computes mean of the numeric columns of a triple layer group" do
      expect(@tl_group.mean).to eq(Daru::DataFrame.new({
        d: [22,44,66,11,77,88,44]
        }, index: @tl_multi_index
      ))
    end
  end

  context "#sum" do
    it "calculates the sum of the numeric columns of a single layer group" do
    end

    it "calculates the sum of the numeric columns of a double layer group" do
    end

    it "calculates the sum of the numeric columns of a triple layer group" do
    end
  end

  context "#count" do
    it "counts the number of elements in a single layer group" do
    end

    it "counts the number of elements in a double layer group" do
    end

    it "counts the number of elements in a triple layer group" do
    end
  end

  context "#[]" do

  end
end