$:.unshift File.expand_path("../../../lib", __FILE__)

require_relative './dataframe/dataframeCreationBenchmark'

module DaruBenchmark
  class DataFrameBenchmark
    extend DaruBenchmark::DataFrame
    DF_SIZE_POW_10 = [2, 3, 4, 5]

    def self.benchmark_daru_dataframe()
      DF_SIZE_POW_10.each do |df_size|
        self.set_df_row_size(10**df_size)
        self.set_df_colmn_size(2)
        self.init()
        puts "DataFrame of size : (10 ** #{df_size}, 2) "
        self.benchmark_dataframe_creation()
        puts 
      end
    end
  end # end DataFrameBenchmark class
end # end DaruBenchmark

DaruBenchmark::DataFrameBenchmark.benchmark_daru_dataframe()

# Jan 2019
# DataFrame of size : 10 ** 2 
# Warming up --------------------------------------
#  Using list of lists   118.000  i/100ms
# Using list of Vector    37.000  i/100ms
#  Using Hash of lists   855.000  i/100ms
# Using Hash of Vector   347.000  i/100ms
# Calculating -------------------------------------
#  Using list of lists      1.228k (± 2.7%) i/s -      6.136k in   5.000674s
# Using list of Vector    379.640  (± 2.6%) i/s -      1.924k in   5.071989s
#  Using Hash of lists      8.697k (± 3.5%) i/s -     43.605k in   5.020186s
# Using Hash of Vector      3.502k (± 3.8%) i/s -     17.697k in   5.061505s

# Comparison:
#  Using Hash of lists:     8697.3 i/s
# Using Hash of Vector:     3501.7 i/s - 2.48x  slower
#  Using list of lists:     1228.0 i/s - 7.08x  slower
# Using list of Vector:      379.6 i/s - 22.91x  slower


# DataFrame of size : 10 ** 3 
# Warming up --------------------------------------
#  Using list of lists    13.000  i/100ms
# Using list of Vector     3.000  i/100ms
#  Using Hash of lists   215.000  i/100ms
# Using Hash of Vector    65.000  i/100ms
# Calculating -------------------------------------
#  Using list of lists    129.814  (± 3.1%) i/s -    650.000  in   5.011517s
# Using list of Vector     38.721  (± 2.6%) i/s -    195.000  in   5.040975s
#  Using Hash of lists      2.125k (± 3.6%) i/s -     10.750k in   5.066062s
# Using Hash of Vector    664.555  (± 3.8%) i/s -      3.380k in   5.093825s

# Comparison:
#  Using Hash of lists:     2124.8 i/s
# Using Hash of Vector:      664.6 i/s - 3.20x  slower
#  Using list of lists:      129.8 i/s - 16.37x  slower
# Using list of Vector:       38.7 i/s - 54.88x  slower


# DataFrame of size : 10 ** 4 
# Warming up --------------------------------------
#  Using list of lists     1.000  i/100ms
# Using list of Vector     1.000  i/100ms
#  Using Hash of lists    24.000  i/100ms
# Using Hash of Vector     7.000  i/100ms
# Calculating -------------------------------------
#  Using list of lists     13.151  (± 7.6%) i/s -     66.000  in   5.036990s
# Using list of Vector      3.311  (± 0.0%) i/s -     17.000  in   5.216135s
#  Using Hash of lists    243.654  (± 6.2%) i/s -      1.224k in   5.047603s
# Using Hash of Vector     71.068  (± 2.8%) i/s -    357.000  in   5.028227s

# Comparison:
#  Using Hash of lists:      243.7 i/s
# Using Hash of Vector:       71.1 i/s - 3.43x  slower
#  Using list of lists:       13.2 i/s - 18.53x  slower
# Using list of Vector:        3.3 i/s - 73.58x  slower


# DataFrame of size : 10 ** 5 
# Warming up --------------------------------------
#  Using list of lists     1.000  i/100ms
# Using list of Vector     1.000  i/100ms
#  Using Hash of lists     1.000  i/100ms
# Using Hash of Vector     1.000  i/100ms
# Calculating -------------------------------------
#  Using list of lists      1.317  (± 0.0%) i/s -      7.000  in   5.342037s
# Using list of Vector      0.349  (± 0.0%) i/s -      2.000  in   5.737458s
#  Using Hash of lists     20.781  (±19.2%) i/s -     96.000  in   5.012213s
# Using Hash of Vector      6.310  (±15.8%) i/s -     32.000  in   5.159075s

# Comparison:
#  Using Hash of lists:       20.8 i/s
# Using Hash of Vector:        6.3 i/s - 3.29x  slower
#  Using list of lists:        1.3 i/s - 15.78x  slower
# Using list of Vector:        0.3 i/s - 59.52x  slower
