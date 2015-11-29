require 'sqlite3'
require 'dbi'
require 'active_record'

module Daru::RSpec
  class Account < ActiveRecord::Base
    self.table_name = 'accounts'
  end
end

shared_context 'with accounts table in sqlite3 database' do
  let(:db_name) do
    'daru_test'
  end

  before do
    # just in case
    FileUtils.rm(db_name) if File.file?(db_name)

    SQLite3::Database.new(db_name).tap do |db|
      db.execute "create table accounts(id integer, name varchar, age integer, primary key(id))"
      db.execute "insert into accounts values(1, 'Homer', 20)"
      db.execute "insert into accounts values(2, 'Marge', 30)"
    end
  end

  after do
    FileUtils.rm(db_name)
  end
end
