$:.unshift File.expand_path("../../lib", __FILE__)

require 'benchmark'
require 'daru'

data = Daru::DataFrame.from_csv './benchmarks/TradeoffData.csv'

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

# New benchmark - 21 jan 2019
#        user     system      total        real
# Single column grouping  0.001172   0.000067   0.001239 (  0.001238)
# Multi-column grouping  0.000584   0.000033   0.000617 (  0.000618)
# Single mean  0.000306   0.000017   0.000323 (  0.000306)
# Multi mean  0.000684   0.000000   0.000684 (  0.000667)
