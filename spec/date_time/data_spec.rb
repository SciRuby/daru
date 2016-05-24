describe Daru::Vector do
  context "#initialize" do
    it "accepts DateTimeIndex in index option" do
      index  = Daru::DateTimeIndex.date_range(:start => DateTime.new(2012,2,1), periods: 100)
      vector = Daru::Vector.new [1,2,3,4,5]*20, index: index

      expect(vector.class).to eq(Daru::Vector)
      expect(vector['2012-2-3']).to eq(3)
    end
  end

  context "#[]" do
    before do
      index   = Daru::DateTimeIndex.date_range(
        :start => DateTime.new(2012,4,4), :end => DateTime.new(2012,4,7), freq: 'H')
      @vector = Daru::Vector.new([23]*index.size, index: index)
    end

    it "returns the element when complete date" do
      expect(@vector['2012-4-4 22:00:00']).to eq(23)
    end

    it "accepts DateTime object for [] argument" do
      expect(@vector[DateTime.new(2012,4,4,22)]).to eq(23)
    end

    it "returns slice when partial date" do
      slice_index = Daru::DateTimeIndex.date_range(
        :start => DateTime.new(2012,4,4), :periods => 24, freq: 'H')
      expect(@vector['2012-4-4']).to eq(
        Daru::Vector.new([23]*slice_index.size, index: slice_index))
    end

    it "returns a slice when range" do
      slice_index = Daru::DateTimeIndex.date_range(
        :start => DateTime.new(2012,4,4), :end => DateTime.new(2012,4,5,23,), freq: 'H')
      expect(@vector['2012-4-4'..'2012-4-5']).to eq(
        Daru::Vector.new([23]*slice_index.size, index: slice_index))
    end

    it "returns a slice when numeric range" do
      slice_index = Daru::DateTimeIndex.date_range(
        :start => DateTime.new(2012,4,4), :periods => 20, :freq => 'H')
      expect(@vector[0..19]).to eq(
        Daru::Vector.new([23]*slice_index.size, index: slice_index))
    end

    it "returns the element when number" do
      expect(@vector[32]).to eq(23)
    end
  end

  context "#[]=" do
    it "assigns a single element when index complete" do
      index = Daru::DateTimeIndex.date_range(:start => '2012', :periods => 5, :freq => 'D')
      vector = Daru::Vector.new([1,2,3,4,5], index: index)
      vector['2012-1-4'] = 666
      expect(vector).to eq(Daru::Vector.new([1,2,3,666,5], index: index))
    end

    it "assigns single element when specified a number for indexing" do
      index = Daru::DateTimeIndex.date_range(:start => '2012', :periods => 5, :freq => 'D')
      vector = Daru::Vector.new([1,2,3,4,5], index: index)

      vector[2] = 666
      expect(vector).to eq(
        Daru::Vector.new([1,2,666,4,5], index: index))
    end

    it "assigns multiple elements when index incomplete" do
      index          = Daru::DateTimeIndex.date_range(:start => '2012', :periods => 100,
        :freq => 'MB')
      vector         = Daru::Vector.new([1,2,3,4,5,6,7,8,9,10]*10, index: index)
      vector['2012'] = 666
      arr            = [666]*12 + [3,4,5,6,7,8,9,10] +  [1,2,3,4,5,6,7,8,9,10]*8
      expect(vector).to eq(Daru::Vector.new(arr, index: index))
    end
  end
end

