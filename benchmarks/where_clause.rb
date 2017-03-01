$:.unshift File.expand_path("../../lib", __FILE__)

require 'benchmark'
require 'daru'

df = Daru::DataFrame.new({
  a: 100000.times.map { |i| i },
  b: 100000.times.map { |i| i },
  c: 100000.times.map { |i| i }
}, index: Daru::Index.new(100000.times.map.to_a.shuffle))

puts "Benchmarking DataFrame#where\n"
Benchmark.bm do |x|
  x.report("Basic one liner") do
    df.where(df[:a].mt(2341))
  end

  x.report("Little complex statement") do
    df.where(df[:a].lt(235) | df[:b].eq(2341) | df[:c].in([35,355,22]))
  end
end

puts "Benchmarking Vector#where\n"
v = Daru::Vector.new(
  100000.times.map { |i| i }, index: 100000.times.map.to_a.shuffle)

Benchmark.bm do |x|
  x.report("Basic one liner") do
    v.where(v.mteq(1000))
  end

  x.report("Little complex statement") do
    v.where(v.lt(235) & v.eq(2341) | v.in([23,511,55]))
  end
end

#                     ====== Benchmarks ======
#
# Benchmarking DataFrame#where
#
#                             user     system      total      real
# Basic one liner           0.700000   0.000000   0.700000 (0.703532)
# Little complex statement  0.120000   0.000000   0.120000 (0.121765)
#
# Benchmarking Vector#where
#                             user     system      total      real
# Basic one liner           0.240000   0.000000   0.240000 (0.245787)
# Little complex statement  0.100000   0.000000   0.100000 (0.094423)
