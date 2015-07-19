$:.unshift File.expand_path("../../lib", __FILE__)

require 'benchmark'
require 'daru'

df = Daru::DataFrame.new({
  a: 100000.times.map { rand },
  b: 100000.times.map { rand },
  c: 100000.times.map { rand }
})

Benchmark.bm do |x|
  x.report("Assign new vector as Array") do
    df[:d] = 100000.times.map { rand }
  end

  x.report("Reassign same vector as Array") do
    df[:a] = 100000.times.map { rand }
  end

  x.report("Assign new Vector as Daru::Vector") do
    df[:e] = Daru::Vector.new(100000.times.map { rand })
  end

  x.report("Reassign same Vector as Daru::Vector") do
    df[:b] = Daru::Vector.new(100000.times.map { rand })
  end
end