describe Daru::DataFrame do
  before :each do
    @index = Daru::DateTimeIndex.date_range(:start => '2012-2-1', periods: 100)
    @order = Daru::DateTimeIndex.new([
      DateTime.new(2012,1,3),DateTime.new(2013,2,3),DateTime.new(2012,3,3)])
    @a     = [1,2,3,4,5]*20
    @b     = @a.map { |e| e*3 }
    @c     = @a.map(&:to_s)
    @df    = Daru::DataFrame.new([@a, @b, @c], index: @index, order: @order)
  end

  context "#initialize" do
    it "accepts DateTimeIndex for index and order options" do
      expect(@df.index).to eq(@index)
      expect(@df['2013-2-3']).to eq(
        Daru::Vector.new(@b, index: @index))
    end
  end

  context "#[]" do
    it "returns one Vector when complete index" do
      expect(@df['2012-3-3']).to eq(Daru::Vector.new(@c, index: @index))
    end

    it "returns a Vector when DateTime object specified" do
      expect(@df[DateTime.new(2012,3,3)]).to eq(
        Daru::Vector.new(@c, index: @index))
    end

    it "returns DataFrame when incomplete index" do
      answer = Daru::DataFrame.new(
        [@a, @c], index: @index, order: Daru::DateTimeIndex.new([
          DateTime.new(2012,1,3),DateTime.new(2012,3,3)]))
      expect(@df['2012']).to eq(answer)
    end

    it "returns Vector when single index specified as a number" do
      expect(@df[1]).to eq(Daru::Vector.new(@b, index: @index))
    end
  end

  context "#[]=" do
    it "assigns one Vector when complete index" do
      answer = Daru::DataFrame.new([@a, @b, @a], index: @index, order: @order)
      @df['2012-3-3'] = @a
      expect(@df).to eq(answer)
    end

    it "assigns one Vector when index as DateTime object" do
      answer = Daru::DataFrame.new([@a, @b, @a], index: @index, order: @order)
      @df[DateTime.new(2012,3,3)] = @a
      expect(@df).to eq(answer)
    end

    it "assigns multiple vectors when incomplete index" do
      answer = Daru::DataFrame.new([@b,@b,@b], index: @index, order: @order)
      @df['2012'] = @b
      expect(@df).to eq(answer)
    end

    it "assigns Vector when specified position index" do
      answer = Daru::DataFrame.new([@a, @b, @a], index: @index, order: @order)
      @df[2] = @a
      expect(@df).to eq(answer)
    end
  end

  context "#row[]" do
    it "returns one row Vector when complete index" do
      expect(@df.row['2012-2-1']).to eq(Daru::Vector.new([1,3,"1"], index: @order))
    end

    it "returns one row when complete DateTime specified" do
      expect(@df.row[DateTime.new(2012,2,1)]).to eq(
        Daru::Vector.new([1,3,"1"], index: @order))
    end

    it "returns DataFrame when incomplete index" do
      range = 0..28
      a = @a[range]
      b = @b[range]
      c = @c[range]
      i = Daru::DateTimeIndex.date_range(:start => '2012-2-1', periods: 29)
      answer = Daru::DataFrame.new([a,b,c], index: i, order: @order)

      expect(@df.row['2012-2']).to eq(answer)
    end

    it "returns one row Vector when position index" do
      expect(@df.row[2]).to eq(Daru::Vector.new([3,9,'3'], index: @order))
    end
  end

  context "#row[]=" do
    it "assigns one row Vector when complete index" do
      @df.row['2012-2-4'] = [666,999,0]
      expect(@df.row['2012-2-4']).to eq(Daru::Vector.new([666,999,0], index: @order))
    end

    it "assigns one row Vector when complete index as DateTime" do
      @df.row[DateTime.new(2012,2,5)] = [1,2,3]
      expect(@df.row[DateTime.new(2012,2,5)]).to eq(
        Daru::Vector.new([1,2,3], index: @order))
    end

    it "assigns multiple rows when incomplete index" do
      a = [666]*29
      b = [999]*29
      c = [0]*29
      index = Daru::DateTimeIndex.date_range(:start => '2012-2-1', :periods => 29)
      answer = Daru::DataFrame.new([a,b,c], index: index, order: @order)
      @df.row['2012-2'] = [666,999,0]

      expect(@df.row['2012-2']).to eq(answer)
    end
  end
end
