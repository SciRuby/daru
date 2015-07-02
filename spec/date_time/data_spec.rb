require 'spec_helper'

include Daru
describe Vector do
  context "#initialize" do
    it "accepts DateTimeIndex in index option" do
      index  = DateTimeIndex.date_range(:start => Time.new(2012,2,1), periods: 100)
      vector = Vector.new [1,2,3,4,5]*20, index: index

      expect(vector.class).to eq(Vector)
      expect(vector['2012-2-3']).to eq(3)
    end
  end

  context "#[]" do
    before do
      index   = DateTimeIndex.date_range(
        :start => Time.new(2012,4,4), :end => Time.new(2012,4,7), freq: :H)
      @vector = Vector.new([23]*index.size, index: index)
    end

    it "returns the element when complete date" do
      expect(@vector['2012-4-4 22:00:00']).to eq(23)
    end

    it "returns slice when partial date" do
      slice_index = DateTimeIndex.date_range(
        :start => Time.new(2012,4,4), :periods => 24, freq: :H)
      expect(@vector['2012-4-4']).to eq(
        Vector.new([23]*slice_index.size, index: slice_index))
    end

    it "returns a slice when range" do
      slice_index = DateTimeIndex.date_range(
        :start => Time.new(2012,4,4), :end => Time.new(2012,4,5), freq: :H)
      expect(@vector['2012-4-4'..'2012-4-5']).to eq(
        Vector.new([23]*slice_index.size, index: slice_index))
    end
  end

  context "#[]=" do
    it "assigns a single element when index complete" do
      # TODO
    end

    it "assigns multiple elements when index incomplete" do
      # TODO
    end
  end
end

describe DataFrame do
  before do
    @index = DateTimeIndex.date_range(:start => '2012-2-1', periods: 100)
    @order = DateTimeIndex.new([
      Time.new(2012,1,3),Time.new(2013,2,3),Time.new(2012,3,3)])
    @a     = [1,2,3,4,5]*20
    @b     = @a.map { |e| e*3 }
    @c     = @a.map(&:to_s)
    @df    = DataFrame.new([@a, @b, @c], index: index, order: order)    
  end

  context "#initialize" do
    it "accepts DateTimeIndex for index and order options" do
      expect(@df.index).to eq(index)
      expect(@df['2013-2-3']).to eq(Vector.new(arry.map { |e| e*3 }, index: index))
    end
  end

  context "#[]" do
    it "returns one Vector when complete index" do
      expect(@df['2012-3-3']).to eq(@c)
    end

    it "returns DataFrame when incomplete index" do
      answer = DataFrame.new(
        [@a, @c], index: @index, order: DateTimeIndex.new([
          Time.new(2012,1,3),Time.new(2012,3,3)])
        )
      expect(@df['2012']).to eq(answer)
    end
  end

  context "#[]=" do
    it "assigns one Vector when complete index" do
      answer = DataFrame.new([@a, @b, @a], index: @index, order: @order)
      @df['2012-3-3'] = @a
      expect(@df).to eq(answer)
    end

    it "assigns multiple vectors when incomplete index" do
      answer = DataFrame.new([@b,@b,@b], index: @index, order: @order)
      @df['2012'] = @b
      expect(@df).to eq(answer)
    end
  end

  context "#row[]" do
    it "returns one row Vector when complete index" do
      expect(@df.row['2012-2-1']).to eq(Vector.new([1,3,"1"], index: @order))
    end

    it "returns DataFrame when incomplete index" do
      range = 0..28
      a = @a[range]
      b = @b[range]
      c = @c[range]
      i = DateTimeIndex.date_range(:start => '2012-2-1', periods: 29)
      answer = DataFrame.new([a,b,c], index: index, order: @order)

      expect(@df.row['2012-2']).to eq(answer)
    end
  end

  context "#row[]=" do
    it "assigns one row Vector when complete index" do
      # TODO
    end

    it "assigns multiple rows when incomplete index" do
      # TODO
    end
  end
end
