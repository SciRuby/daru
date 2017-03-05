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
        expect(df.vectors.to_a).to eq(["id", "name_1", "age_1", "city", "a1", "name_2", "age_2"])

        age = Daru::Vector.new([3, 4, 5, 6, nil, 8])
        expect(df['age_2']).to eq(age)
      end

      it "accepts scientific notation as float" do
        ds = Daru::DataFrame.from_csv('spec/fixtures/scientific_notation.csv', order: ['x', 'y'])
        expect(ds.vectors.to_a).to eq(['x', 'y'])
        y = [9.629587310436753e+127, 1.9341543147883677e+129, 3.88485279048245e+130]
        y.zip(ds['y']).each do |y_expected, y_ds|
          expect(y_ds).to be_within(0.001).of(y_expected)
        end
      end

      it "follows the order of columns given in CSV" do
        df = Daru::DataFrame.from_csv 'spec/fixtures/sales-funnel.csv'
        expect(df.vectors.to_a).to eq(%W[Account Name Rep Manager Product Quantity Price Status])
      end
    end

    context "#write_csv" do
      before do
        @df = Daru::DataFrame.new({
          'a' => [1,2,3,4,5],
          'b' => [11,22,33,44,55],
          'c' => ['a', 'g', 4, 5,'addadf'],
          'd' => [nil, 23, 4,'a','ff']})
        @tempfile = Tempfile.new('data.csv')

      end

      it "writes DataFrame to a CSV file" do
        @df.write_csv @tempfile.path
        expect(Daru::DataFrame.from_csv(@tempfile.path)).to eq(@df)
      end

      it "will write headers unless headers=false" do
        @df.write_csv @tempfile.path
        first_line = File.open(@tempfile.path, &:readline).chomp.split(',', -1)
        expect(first_line).to eq @df.vectors.to_a
      end

      it "will not write headers when headers=false" do
        @df.write_csv @tempfile.path, { headers: false }
        first_line = File.open(@tempfile.path, &:readline).chomp.split(',', -1)
        expect(first_line).to eq @df.head(1).map { |v| (v.first || '').to_s }
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
      include_context 'with accounts table in sqlite3 database'

      context 'with a database handler of DBI' do
        let(:db) do
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
          Daru::RSpec::Account.establish_connection "sqlite3:#{db_name}"
          Daru::RSpec::Account.connection
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
      let(:df) { Daru::DataFrame.new({
          'a' => [1,2,3,4,5],
          'b' => [11,22,33,44,55],
          'c' => ['a', 'g', 4, 5,'addadf'],
          'd' => [nil, 23, 4,'a','ff']})
      }

      let(:dbh) { double }
      let(:prepared_query) { double }

      it "writes the DataFrame to an SQL database" do
        expect(dbh).to receive(:prepare)
          .with('INSERT INTO tbl (a,b,c,d) VALUES (?,?,?,?)')
          .and_return(prepared_query)
        df.each_row { |r| expect(prepared_query).to receive(:execute).with(*r.to_a).ordered }

        df.write_sql dbh, 'tbl'
      end
    end

    context '.from_activerecord' do
      include_context 'with accounts table in sqlite3 database'

      context 'with ActiveRecord::Relation' do
        before do
          Daru::RSpec::Account.establish_connection "sqlite3:#{db_name}"
        end

        let(:relation) do
          Daru::RSpec::Account.all
        end

        context 'without specifying field names' do
          subject do
            Daru::DataFrame.from_activerecord(relation)
          end

          it 'loads data from an AR::Relation object' do
            accounts = subject
            expect(accounts.class).to eq Daru::DataFrame
            expect(accounts.nrows).to eq 2
            expect(accounts.vectors.to_a).to eq [:id, :name, :age]
            expect(accounts.row[0][:id]).to eq 1
            expect(accounts.row[0][:name]).to eq 'Homer'
            expect(accounts.row[0][:age]).to eq 20
          end
        end

        context 'with specifying field names in parameters' do
          subject do
            Daru::DataFrame.from_activerecord(relation, :name, :age)
          end

          it 'loads data from an AR::Relation object' do
            accounts = subject
            expect(accounts.class).to eq Daru::DataFrame
            expect(accounts.nrows).to eq 2
            expect(accounts.vectors.to_a).to eq [:name, :age]
            expect(accounts.row[0][:name]).to eq 'Homer'
            expect(accounts.row[0][:age]).to eq 20
          end
        end
      end
    end

    context ".from_plaintext" do
      it "reads data from plain text files" do
        df = Daru::DataFrame.from_plaintext 'spec/fixtures/bank2.dat', [:v1,:v2,:v3,:v4,:v5,:v6]

        expect(df.vectors.to_a).to eq([:v1,:v2,:v3,:v4,:v5,:v6])
      end

      xit "understands empty fields" do
        pending 'See FIXME note in io.rb'

        df = Daru::DataFrame.from_plaintext 'spec/fixtures/empties.dat', [:v1,:v2,:v3]

        expect(df.row[1].to_a).to eq [4, nil, 6]
      end

      it "understands non-numeric fields" do
        df = Daru::DataFrame.from_plaintext 'spec/fixtures/strings.dat', [:v1,:v2,:v3]

        expect(df[:v1].to_a).to eq ['test', 'foo']
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

    context "#from_html" do
      let(:path) { path = "file://#{Dir.pwd}/spec/fixtures/wiki_table_info.html" }

      it "reads table from html file into dataframe - test table 1" do
        df = Daru::DataFrame.from_html(path)[0]
        expect(df).to eq(Daru::DataFrame.new(
            [["Tinu", "Blaszczyk", "Lily", "Olatunkboh", "Adrienne", "Axelia", "Jon-Kabat"],
            ["Elejogun", "Kostrzewski", "McGarrett", "Chijiaku", "Anthoula", "Athanasios", "Zinn"],
            ["14", "25", "16", "22", "22", "22", "22"]], 
            order: ["First name","Last name","Age"], 
            name: "Age table"
          )
        )
      end

      it "reads table with options from html file into dataframe - test table 1" do
        df = Daru::DataFrame.from_html(path, order: ["FName","LName","Age"], name: "People Table")[0]
        expect(df).to eq(Daru::DataFrame.new(
            [["Tinu", "Blaszczyk", "Lily", "Olatunkboh", "Adrienne", "Axelia", "Jon-Kabat"],
            ["Elejogun", "Kostrzewski", "McGarrett", "Chijiaku", "Anthoula", "Athanasios", "Zinn"],
            ["14", "25", "16", "22", "22", "22", "22"]], 
            order: ["FName","LName","Age"], 
            name: "People table"
          )
        )
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
