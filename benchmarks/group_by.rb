$:.unshift File.expand_path("../../lib", __FILE__)

require 'benchmark'
require 'daru'

data = Daru::DataFrame.from_csv 'TradeoffData.csv'

Benchmark.bm do |x|
  x.report("Single column grouping") do
    @single = data.group_by(['Treatment'])
  end

  x.report("Multi-column grouping") do
    @multi = data.group_by(['Group', 'Treatment'])
  end

  x.report("Single mean") do
    @single.mean
  end

  x.report("Multi mean") do
    @multi.mean
  end
end

#                    ===== Benchmarks =====
#
#                          user     system      total        real
# Single column grouping  0.000000   0.000000   0.000000  (0.000340)
# Multi-column grouping   0.000000   0.000000   0.000000  (0.000855)
# Single mean             0.000000   0.000000   0.000000  (0.001208)
# Multi mean              0.000000   0.000000   0.000000  (0.004892)