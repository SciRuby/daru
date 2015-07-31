$:.unshift File.expand_path("../../lib", __FILE__)

require 'benchmark'
require 'daru'

vector = Daru::Vector.new(10000.times.map.to_a.shuffle)
df = Daru::DataFrame.new({
  a: vector,
  b: vector,
  c: vector
})
Benchmark.bm do |x|
  x.report("Sort a Vector without any args") do
    vector.sort
  end

  x.report("Sort vector in descending order with custom <=> operator") do
    vector.sort(ascending: false) { |a,b| a.to_s <=> b.to_s }
  end

  x.report("Sort single column of DataFrame") do
    df.sort([:a])
  end

  x.report("Sort two columns of DataFrame") do
    df.sort([:c,:a])
  end

  x.report("Sort two columns with custom operators in different orders of DataFrame") do
    df.sort([:c,:a], ascending: [true, false], 
      by: { c: lambda { |a,b| a.to_s <=> b.to_s },
            a: lambda { |a,b| (a+1) <=> (b+1) } })
  end
end

# FIXME: MASSIVE SPEEDUP NECESSARY!

#                                         ===== Benchamarks =====
#                                                                             user      system      total      real
# Sort a Vector without any args                                           0.130000    0.000000 0.130000    (  0.128006)
# Sort vector in descending order with custom <=> operator                 0.190000    0.000000 0.190000    (  0.184604)
# Sort single column of DataFrame                                          2502.450000 0.000000 2502.450000 (2503.808073)
# Sort two columns of DataFrame                                            0.540000    0.000000 0.540000    (  0.537670)
# Sort two columns with custom operators in different orders of DataFrame  2084.160000 7.260000 2091.420000 (2092.716603)
