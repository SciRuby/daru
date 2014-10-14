require 'spec_helper.rb'

describe Daru::DataFrame do
  context "DataFrame of Array" do
    
    before :each do
      @df = Daru::DataFrame.new({a: Daru::Vector.new(1..3), 
        b: (50..52).daru_vector, b_bad: ['Jesse', 'Walter', 'Hank'].daru_vector}, 
        [:b_bad, :a, :b], :muddler)

      @vector = Daru::Vector.new 1..3, :a
    end

    it "checks for the size of DataFrame" do
      expect(@df.size).to eq(3)
    end

    it "raises exception for uneven vectors" do
      expect do
        df = Daru::DataFrame.new({a: (1..5).dv, b: [1,2,3].daru_vector})
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

    it "returns a row" do
      r = @df.row 0

      expect(r).to eq({:b_bad=> "Jesse", :a=> 1, :b=> 50})
    end

    it "iterates over columns in the specified order" do
      cols = []
      df = @df.each_vector do |col|
        expect(col.is_a?(Daru::Vector)).to be(true)
        cols << col.name
      end

      expect(cols).to eq([:b_bad, :a, :b])
      expect(df).to eq(@df)
    end

    it "iterates over rows" do
      @df.each_row do |row|
        expect(row.size).to be(@df.fields.size)
      end
    end

    it "filters rows" do
      res = @df.filter_rows(@df.name) { |row| row[:b] == 50 }

      expect(res).to eq(Daru::DataFrame.new({a: [1].dv, b: [50].dv, b_bad: ['Jesse'].dv}, 
        @df.fields, @df.name))
    end

    it "shows column fields" do
      expect(@df.fields).to eq([:b_bad, :a, :b])
    end

    it "inserts a new vector" do
      @df.insert_vector :c, Daru::Vector.new([3,6,9])

      expect(@df.fields.include?(:c)).to be(true)
    end

    it "inserts a new row" do
      @df.insert_row ["Fred",6, 6]

      expect(@df.a.vector)    .to eq([1,2,3,6])
      expect(@df.b.vector)    .to eq([50,51,52,6])
      expect(@df.b_bad.vector).to eq(['Jesse', 'Walter', 'Hank', 'Fred'])
    end

    it "raises an error for inappropriate row insertion" do
      expect { @df.insert_row [1,1] }.to raise_error
    end

    it "deletes a vector" do
      @df.delete :a

      expect(@df.fields.include? :a).to be(false)
    end

    it "returns a DataFrame of requested fields" do
      req = @df = Daru::DataFrame.new({a: Daru::Vector.new(1..3), 
        b: (50..52).daru_vector}, [:a, :b], :muddler)

      expect(@df[:a, :b]).to eq(req)
    end

    it "creates DataFrame from Array" do
      a_df = Daru::DataFrame.new({a: [1,2,3,4], b: [10,11,12,13]})

      expect(a_df.a.is_a? Daru::Vector).to eq(true)
      expect(a_df.a.vector).to eq([1,2,3,4])
    end
  end

  context "Malformed DataFrame from Array" do
    it "adds extra nil vectors from fields" do
      df = Daru::DataFrame.new({a: (1..4).dv, b: (50..53).dv}, [:b, :a, :jazzy, :joe])

      expect(df.fields).to eq([:b, :a, :jazzy, :joe])
      expect(df.jazzy).to eq(([nil]*4).dv(:jazzy))
      expect(df.joe).to eq(([nil]*4).dv(:joe))
    end
  end

  context "DataFrame from files" do

    it "loads a DataFrame from CSV" do
      df = Daru::DataFrame.from_csv('spec/fixtures/matrix_test.csv', 
        {col_sep: ' ', headers: true}) do |csv|
        csv.convert do |field, info|
          case info[:header]
          when :true_transform
            field.split(',').map { |s| s.to_f }
          else
            field
          end
        end
      end

      expect(df.fields).to eq([:image_resolution, :true_transform, :mls])
      expect(df[:image_resolution].first).to eq(6.55779)
      expect(df.column(:true_transform).first[15]).to eq(1.0)
    end

    it "loads data from JSON" , :focus => true do
      require 'json'
      file = File.read 'spec/fixtures/countries.json'

      df = Daru::DataFrame.new JSON.parse(file)
    end
  end
end if RUBY_ENGINE == 'ruby'