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

  let(:dat_file) do
    'spec/fixtures/bank2.dat'
  end

  let(:query) do
    'select * from accounts'
  end

  let(:source) do
    active_record_connection
  end

  describe '.make_dataframe' do
    subject(:df) { Daru::IO::SqlDataSource.make_dataframe(source, query) }

    context 'with DBI::DatabaseHandle' do
      let(:source) { dbi_handle }
      it { is_expected.to be_a(Daru::DataFrame) }
      it { expect(df.row[0]).to have_attributes(id: 1) }
      it { expect(df.row[0]).to have_attributes(age: 20) }
      its(:nrows) { is_expected.to eq 2 }
    end

    context 'with ActiveRecord::Connection' do
      let(:source) { active_record_connection }
      it { is_expected.to be_a(Daru::DataFrame) }
      it { expect(df.row[0]).to have_attributes(id: 1) }
      it { expect(df.row[0]).to have_attributes(age: 20) }
      its(:nrows) { is_expected.to eq 2 }
    end

    context 'with path to sqlite3 file' do
      let(:source) { db_name }
      it { is_expected.to be_a(Daru::DataFrame) }
      it { expect(df.row[0]).to have_attributes(id: 1) }
      it { expect(df.row[0]).to have_attributes(age: 20) }
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
      let(:source) { dat_file }
      it { expect { df }.to raise_error(ArgumentError) }
    end
  end
end
