require 'spec_helper.rb'

describe Daru::DataFrame do
  context "DataFrame from normal array vectors" do
    
    before :each do
      @df = Daru::DataFrame.new({a: Daru::Vector.new(1..3), 
        b: (50..52).daru_vector, b_bad: ['Jesse', 'Walter', 'Hank'].daru_vector})

      @vector = Daru::Vector.new 1..3, :a
    end

    it "checks for the size of DataFrame" do
      expect(@df.size).to eq(3)
    end

    it "raises exception for eneven vectors" do
      expect do
        df = Daru::DataFrame.new({a: (1..5).daru_vector, b: [1,2,3].daru_vector})
      end.to raise_error
    end

    it "returns vector by specifying as method" do
      expect(@df.a).to eq(@vector)
    end

    it "returns vector by specifying as index" do
      expect(@df[:a]).to eq(@vector)
    end

    it "returns vector by specifying as a column argument" do
      expect(@df.column(:a)).to eq(@vector)
    end

    it "iterates over columns" do
      @df.each_column do |col|
        expect(col.is_a?(Daru::Vector)).to be(true)
        expect([:a, :b, :b_bad].include? col.name).to be(true)
      end
    end

    it "iterates over rows" do 
      @df.each_row do |row|
        expect(row[0].nil?).to be(false)
      end
    end

    it "shows column fields" do
      expect(@df.fields).to eq([:a, :b, :b_bad])
    end

    it "inserts a new vector" do
      @df.insert_vector({c: Daru::Vector.new([3,6,9]) })

      expect(@df.fields.include?(:c)).to be(true)
    end

    it "inserts a new row" do
      @df.insert_row [6,6,"Fred",6]

      expect(@df.a.vector)    .to eq([1,2,3,6])
      expect(@df.b.vector)    .to eq([51,52,53,6])
      expect(@df.b_bad.vector).to eq(['Jesse', 'Walter', 'Hank', 'Fred'])
      expect(@df.c.vector)    .to eq([3,6,9,6])
    end

    it "raises an error for inappropriate row insertion" do
      expect { @df.insert_row [1,1] }.to raise_error
    end

    it "deletes a column" do
      @df.delete(:c)

      expect(@df.fields.include?(:c)).to be(false)
    end
  end

  context "DataFrame loads from files" do
    it "loads a DataFrame from CSV" do
      df = Daru::DataFrame.from_csv 'fixtures/test_matrix.csv'
    end
  end

  # context "DataFrame from NMatrix vectors" do
  # end
end if RUBY_ENGINE == 'ruby'