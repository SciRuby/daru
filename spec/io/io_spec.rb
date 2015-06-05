require 'spec_helper.rb'

describe Daru::IO do
  describe Daru::DataFrame do
    context ".from_csv" do
      it "loads from a CSV file" do
        df = Daru::DataFrame.from_csv('spec/fixtures/matrix_test.csv', 
          col_sep: ' ', headers: true)

        expect(df.vectors).to eq([:image_resolution, :mls, :true_transform].to_index)
        expect(df.vector[:image_resolution].first).to eq(6.55779)
        expect(df.vector[:true_transform].first).to eq("-0.2362347,0.6308649,0.7390552,0,0.6523478,-0.4607318,0.6018043,0,0.7201635,0.6242881,-0.3027024,4262.65,0,0,0,1")
      end
    end

    context "#write_csv" do
      it "writes DataFrame to a CSV file" do
        df = Daru::DataFrame.new({
          a: [1,2,3,4,5], 
          b: [11,22,33,44,55],
          c: ['a', 'g', 4, 5,'addadf'],
          d: [nil, 23, 4,'a','ff',44]})
        t = Tempfile.new('data.csv')
        df.write_csv t.path

        expect(Daru::DataFrame.from_csv(t.path)).to eq(df)
      end
    end

    context ".from_excel" do
      it "loads DataFrame from an Excel Spreadsheet" do
      end
    end

    context "#write_excel" do
      it "writes DataFrame to an Excel Spreadsheet" do
      end
    end

    context ".from_sql" do
    end

    context "#write_sql" do
    end

    context "JSON" do
      it "loads parsed JSON" do
        require 'json'

        json = File.read 'spec/fixtures/countries.json'
        df   = Daru::DataFrame.new JSON.parse(json)

        expect(df.vectors).to eq([
          :name, :nativeName, :tld, :cca2, :ccn3, :cca3, :currency, :callingCode, 
          :capital, :altSpellings, :relevance, :region, :subregion, :language, 
          :languageCodes, :translations, :latlng, :demonym, :borders, :area].to_index)

        expect(df.row[0][:name]).to eq("Afghanistan")
      end
    end

    context "Marshalling" do
      it "" do
        vector = Daru::Vector.new (0..100).collect { |_n| rand(100) }
        dataframe = Daru::Vector.new({a: vector, b: vector, c: vector})
        expect(Marshal.load(Marshal.dump(dataframe))).to eq(dataframe)
      end
    end

    context "#save" do
      before do
        @data_frame = Daru::DataFrame.new({b: [11,12,13,14,15], a: [1,2,3,4,5], 
          c: [11,22,33,44,55]}, 
          order: [:a, :b, :c], 
          index: [:one, :two, :three, :four, :five])
      end

      it "saves df to a file" do
        outfile = Tempfile.new('dataframe.df')
        @data_frame.save(outfile.path)
        a = Daru::IO.load(outfile.path)
        expect(a).to eq(@data_frame)
      end
    end
  end

  describe Daru::Vector do
    context "Marshalling" do
      it "" do
        vector = Daru::Vector.new (0..100).collect { |_n| rand(100) }
        expect(Marshal.load(Marshal.dump(vector))).to eq(vector)
      end
    end

    context "#save" do
      ALL_DTYPES.each do |dtype|
        it "saves to a file and returns the same Vector of type #{dtype}" do
          vector = Daru::Vector.new(
              [5, 5, 5, 5, 5, 6, 6, 7, 8, 9, 10, 1, 2, 3, 4, 11, -99, -99], 
              dtype: dtype)
          outfile = Tempfile.new('vector.vec')
          vector.save(outfile.path)
          expect(Daru::IO.load(outfile.path)).to eq(vector)
        end
      end
    end
  end

  describe Daru::Index do
    context "Marshalling" do
      it "" do
        i = Daru::Index.new([:a, :b, :c, :d, :e], [8,6,4,3,5])
        expect(Marshal.load(Marshal.dump(i))).to eq(i)
      end
    end
  end
end
