$:.unshift File.expand_path("../../lib", __FILE__)

require 'daru'
require 'benchmark'

vector = Daru::Vector.new(
  (10**6).times.map.to_a.shuffle,
  missing_values: 100.times.map.to_a.shuffle
  )

vector_gsl = Daru::Vector.new(
  10000.times.map.to_a.shuffle,
  missing_values: 100.times.map.to_a.shuffle,
  dtype: :gsl
  )

Benchmark.bm do |x|
  x.report("Mean of a vector") do
    vector.mean
  end

  x.report("Minimum of a vector") do
    vector.min
  end

  x.report("Mean of a vector with data type gsl") do
    vector_gsl.mean
  end

  x.report "Minimum of a vector with data type gsl" do
    vector_gsl.min
  end
end

#                    ===== Benchmarks =====
#
#                                     user     system      total        real
# Mean of a vector                 0.130000   0.010000   0.140000 (  0.145534)
# Min of a vector                  0.150000   0.000000   0.150000 (  0.163623)
# Mean of a gsl vector             0.000000   0.000000   0.000000 (  0.001037)
# Min of a gsl vector              0.000000   0.000000   0.000000 (  0.001251)


# New benchmark - 21 jan 2019
#                    user     system      total        real
# Mean of a vector  0.094727   0.000000   0.094727 (  0.094808)
# Minimum of a vector  1.015387   0.019809   1.035196 (  1.035515)
# Mean of a vector with data type gsl  0.000961   0.000038   0.000999 (  0.021783)
# Minimum of a vector with data type gsl  0.019477   0.000000   0.019477 (  0.019499)
