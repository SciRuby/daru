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
      by: { c: lambda { |a| a.to_s },
            a: lambda { |a| a+1 } })
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

#                                         ===== Current Benchamarks =====
# Sort a Vector without any args                                           0.070000   0.000000   0.070000 (  0.070323)
# Sort vector in descending order with custom <=> operator                 0.120000   0.000000   0.120000 (  0.119462)
# Sort single column of DataFrame                                          0.940000   0.010000   0.950000 (  0.950349)
# Sort two columns of DataFrame                                            1.490000   0.010000   1.500000 (  1.505680)
# Sort two columns with custom operators in different orders of DataFrame  1.480000   0.000000   1.480000 (  1.495839)
