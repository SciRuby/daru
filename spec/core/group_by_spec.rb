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

    @sl_index = Daru::Index.new([:bar, :foo])
    @dl_multi_index = Daru::MultiIndex.from_tuples([
      [:bar, :one],
      [:bar, :three],
      [:bar, :two],
      [:foo, :one],
      [:foo, :three],
      [:foo, :two]
    ])
    @tl_multi_index = Daru::MultiIndex.from_tuples([
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
    it "returns a vector containing the size of each group" do
      expect(@dl_group.size).to eq(Daru::Vector.new([1,1,1,2,1,2], index: @dl_multi_index))
    end
  end

  context "#get_group" do
    it "returns the whole sub-group for single layer grouping" do
      expect(@sl_group.get_group(['bar'])).to eq(Daru::DataFrame.new({
        a: ['bar', 'bar', 'bar'],
        b: ['one', 'three', 'two'],
        c: [2,1,6],
        d: [22,44,66]
        }, index: [1,3,5]
      ))
    end

    it "returns the whole sub-group for double layer grouping" do
      expect(@dl_group.get_group(['bar', 'one'])).to eq(Daru::DataFrame.new({
        a: ['bar'],
        b: ['one'],
        c: [2],
        d: [22]
        }, index: [1]
      ))
    end

    it "returns the whole sub-group for triple layer grouping" do
      expect(@tl_group.get_group(['foo','two',3])).to eq(Daru::DataFrame.new({
        a: ['foo', 'foo'],
        b: ['two', 'two'],
        c: [3,3],
        d: [33,55]
        }, index: [2,4]
      ))
    end

    it "raises error for incomplete specification" do
      expect {
        @tl_group.get_group(['foo'])
      }.to raise_error
    end

    it "raises error for over specification" do
      expect {
        @sl_group.get_group(['bar', 'one'])
      }.to raise_error
    end
  end

  context "#aggregate" do
    pending
  end

  context "#mean" do
    it "computes mean of the numeric columns of a single layer group" do
      expect(@sl_group.mean).to eq(Daru::DataFrame.new({
        :c => [3.0, 3.6],
        :d => [44.0, 52.8]
        }, index: @sl_index
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
      expect(@sl_group.sum).to eq(Daru::DataFrame.new({
        c: [9, 18],
        d: [132, 264]
        }, index: @sl_index
      ))
    end

    it "calculates the sum of the numeric columns of a double layer group" do
      expect(@dl_group.sum).to eq(Daru::DataFrame.new({
        c: [2,1,6,4,8,6],
        d: [22,44,66,88,88,88]
        }, index: @dl_multi_index))
    end

    it "calculates the sum of the numeric columns of a triple layer group" do
      expect(@tl_group.sum).to eq(Daru::DataFrame.new({
        d: [22,44,66,11,77,88,88]
        }, index: @tl_multi_index))
    end
  end

  context "#product" do
    it "calculates product for single layer groups" do
      # TODO
    end

    it "calculates product for double layer groups" do
      # TODO
    end

    it "calculates product for triple layer groups" do
      # TODO
    end
  end

  context "#count" do
    it "counts the number of elements in a single layer group" do
      expect(@sl_group.count).to eq(Daru::DataFrame.new({
        b: [3,5],
        c: [3,5],
        d: [3,5]
        }, index: @sl_index))
    end

    it "counts the number of elements in a double layer group" do
      expect(@dl_group.count).to eq(Daru::DataFrame.new({
        c: [1,1,1,2,1,2],
        d: [1,1,1,2,1,2]
        }, index: @dl_multi_index))
    end

    it "counts the number of elements in a triple layer group" do
      expect(@tl_group.count).to eq(Daru::DataFrame.new({
        d: [1,1,1,1,1,1,2]
        }, index: @tl_multi_index))
    end
  end

  context "#std" do
    it "calculates sample standard deviation for single layer groups" do
      # TODO
    end

    it "calculates sample standard deviation for double layer groups" do
      # TODO
    end

    it "calculates sample standard deviation for triple layer groups" do
      # TODO
    end
  end

  context "#max" do
    it "calculates max value for single layer groups" do
      # TODO
    end

    it "calculates max value for double layer groups" do
      # TODO
    end

    it "calculates max value for triple layer groups" do
      # TODO
    end
  end

  context "#min" do
    it "calculates min value for single layer groups" do
      # TODO
    end

    it "calculates min value for double layer groups" do
      # TODO
    end

    it "calculates min value for triple layer groups" do
      # TODO
    end
  end

  context "#median" do
    it "calculates median for single layer groups" do
      # TODO
    end

    it "calculates median for double layer groups" do
      # TODO
    end

    it "calculates median for triple layer groups" do
      # TODO
    end
  end

  context "#head" do
    it "returns first n rows of each single layer group" do
      expect(@sl_group.head(2)).to eq(Daru::DataFrame.new({
        a: ['bar', 'bar','foo','foo'],
        b: ['one', 'three','one', 'two'],
        c: [2, 1, 1, 3],
        d: [22, 44, 11, 33]
      }, index: [1,3,0,2]))
    end

    it "returns first n rows of each double layer group" do
      expect(@dl_group.head(2)).to eq(Daru::DataFrame.new({
        a: ['bar','bar','bar','foo','foo','foo','foo','foo'],
        b: ['one','three','two','one','one','three','two','two'],
        c: [2,1,6,1,3,8,3,3],
        d: [22,44,66,11,77,88,33,55]
      }, index: [1,3,5,0,6,7,2,4]))
    end

    it "returns first n rows of each triple layer group" do
      expect(@tl_group.head(1)).to eq(Daru::DataFrame.new({
        a: ['bar','bar','bar','foo','foo','foo','foo'],
        b: ['one','three','two','one','one','three','two'],
        c: [2,1,6,1,3,8,3],
        d: [22,44,66,11,77,88,33]
        }, index: [1,3,5,0,6,7,2]))
    end
  end

  context "#tail" do
    it "returns last n rows of each single layer group" do
      expect(@sl_group.tail(1)).to eq(Daru::DataFrame.new({
        a: ['bar','foo'],
        b: ['two', 'three'],
        c: [6,8],
        d: [66,88]
      }, index: [5,7]))
    end

    it "returns last n rows of each double layer group" do
      expect(@dl_group.tail(2)).to eq(Daru::DataFrame.new({
        a: ['bar','bar','bar','foo','foo','foo','foo','foo'],
        b: ['one','three','two','one','one','three','two','two'],
        c: [2,1,6,1,3,8,3,3],
        d: [22,44,66,11,77,88,33,55]
        }, index: [1,3,5,0,6,7,2,4]))
    end

    it "returns last n rows of each triple layer group" do
      expect(@tl_group.tail(1)).to eq(Daru::DataFrame.new({
        a: ['bar','bar','bar','foo','foo','foo','foo'],
        b: ['one','three','two','one','one','three','two'],
        c: [2,1,6,1,3,8,3],
        d: [22,44,66,11,77,88,55]
        }, index: [1,3,5,0,6,7,4]))
    end
  end

  context "#[]" do
    pending
  end
end