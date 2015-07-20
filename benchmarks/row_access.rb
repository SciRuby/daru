$:.unshift File.expand_path("../../lib", __FILE__)

require 'benchmark'
require 'daru'

df = Daru::DataFrame.new({
  a: 100000.times.map { rand },
  b: 100000.times.map { rand },
  c: 100000.times.map { rand }
})

Benchmark.bm do |x|
  x.report("Access single row") do
    df.row[50]
  end

  x.report("Access rows by comma") do
    df.row[*(5..40000).to_a.shuffle]
  end

  x.report("Individual rows") do
    rows = []
    index = (5..40000).to_a.shuffle
    index.each do |a|
      rows << df.row[a].to_a
    end

    Daru::DataFrame.rows(rows, order: [:a,:b,:c], index: index)
  end

  x.report("Access rows by range") do
    df.row[5..40000]
  end
end

#                     ==== Benchmarks ====
#                         user     system      total        real
# Access single row     0.000000   0.000000   0.000000 (  0.000059)
# Access rows by comma  1.410000   0.010000   1.420000 (  1.420426)
# Individual rows       1.480000   0.000000   1.480000 (  1.488531)
# Access rows by range  1.440000   0.010000   1.450000 (  1.436750)
