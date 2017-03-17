require 'daru/io/sql_data_source'
require 'sqlite3'
require 'dbi'
require 'active_record'

RSpec.describe Daru::IO::SqlDataSource do
  include_context 'with accounts table in sqlite3 database'

  let(:query) do
    'select * from accounts'
  end

  let(:source) do
    ActiveRecord::Base.establish_connection("sqlite3:#{db_name}")
    ActiveRecord::Base.connection
  end

  describe '.make_dataframe' do
    subject(:df) { Daru::IO::SqlDataSource.make_dataframe(source, query) }

    context 'with DBI::DatabaseHandle' do
      let(:source) { DBI.connect("DBI:SQLite3:#{db_name}") }
      it { is_expected.to be_a(Daru::DataFrame) }
      it { expect(df.row[0]).to have_attributes(id: 1, age: 20) }
      its(:nrows) { is_expected.to eq 2 }
    end

    context 'with ActiveRecord::Connection' do
      it { is_expected.to be_a(Daru::DataFrame) }
      it { expect(df.row[0]).to have_attributes(id: 1, age: 20) }
      its(:nrows) { is_expected.to eq 2 }
    end

    context 'with path to sqlite3 file' do
      let(:source) { db_name }
      it { is_expected.to be_a(Daru::DataFrame) }
      it { expect(df.row[0]).to have_attributes(id: 1, age: 20) }
      its(:nrows) { is_expected.to eq 2 }
    end

    context 'with an object not a string as a query' do
      let(:query) { Object.new }
      it { expect { df }.to raise_error(ArgumentError) }
    end

    context 'with an object not a database connection' do
      let(:source) { Object.new }
      it { expect { df }.to raise_error(ArgumentError) }
    end

    context 'with path to unsupported db file' do
      let(:source) { 'spec/fixtures/bank2.dat' }
      it { expect { df }.to raise_error(ArgumentError) }
    end
  end
end
