$:.unshift File.expand_path("../../lib", __FILE__)

require 'benchmark'
require 'daru'

# Check scaling
base_n = 10000
0.upto(2) do |iscale|
  n = base_n * 2**iscale

  df_h = ('a'..'z').map { |v| v.to_sym }.reduce({}) do |h, v|
    h[v] = Daru::Vector.new(1.upto(n).to_a)
    h
  end

  df = Daru::DataFrame.new(df_h)

  Benchmark.bm do |bm|
    bm.report("dupe (n=#{n})") do
      df.dup
    end
  end
end

#                   ===== Benchmarks =====
# System: iMac Late 2013 3.5GHz Core i7
#
#       user     system      total        real
#dupe (n=10000)  0.590000   0.020000   0.610000 (  0.613648)
#       user     system      total        real
#dupe (n=20000)  1.170000   0.040000   1.210000 (  1.236629)
#       user     system      total        real
#dupe (n=40000)  2.390000   0.070000   2.460000 (  2.511199)




#                   ===== Prior Benchmarks (Daru 0.1.2 - 2707559369c03894a8394714820aabf116b99b20 - 2016-04-25) =====
# Note that the n here is 100x smaller than above
#       user     system      total        real
#dupe (n=100)  0.220000   0.000000   0.220000 (  0.227924)
#       user     system      total        real
#dupe (n=200)  0.850000   0.000000   0.850000 (  0.856591)
#       user     system      total        real
#dupe (n=400)  3.370000   0.020000   3.390000 (  3.428211)
