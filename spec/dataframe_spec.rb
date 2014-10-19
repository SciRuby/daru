require 'spec_helper.rb'

describe Daru::DataFrame do
  context "#initialize" do
    it "initializes an empty DataFrame", :focus => true do
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
      df = Daru::DataFrame.new({b: [11,12,13,14,15].dv, a: [1,2,3,4,5].dv}, [:a, :b],
        [:one, :two, :three, :four, :five])

      expect(df.index)  .to eq(Daru::Index.new [:one, :two, :three, :four, :five])
      expect(df.vectors).to eq(Daru::Index.new [:a, :b])
      expect(df.a.class).to eq(Daru::Vector)
      expect(df.a)      .to eq([1,2,3,4,5].dv(:a)) 
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

      expect(df.a)      .to eq(Daru::Vector.new(:a,  [1,2,3,4,5]     , rows))
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
      pending
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
  end

  context "#[]" do
    before :each do
      @df = Daru::DataFrame.new({b: [11,12,13,14,15], a: [1,2,3,4,5], 
        c: [11,22,33,44,55]}, [:a, :b, :c], [:one, :two, :three, :four, :five])
    end

    it "returns a Vector" do
      expect(@df[:a]).to eq([1,2,3,4,5].dv(:a))
    end

    it "returns a DataFrame" do
      temp = Daru::DataFrame.new({b: [11,12,13,14,15], a: [1,2,3,4,5]}, 
        [:a, :b], [:one, :two, :three, :four, :five])

      expect(@df[:a, :b]).eq(temp)
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
end if RUBY_ENGINE == 'ruby'