require 'spec_helper.rb'

describe Daru::DataFrame do
  context "#initialize" do
    it "initializes an empty DataFrame" do
      df = Daru::DataFrame.new({}, [:a, :b])

      expect(df.vectors).to eq(Daru::Index.new [:a, :b])
      expect(df.a.class).to eq(Daru::Vector)
      expect(df.a)      .to eq([].dv(:a)) 
    end

    it "initializes from a Hash" do
      df = Daru::DataFrame.new({b: [11,12,13,14,15], a: [1,2,3,4,5]}, [:a, :b],
        [:one, :two, :three, :four, :five])

      expect(df.index)  .to eq(Daru::Index.new [:one, :two, :three, :four, :five])
      expect(df.vectors).to eq(Daru::Index.new [:a, :b])
      expect(df.a.class).to eq(Daru::Vector)
      expect(df.a)      .to eq([1,2,3,4,5].dv(:a, df.index)) 
    end

    it "initializes from a Hash of Vectors" do
      df = Daru::DataFrame.new({b: [11,12,13,14,15].dv(:b, [:one, :two, :three, :four, :five]), 
        a: [1,2,3,4,5].dv(:a, [:one, :two, :three, :four, :five])}, [:a, :b],
        [:one, :two, :three, :four, :five])

      expect(df.index)  .to eq(Daru::Index.new [:one, :two, :three, :four, :five])
      expect(df.vectors).to eq(Daru::Index.new [:a, :b])
      expect(df.a.class).to eq(Daru::Vector)
      expect(df.a)      .to eq([1,2,3,4,5].dv(:a, [:one, :two, :three, :four, :five])) 
    end

    it "initializes from an Array of Hashes" do
      df = Daru::DataFrame.new([{a: 1, b: 11}, {a: 2, b: 12}, {a: 3, b: 13},
        {a: 4, b: 14}, {a: 5, b: 15}], [:b, :a], [:one, :two, :three, :four, :five])

      expect(df.index)  .to eq(Daru::Index.new [:one, :two, :three, :four, :five])
      expect(df.vectors).to eq(Daru::Index.new [:b, :a])
      expect(df.a.class).to eq(Daru::Vector)
      expect(df.a)      .to eq([1,2,3,4,5].dv(:a,[:one, :two, :three, :four, :five])) 
    end

    it "accepts Index objects for row/col" do
      rows = Daru::Index.new [:one, :two, :three, :four, :five]
      cols = Daru::Index.new [:a, :b]

      df  = Daru::DataFrame.new({b: [11,12,13,14,15], a: [1,2,3,4,5]}, cols, rows)

      expect(df.a)      .to eq(Daru::Vector.new(:a, [1,2,3,4,5]     , rows))
      expect(df.b)      .to eq(Daru::Vector.new(:b, [11,12,13,14,15], rows))
      expect(df.index)  .to eq(Daru::Index.new [:one, :two, :three, :four, :five])
      expect(df.vectors).to eq(Daru::Index.new [:a, :b])
    end

    it "initializes without specifying row/col index" do
      df = Daru::DataFrame.new({b: [11,12,13,14,15], a: [1,2,3,4,5]})

      expect(df.index)  .to eq(Daru::Index.new [0,1,2,3,4])
      expect(df.vectors).to eq(Daru::Index.new [:a, :b])
    end

    it "initializes from Vectors by correct index" do
      pending "Implement creation of DataFrame from unequal vectors by \
        inserting nils into resulting DataFrame"

      raise
    end

    it "completes incomplete vectors" do
      df = Daru::DataFrame.new({b: [11,12,13,14,15], a: [1,2,3,4,5], 
        c: [11,22,33,44,55]}, [:a, :c])

      expect(df.vectors).to eq([:a,:c,:b].to_index)
    end

    it "raises error for incomplete index" do
      expect {
        df = Daru::DataFrame.new({b: [11,12,13,14,15], a: [1,2,3,4,5], 
          c: [11,22,33,44,55]}, [:a, :b, :c], [:one, :two, :three])
      }.to raise_error
    end

    it "raises error for unequal sized vectors" do
      expect {
        df = Daru::DataFrame.new({b: [11,12,13], a: [1,2,3,4,5], 
          c: [11,22,33,44,55]}, [:a, :b, :c], [:one, :two, :three])
      }.to raise_error
    end
  end

  context "#[:vector]" do
    before :each do
      @df = Daru::DataFrame.new({b: [11,12,13,14,15], a: [1,2,3,4,5], 
        c: [11,22,33,44,55]}, [:a, :b, :c], [:one, :two, :three, :four, :five])
    end

    it "returns a Vector" do
      expect(@df[:a, :vector]).to eq([1,2,3,4,5].dv(:a, [:one, :two, :three, :four, :five]))
    end

    it "returns a DataFrame" do
      temp = Daru::DataFrame.new({b: [11,12,13,14,15], a: [1,2,3,4,5]}, 
        [:a, :b], [:one, :two, :three, :four, :five])

      expect(@df[:a, :b, :vector]).to eq(temp)
    end

    it "accesses vector with Integer index" do
      expect(@df[0, :vector]).to eq([1,2,3,4,5].dv(:a, [:one, :two, :three, :four, :five]))
    end
  end

  context "#[:row]" do
    before :each do
      @df = Daru::DataFrame.new({b: [11,12,13,14,15], a: [1,2,3,4,5], 
        c: [11,22,33,44,55]}, [:a, :b, :c], [:one, :two, :three, :four, :five])
    end

    it "returns a row with the given index" do
      expect(@df[:one, :row]).to eq([1,11,11].dv(:one, [:a, :b, :c]))
    end

    it "returns a row with given Integer index" do
      expect(@df[0, :row]).to eq([1,11,11].dv(:one, [:a, :b, :c]))
    end
  end

  context "#[:vector]=" do
    before :each do
      @df = Daru::DataFrame.new({b: [11,12,13,14,15], a: [1,2,3,4,5], 
        c: [11,22,33,44,55]}, [:a, :b, :c], [:one, :two, :three, :four, :five])
    end

    it "appends an Array as a Daru::Vector" do
      @df[:d, :vector] = [69,99,108,85,49]

      expect(@df.d.class).to eq(Daru::Vector)
    end

    it "replaces an already present vector" do
      @df[:a, :vector] = [69,99,108,85,49].dv(nil, [:one, :two, :three, :four, :five])

      expect(@df.a).to eq([69,99,108,85,49].dv(nil, [:one, :two, :three, :four, :five]))
    end

    it "appends a new vector to the DataFrame" do
      @df[:woo, :vector] = [69,99,108,85,49].dv(nil, [:one, :two, :three, :four, :five])

      expect(@df.vectors).to eq([:a, :b, :c, :woo].to_index)
    end

    it "creates an index for the new vector if not specified" do
      @df[:woo, :vector] = [69,99,108,85,49]

      expect(@df.woo.index).to eq([:one, :two, :three, :four, :five].to_index)
    end

    it "raises error if index mismatch between DataFrame and new vector(s)" do
      expect {
        @df[:woo, :vector] = [69,99,108,85,49].dv
      }.to raise_error

      # TODO: Remove this. Must work for mismatched indexes(?).
    end    

    it "inserts vector of same length as DataFrame but of mangled index" do
      pending "Implement after adding constructor for DataFrame from vectors with \ 
        unequal index."

      # Rudimentary example. Yet to think this out.
      @df[:shankar, :vector] = [69,99,108,85,49].dv(:shankar, [:two, :one, :three, :five, :four])

      expect(@df.shankar).to eq([99,69,108,49,85].dv(:shankar, 
        [:one, :two, :three, :four, :five]))
    end

    it "appends multiple vectors at a time" do
      pending "Implement after initialize with array of arrays is done with."

      # Rudimentary example. Yet to think this out.

      @df[:woo, :boo, :vector] = [[69,99,108,85,49].dv(nil, [:one, :two, :three, :four, :five]), 
                         [69,99,108,85,49].dv(nil, [:one, :two, :three, :four, :five])]
    end
  end

  context "#[:row]=" do
    before :each do
      @df = Daru::DataFrame.new({b: [11,12,13,14,15], a: [1,2,3,4,5], 
        c: [11,22,33,44,55]}, [:a, :b, :c], [:one, :two, :three, :four, :five])
    end

    it "assigns specified row when Array" do
      @df.row[:one] = [49, 99, 59]

      expect(@df[:one, :row])      .to eq([49, 99, 59].dv(:one, [:a, :b, :c]))
      expect(@df[:one, :row].index).to eq([:a, :b, :c].to_index)
      expect(@df[:one, :row].name) .to eq(:one)
    end

    it "assigns specified row when DV" do
      @df[:one, :row] = [49, 99, 59].dv(nil, [:a, :b, :c])

      expect(@df[:one, :row]).to eq([49, 99, 59].dv(:one, [:a, :b, :c]))
    end

    it "creates a new row from an Array" do
      @df.row[:patekar] = [9,2,11]

      expect(@df[:patekar, :row]).to eq([9,2,11].dv(:patekar, [:a, :b, :c]))
    end

    it "creates a new row from a DV" do
      @df.row[:patekar] = [9,2,11].dv(nil, [:a, :b, :c])

      expect(@df[:patekar, :row]).to eq([9,2,11].dv(:patekar, [:a, :b, :c]))
    end

    it "raises error for DV assignment with wrong index" do
      expect {
        @df[:two, :row] = [49, 99, 59].dv(nil, [:oo, :aah, :gaah])
      }.to raise_error
    end

    it "raises error for assignment with wrong size" do
      expect {
        @df[:three, :row] = [99, 59].dv(nil, [:aah, :gaah])
      }.to raise_error
    end

    it "returns a DataFrame when mutiple indexes specified" do
      pending "Next release"

      raise
    end

    it "correctly aligns assigned DV by index" do
      pending "Do this once the misalign initialize is done."

      raise
    end
  end

  context "#row" do
    before :each do
      @df = Daru::DataFrame.new({b: [11,12,13,14,15], a: [1,2,3,4,5], 
        c: [11,22,33,44,55]}, [:a, :b, :c], [:one, :two, :three, :four, :five])
    end

    it "creates an index for assignment if not already specified" do
      @df.row[:one] = [49, 99, 59]

      expect(@df[:one, :row])      .to eq([49, 99, 59].dv(:one, [:a, :b, :c]))
      expect(@df[:one, :row].index).to eq([:a, :b, :c].to_index)
      expect(@df[:one, :row].name) .to eq(:one)
    end
  end

  context "#vector" do
    before :each do
      @df = Daru::DataFrame.new({b: [11,12,13,14,15], a: [1,2,3,4,5], 
        c: [11,22,33,44,55]}, [:a, :b, :c], [:one, :two, :three, :four, :five])
    end

    it "appends an Array as a Daru::Vector" do
      @df[:d, :vector] = [69,99,108,85,49]

      expect(@df.d.class).to eq(Daru::Vector)
    end
  end

  context "#==" do
    it "compares by vectors, index and values of a DataFrame (ignores name)" do
      a = Daru::DataFrame.new({b: [11,12,13,14,15], a: [1,2,3,4,5]}, 
        [:a, :b], [:one, :two, :three, :four, :five])

      b = Daru::DataFrame.new({b: [11,12,13,14,15], a: [1,2,3,4,5]}, 
        [:a, :b], [:one, :two, :three, :four, :five])

      expect(a).to eq(b)
    end
  end

  context "#each_vector" do
    it "iterates over all vectors" do
      df = Daru::DataFrame.new({b: [11,12,13,14,15], a: [1,2,3,4,5], 
        c: [11,22,33,44,55]}, [:a, :b, :c], [:one, :two, :three, :four, :five])

      ret = df.each_vector do |vector|
        expect(vector.index).to eq([:one, :two, :three, :four, :five].to_index)
        expect(vector.class).to eq(Daru::Vector) 
      end

      expect(ret).to eq(df)
    end
  end

  context "#each_vector_with_index" do
    it "iterates over vectors with index" do
      df = Daru::DataFrame.new({b: [11,12,13,14,15], a: [1,2,3,4,5], 
        c: [11,22,33,44,55]}, [:a, :b, :c], [:one, :two, :three, :four, :five])

      idxs = []
      ret = df.each_vector_with_index do |vector, index|
        idxs << index
        expect(vector.index).to eq([:one, :two, :three, :four, :five].to_index)
        expect(vector.class).to eq(Daru::Vector) 
      end

      expect(idxs).to eq([:a, :b, :c])

      expect(ret).to eq(df)
    end
  end

  context "#each_row" do
    it "iterates over rows" do
      df = Daru::DataFrame.new({b: [11,12,13,14,15], a: [1,2,3,4,5], 
        c: [11,22,33,44,55]}, [:a, :b, :c], [:one, :two, :three, :four, :five])

      ret = df.each_row do |row|
        expect(row.index).to eq([:a, :b, :c].to_index)
        expect(row.class).to eq(Daru::Vector)
      end

      expect(ret).to eq(df)
    end
  end

  context "#each_row_with_index" do
    it "iterates over rows with indexes" do
      df = Daru::DataFrame.new({b: [11,12,13,14,15], a: [1,2,3,4,5], 
        c: [11,22,33,44,55]}, [:a, :b, :c], [:one, :two, :three, :four, :five])

      idxs = []
      ret = df.each_row do |row, idx|
        idxs << idx
        expect(row.index).to eq([:a, :b, :c].to_index)
        expect(row.class).to eq(Daru::Vector)
      end

      expect(idxs).to eq([:one, :two, :three, :four, :five])
      expect(ret) .to eq(df)
    end
  end

  context "#map_rows" do
  end

  context "#map_rows_with_index" do
  end

  context "#map_vectors" do
  end

  context "#map_vectors_with_index" do
  end
end if RUBY_ENGINE == 'ruby'