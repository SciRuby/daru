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

#                   ====== Benchmarks ======
#
#                         user     system      total        real
# Access single row    0.000000   0.000000   0.000000 (  0.000061)
# Access rows by comma 1.150000   0.000000   1.150000 (  1.159109)
# Individual rows      1.170000   0.000000   1.170000 (  1.180245)
# Access rows by range 122.960000   0.000000 122.960000 (123.074147)
