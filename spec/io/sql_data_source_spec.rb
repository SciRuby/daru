require 'daru/io/sql_data_source'
require 'sqlite3'
require 'dbi'
require 'active_record'

RSpec.describe Daru::IO::SqlDataSource do
  include_context 'with accounts table in sqlite3 database'
  let(:dbi_handle) do
    DBI.connect("DBI:SQLite3:#{db_name}")
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
      subject(:df) { Daru::IO::SqlDataSource.make_dataframe(dbi_handle, query) }
      it { is_expected.to be_a(Daru::DataFrame) }
      it { expect(df.nrows).to eq 2 }
      it { expect(df.row[0][:id]).to eq 1 }
      it { expect(df.row[0][:name]).to eq 'Homer' }

    end

    context 'with ActiveRecord::Connection' do
      subject(:df) { Daru::IO::SqlDataSource.make_dataframe(active_record_connection, query) }
      it { is_expected.to be_a(Daru::DataFrame) }
      it { expect(df.nrows).to eq 2 }
      it { expect(df.row[0][:id]).to eq 1 }
      it { expect(df.row[0][:name]).to eq 'Homer' }
    end

    context 'with path to sqlite3 file' do
      subject(:df) { Daru::IO::SqlDataSource.make_dataframe(db_name, query) }
      it { is_expected.to be_a(Daru::DataFrame) }
      it { expect(df.nrows).to eq 2 }
      it { expect(df.row[0][:id]).to eq 1 }
      it { expect(df.row[0][:name]).to eq 'Homer' }
    end

    context 'with an object not a string as a query' do
      it {
        expect {
          Daru::IO::SqlDataSource.make_dataframe(active_record_connection, Object.new)
        }.to raise_error(ArgumentError)
      }
    end

    context 'with an object not a database connection' do
      it {
        expect {
          Daru::IO::SqlDataSource.make_dataframe(Object.new, query)
        }.to raise_error(ArgumentError)
      }
    end

    context 'with path to unsupported db file' do
      it {
        expect {
          Daru::IO::SqlDataSource.make_dataframe("spec/fixtures/bank2.dat", query)
        }.to raise_error(ArgumentError)
      }
    end
  end
end
