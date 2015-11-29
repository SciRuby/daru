require 'spec_helper'
require 'daru/io/sql_data_source'
require 'sqlite3'
require 'dbi'
require 'active_record'

RSpec.describe Daru::IO::SqlDataSource do
  let(:db_name) do
    'daru_test'
  end

  before do
    # just in case
    FileUtils.rm(db_name) if File.file?(db_name)

    SQLite3::Database.new(db_name).tap do |db|
      db.execute "create table accounts(id integer, name varchar)"
      db.execute "insert into accounts values(1, 'Homer')"
      db.execute "insert into accounts values(2, 'Marge')"
    end
  end

  after do
    FileUtils.rm(db_name)
  end

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

    context 'with DBI::DatabaseHandle' do
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
  end
end
