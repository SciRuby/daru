$:.unshift File.expand_path("../../lib", __FILE__)

require 'benchmark'
require 'daru'

Benchmark.bm do |x|
  x.report("Create with Arrays and clone") do
    df = Daru::DataFrame.new({
      a: 100000.times.map { rand },
      b: 100000.times.map { rand },
      c: 100000.times.map { rand }
    })
  end

  x.report("Create with Vectors and clone") do
    df = Daru::DataFrame.new({
      a: Daru::Vector.new(100000.times.map { rand }),
      b: Daru::Vector.new(100000.times.map { rand }),
      c: Daru::Vector.new(100000.times.map { rand })
    })
  end

  x.report("Create with Vector and dont clone") do
    df = Daru::DataFrame.new({
      a: Daru::Vector.new(100000.times.map { rand }),
      b: Daru::Vector.new(100000.times.map { rand }),
      c: Daru::Vector.new(100000.times.map { rand })
    }, clone: false)
  end

  x.report("Create by row from Arrays") do
  end
end

#                           ===== Benchmarks =====
#                                       user     system      total        real
# Create with Arrays and clone       0.940000   0.010000   0.950000 (  0.959851)
# Create with Vectors and clone      1.950000   0.020000   1.970000 (  1.966835)
# Create with Vector and dont clone  1.170000   0.000000   1.170000 (  1.177132)
