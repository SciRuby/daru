$:.unshift File.expand_path("../../lib", __FILE__)

require 'benchmark'
require 'daru'

df = Daru::DataFrame.new({
  a: 10000.times.map { rand },
  b: 10000.times.map { rand },
  c: 10000.times.map { rand }
})

Benchmark.bm do |x|
  x.report("Single Vector access") do
    df[:a]
  end

  x.report("Access as range") do
    df[:a..:c]
  end

  x.report("Access with commas") do
    df[:a, :c]
  end
end

# ======== Benchmarks =======
#
#                         user     system      total        real
# Single Vector access  0.000000   0.000000   0.000000 (  0.000012)
# Access as range       0.090000   0.000000   0.090000 (  0.084584)
# Access with commas    0.050000   0.000000   0.050000 (  0.051951)