require 'spec_helper.rb'

describe Daru::IO do
  describe Daru::DataFrame do
    context ".from_csv" do
      it "loads from a CSV file" do
        df = Daru::DataFrame.from_csv('spec/fixtures/matrix_test.csv', 
          col_sep: ' ', headers: true)

        df.vectors = [:image_resolution, :mls, :true_transform].to_index
        expect(df.vectors).to eq([:image_resolution, :mls, :true_transform].to_index)
        expect(df[:image_resolution].first).to eq(6.55779)
        expect(df[:true_transform].first).to eq("-0.2362347,0.6308649,0.7390552,0,0.6523478,-0.4607318,0.6018043,0,0.7201635,0.6242881,-0.3027024,4262.65,0,0,0,1")
      end

      it "works properly for repeated headers" do
        df = Daru::DataFrame.from_csv('spec/fixtures/repeated_fields.csv',header_converters: :symbol)
        expect(df.vectors.to_a).to eq(['a1', 'age_1', 'age_2', 'city', 'id', 'name_1', 'name_2'])

        age = Daru::Vector.new([3, 4, 5, 6, nil, 8])
        expect(df['age_2']).to eq(age)
      end

      it "accepts scientific notation as float" do
        ds = Daru::DataFrame.from_csv('spec/fixtures/scientific_notation.csv')
        expect(ds.vectors.to_a).to eq(['x', 'y'])
        y = [9.629587310436753e+127, 1.9341543147883677e+129, 3.88485279048245e+130]
        y.zip(ds['y']).each do |y_expected, y_ds|
          expect(y_ds).to be_within(0.001).of(y_expected)
        end
      end
    end

    context "#write_csv" do
      it "writes DataFrame to a CSV file" do
        df = Daru::DataFrame.new({
          'a' => [1,2,3,4,5], 
          'b' => [11,22,33,44,55],
          'c' => ['a', 'g', 4, 5,'addadf'],
          'd' => [nil, 23, 4,'a','ff']})
        t = Tempfile.new('data.csv')
        df.write_csv t.path

        expect(Daru::DataFrame.from_csv(t.path)).to eq(df)
      end
    end

    context ".from_excel" do
      before do
        id   = Daru::Vector.new([1, 2, 3, 4, 5, 6])
        name = Daru::Vector.new(%w(Alex Claude Peter Franz George Fernand))
        age  = Daru::Vector.new( [20, 23, 25, nil, 5.5, nil])
        city = Daru::Vector.new(['New York', 'London', 'London', 'Paris', 'Tome', nil])
        a1   = Daru::Vector.new(['a,b', 'b,c', 'a', nil, 'a,b,c', nil])
        @expected = Daru::DataFrame.new({ 
          :id => id, :name => name, :age => age, :city => city, :a1 => a1 
          }, order: [:id, :name, :age, :city, :a1])
      end

      it "loads DataFrame from an Excel Spreadsheet" do
        df = Daru::DataFrame.from_excel 'spec/fixtures/test_xls.xls'

        expect(df.nrows).to eq(6)
        expect(df.vectors.to_a).to eq([:id, :name, :age, :city, :a1])
        expect(df[:age][5]).to eq(nil)
        expect(@expected).to eq(df)
      end
    end

    context "#write_excel" do
      before do
        a   = Daru::Vector.new(100.times.map { rand(100) })
        b   = Daru::Vector.new((['b'] * 100))
        @expected = Daru::DataFrame.new({ :b => b, :a => a })

        tempfile = Tempfile.new('test_write.xls')

        @expected.write_excel tempfile.path
        @df = Daru::DataFrame.from_excel tempfile.path
      end

      it "correctly writes DataFrame to an Excel Spreadsheet" do
        expect(@expected).to eq(@df)
      end
    end

    context ".from_sql" do
      let(:db_name) do
        'daru_test'
      end

      before do
        require 'sqlite3'
        SQLite3::Database.new(db_name).tap do |db|
          db.execute "create table accounts(id integer, name varchar)"
          db.execute "insert into accounts values(1, 'Homer')"
          db.execute "insert into accounts values(2, 'Marge')"
        end
      end

      after do
        FileUtils.rm(db_name)
      end

      context 'with a database handler of DBI' do
        let(:db) do
          require "dbi"
          DBI.connect("DBI:SQLite3:#{db_name}")
        end

        subject { Daru::DataFrame.from_sql(db, "select * from accounts") }

        it "loads data from an SQL database" do
          accounts = subject
          expect(accounts.class).to eq Daru::DataFrame
          expect(accounts.nrows).to eq 2
          expect(accounts.row[0][:id]).to eq 1
          expect(accounts.row[0][:name]).to eq "Homer"
        end
      end

      context 'with a database connection of ActiveRecord' do
        let(:connection) do
          require 'active_record'
          ActiveRecord::Base.establish_connection("sqlite3:#{db_name}")
          ActiveRecord::Base.connection
        end

        subject do
          Daru::DataFrame.from_sql(connection, "select * from accounts")
        end

        it "loads data from an SQL database" do
          accounts = subject
          expect(accounts.class).to eq Daru::DataFrame
          expect(accounts.nrows).to eq 2
          expect(accounts.row[0][:id]).to eq 1
          expect(accounts.row[0][:name]).to eq "Homer"
        end
      end
    end

    context "#write_sql" do
      it "writes the DataFrame to an SQL database" do
        # TODO: write these tests
      end
    end

    context ".from_plaintext" do
      it "reads data from plain text files" do
        df = Daru::DataFrame.from_plaintext 'spec/fixtures/bank2.dat', [:v1,:v2,:v3,:v4,:v5,:v6]

        expect(df.vectors.to_a).to eq([:v1,:v2,:v3,:v4,:v5,:v6])
      end
    end

    context "JSON" do
      it "loads parsed JSON" do
        require 'json'

        json = File.read 'spec/fixtures/countries.json'
        df   = Daru::DataFrame.new JSON.parse(json)

        expect(df.vectors).to eq([
          'name', 'nativeName', 'tld', 'cca2', 'ccn3', 'cca3', 'currency', 'callingCode', 
          'capital', 'altSpellings', 'relevance', 'region', 'subregion', 'language', 
          'languageCodes', 'translations', 'latlng', 'demonym', 'borders', 'area'].to_index)

        expect(df.row[0]['name']).to eq("Afghanistan")
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
        i = Daru::Index.new([:a, :b, :c, :d, :e])
        expect(Marshal.load(Marshal.dump(i))).to eq(i)
      end
    end
  end
end
