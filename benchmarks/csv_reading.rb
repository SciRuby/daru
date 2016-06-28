# Date - 28 june 2016. daru version - 0.1.3.1
# Compare speed of Ruby stdlib CSV and DataFrame.from_csv.

require 'benchmark'
require 'csv'
require 'daru'

Benchmark.bm do |x|
  x.report("Ruby CSV") do
    CSV.read("TradeoffData.csv")
  end

  x.report("DataFrame.from_csv") do
    Daru::DataFrame.from_csv("TradeoffData.csv")
  end
end

# FIXME: Improve this. It's 4 times slower than Ruby CSV reading!!

#        user     system      total        real
# Ruby CSV  0.010000   0.000000   0.010000 (  0.002385)
# DataFrame.from_csv  0.000000   0.000000   0.000000 (  0.008225)
