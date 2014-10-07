require 'spec_helper.rb'

describe Daru::DataFrame do
  context "DataFrame from normal array vectors" do
    
    before :each do
      @df = Daru::DataFrame.new({a: Daru::Vector.new(1..5, :yolo), 
        b: (50..80).daru_vector, b_bad: ['Jesse', 'Walter', 'Hank'].daru_vector})

      @vector = Daru::Vector.new 1..3, :a
    end

    it "destructively cuts all vectors to the vector of shortest length" do
      expect(@df.b_bad.size).to eq(3)
      expect(@df.b.size).to eq(3)
      expect(@df.a.size).to eq(3)
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
        # TODO: What here?
      end
    end

    it "shows column labels" do
    end

    it "inserts a new vector" do
      @df.insert_vector(Daru::Vector.new [3,6,9], :c)

      expect(@df.fields.include?(:c)).to be(true)
    end

    it "inserts a new row" do
    end

    it "raises an error for inappropriate row insertion" do
    end

    it "deletes a column" do
    end
  end

  context "DataFrame loads from files" do
    it "loads a DataFrame from CSV" do
    end
  end

  # context "DataFrame from NMatrix vectors" do
  # end
end if RUBY_ENGINE == 'ruby'