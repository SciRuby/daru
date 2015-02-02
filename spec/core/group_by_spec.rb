require 'spec_helper.rb'

describe Daru::Core::GroupBy do
  before do
    @df = Daru::DataFrame.new({
      a: %w{foo bar foo bar   foo bar foo foo},
      b: %w{one one two three two two one three},
      c:   [1  ,2  ,3  ,1    ,3  ,6  ,3  ,8],
      d:   [11 ,22 ,33 ,44   ,55 ,66 ,77 ,88]
    })
  end

  context "#initialize" do
    it "groups by a single tuple" do
      grouped = @df.group_by(:a)

      expect(grouped.groups).to eq({
        ['bar'] => [1,3,5],
        ['foo'] => [0,2,4,6,7]
      })
    end

    it "groups by a double layer hierarchy" do
      grouped = @df.group_by([:a, :b])

      expect(grouped.groups).to eq({
        ['foo', 'one']   => [0,6],
        ['bar', 'one']   => [1],
        ['foo', 'two']   => [2,4],
        ['bar', 'three'] => [3],
        ['bar', 'two']   => [5],
        ['foo', 'three'] => [7]
      })
    end

    it "groups by a triple layer hierarchy" do
      grouped = @df.group_by([:a, :b, :c])

      expect(grouped.groups).to eq({
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

  context "#mean" do

  end

  context "#count" do

  end

  context "#[]" do

  end
end