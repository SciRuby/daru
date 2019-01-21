$:.unshift File.expand_path("../../lib", __FILE__)

require 'benchmark'
require 'daru'

df = Daru::DataFrame.new({
  a: 100000.times.map { rand },
  b: 100000.times.map { rand },
  c: 100000.times.map { rand }
})

Benchmark.bm do |x|
  x.report("Set a single row with Array") do
    df.row[5] = [55,22,65]
  end

  x.report("Set a single row with Daru::Vector") do
    df.row[3456] = Daru::Vector.new([3,54,11], index: [:b,:e,:a])
  end

  x.report("Create a new row with Array") do
    df.row[100001] = [34,66,11]
  end

  x.report("Create a new row with Daru::Vector") do
    df.row[100005] = Daru::Vector.new([34,66,11], index: [:a,:b,:t])
  end
end

#                      ==== Benchmarks ====
#
#                                       user     system      total        real
# Set a single row with Array         0.600000   0.000000   0.600000 (  0.604718)
# Set a single row with Daru::Vector  0.600000   0.000000   0.600000 (  0.598599)
# Create a new row with Array         0.840000   0.010000   0.850000 (  0.858349)
# Create a new row with Daru::Vector  0.950000   0.000000   0.950000 (  0.950725)

# New benchmark - 21 jan 2019
#        user     system      total        real
# Set a single row with Array  0.020479   0.000082   0.020561 (  0.020561)
# Set a single row with Daru::Vector  0.000145   0.000013   0.000158 (  0.000157)
# Create a new row with Array  0.043214   0.007858   0.051072 (  0.051085)
# Create a new row with Daru::Vector  0.052970   0.000158   0.053128 (  0.053162)
