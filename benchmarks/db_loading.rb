$:.unshift File.expand_path("../../lib", __FILE__)

require 'benchmark'
require 'daru'
require 'sqlite3'
require 'dbi'
require 'active_record'

db_name = 'daru_test.sqlite'
FileUtils.rm(db_name) if File.file?(db_name)

SQLite3::Database.new(db_name).tap do |db|
  db.execute "create table accounts(id integer, name varchar, age integer, primary key(id))"

  values = 1.upto(100_000).map { |i| %!(#{i},"name_#{i}",#{rand(100)})! }.join(",")
  db.execute "insert into accounts values #{values}"
end

ActiveRecord::Base.establish_connection("sqlite3:#{db_name}")
ActiveRecord::Base.connection

class Account < ActiveRecord::Base; end

Benchmark.bm do |x|
  x.report("DataFrame.from_sql") do
    Daru::DataFrame.from_sql(ActiveRecord::Base.connection, "SELECT * FROM accounts")
  end

  x.report("DataFrame.from_activerecord") do
    Daru::DataFrame.from_activerecord(Account.all)
  end
end

FileUtils.rm(db_name)
