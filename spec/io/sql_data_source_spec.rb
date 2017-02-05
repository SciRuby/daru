require 'daru/io/sql_data_source'
require 'sqlite3'
require 'dbi'
require 'active_record'

RSpec.describe Daru::IO::SqlDataSource do
  include_context 'with accounts table in sqlite3 database'
  let(:dbi_handle) do
    DBI.connect("DBI:SQLite3:#{db_name}")
  end

  let(:db_file) do
    'spec/fixtures/names.db'
  end

  let(:active_record_connection) do
    ActiveRecord::Base.establish_connection("sqlite3:#{db_name}")
    ActiveRecord::Base.connection
  end

  let(:query) do
    'select * from accounts'
  end

  describe '.make_dataframe' do
    context 'with DBI::DatabaseHandle' do
      it 'returns a dataframe' do
        result = Daru::IO::SqlDataSource.make_dataframe(dbi_handle, query)
        expect(result).to be_a(Daru::DataFrame)
        expect(result.nrows).to eq(2)
        expect(result.row[0][:id]).to eq(1)
        expect(result.row[0][:name]).to eq('Homer')
      end

      context 'with an object not a string as a query' do
        it 'raises ArgumentError' do
          expect {
            Daru::IO::SqlDataSource.make_dataframe(dbi_handle, Object.new)
          }.to raise_error(ArgumentError)
        end
      end
    end

    context 'with ActiveRecord::Connection' do
      it 'returns a dataframe' do
        result = Daru::IO::SqlDataSource.make_dataframe(active_record_connection, query)
        expect(result).to be_a(Daru::DataFrame)
        expect(result.nrows).to eq(2)
        expect(result.row[0][:id]).to eq(1)
        expect(result.row[0][:name]).to eq('Homer')
      end

      context 'with an object not a string as a query' do
        it 'raises ArgumentError' do
          expect {
            Daru::IO::SqlDataSource.make_dataframe(active_record_connection, Object.new)
          }.to raise_error(ArgumentError)
        end
      end
    end

    context 'with an object not a database connection' do
      it 'raises ArgumentError' do
        expect {
          Daru::IO::SqlDataSource.make_dataframe(Object.new, query)
        }.to raise_error(ArgumentError)
      end
    end

    context 'with database file path' do
      it 'returns a dataframe' do
        result = Daru::IO::SqlDataSource.make_dataframe(db_file, query)
        expect(result).to be_a(Daru::DataFrame)
        expect(result.row[0][:id]).to eq(1)
        expect(result.row[0][:name]).to eq('Alex')
      end
      it 'raises ArgumentError' do
        expect {
          Daru::IO::SqlDataSource.make_dataframe("spec/fixtures/bank2.dat", query)
        }.to raise_error(ArgumentError)
      end
    end
  end
end
