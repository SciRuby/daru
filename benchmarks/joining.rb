$:.unshift File.expand_path("../../lib", __FILE__)

require 'benchmark'
require 'daru'

# Check scaling
base_n = 10000
0.upto(2) do |iscale|
  n = base_n * 2**iscale
  keys = (1..(n)).to_a
  base_data = { idx: 1.upto(n).to_a, keys: 1.upto(n).map { |v| keys[Random.rand(n)]}}
  lookup_hash = keys.map { |k| [k, k * 100]}.to_h

  base_data_df = Daru::DataFrame.new(base_data)
  lookup_df = Daru::DataFrame.new({ keys: lookup_hash.keys, values: lookup_hash.values })

  Benchmark.bm do |bm|
    bm.report("Inner join (n=#{n})") do
      base_data_df.join(lookup_df, on: [:keys], how: :inner)
    end

    bm.report("Outer join (n=#{n})") do
      base_data_df.join(lookup_df, on: [:keys], how: :outer)
    end
  end
end

#                   ===== Benchmarks =====
# System: MacBook Pro Mid 2014 3GHz Core i7
#
#       user     system      total        real
#Inner join (n=10000)  0.170000   0.000000   0.170000 (  0.182254)
#Outer join (n=10000)  0.200000   0.000000   0.200000 (  0.203022)
#       user     system      total        real
#Inner join (n=20000)  0.380000   0.000000   0.380000 (  0.387600)
#Outer join (n=20000)  0.410000   0.000000   0.410000 (  0.415644)
#       user     system      total        real
#Inner join (n=40000)  0.720000   0.010000   0.730000 (  0.743787)
#Outer join (n=40000)  0.810000   0.010000   0.820000 (  0.840871)


#                   ===== Prior Benchmarks (Daru 0.1.2 - prior to sorted merge algorithm) =====
# Note that the n here is 10x smaller than above
#       user     system      total        real
#Inner join (n=1000)  0.170000   0.010000   0.180000 (  0.175585)
#Outer join (n=1000)  0.990000   0.000000   0.990000 (  1.004305)
#       user     system      total        real
#Inner join (n=2000)  0.440000   0.010000   0.450000 (  0.446748)
#Outer join (n=2000)  3.880000   0.010000   3.890000 (  3.926399)
#       user     system      total        real
#Inner join (n=4000)  1.670000   0.010000   1.680000 (  1.680742)
#Outer join (n=4000) 15.640000   0.060000  15.700000 ( 15.855202)
