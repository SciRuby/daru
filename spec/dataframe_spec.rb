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
      pending "Implement creation of DataFrame from unequal vectors by inserting nils into resulting DataFrame"
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

  context "#[]" do
    before :each do
      @df = Daru::DataFrame.new({b: [11,12,13,14,15], a: [1,2,3,4,5], 
        c: [11,22,33,44,55]}, [:a, :b, :c], [:one, :two, :three, :four, :five])
    end

    it "returns a Vector" do
      expect(@df[:a]).to eq([1,2,3,4,5].dv(:a, [:one, :two, :three, :four, :five]))
    end

    it "returns a DataFrame" do
      temp = Daru::DataFrame.new({b: [11,12,13,14,15], a: [1,2,3,4,5]}, 
        [:a, :b], [:one, :two, :three, :four, :five])

      puts @df[:a, :b]

      expect(@df[:a, :b]).to eq(temp)
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

  context "#[]=" do
    before :each do
      @df = Daru::DataFrame.new({b: [11,12,13,14,15], a: [1,2,3,4,5], 
        c: [11,22,33,44,55]}, [:a, :b, :c], [:one, :two, :three, :four, :five])
    end

    it "appends an Array as a Daru::Vector" do
      @df[:d] = [69,99,108,85,49]

      expect(@df.d.class).to eq(Daru::Vector)
    end

    it "replaces an already present vector" do
      @df[:a] = [69,99,108,85,49].dv(nil, [:one, :two, :three, :four, :five])

      expect(@df.a).to eq([69,99,108,85,49].dv(nil, [:one, :two, :three, :four, :five]))
    end

    it "appends a new vector to the DataFrame" do
      @df[:woo] = [69,99,108,85,49].dv(nil, [:one, :two, :three, :four, :five])

      expect(@df.vectors).to eq([:a, :b, :c, :woo].to_index)
    end

    it "creates an index for the new vector if not specified" do
      @df[:woo] = [69,99,108,85,49]

      expect(@df.woo.index).to eq([:one, :two, :three, :four, :five].to_index)
    end

    it "raises error if index mismatch between DataFrame and new vector(s)" do
      expect {
        @df[:woo] = [69,99,108,85,49].dv
      }.to raise_error

      # TODO: Remove this. Must work for mismatched indexes.
    end    

    it "inserts vector of same length as DataFrame but of different index" do
      pending "Implement after adding constructor for DataFrame from vectors with \ 
        unequal index."
    end

    it "appends multiple vectors at a time" do
      @df[:woo, :boo] = [[69,99,108,85,49].dv(nil, [:one, :two, :three, :four, :five]), 
                         [69,99,108,85,49].dv(nil, [:one, :two, :three, :four, :five])]

      pending "Implement after basic stuff is done with."
    end
  end
end if RUBY_ENGINE == 'ruby'