$:.unshift File.expand_path("../../lib", __FILE__)

require 'benchmark'
require 'daru'

df = Daru::DataFrame.new({
  a: [1,2,3,4,5,6]*100,
  b: ['a','b','c','d','e','f']*100,
  c: [11,22,33,44,55,66]*100
}, index: (1..600).to_a.shuffle)

Benchmark.bm do |x|
  x.report("where") do
    df.where(df[:a].eq(2) | df[:c].eq(55))
  end

  x.report("filter_rows") do
    df.filter(:row) do |r|
      r[:a] == 2 or r[:c] == 55
    end
  end
end

#             ===== Benchmarks =====
#
#                user     system      total        real
# where        0.000000   0.000000   0.000000 (  0.002575)
# filter_rows  0.210000   0.000000   0.210000 (  0.205403)
