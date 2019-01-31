$:.unshift File.expand_path("../../../lib", __FILE__)

require_relative './vector/vectorCreationBenchmark'

module DaruBenchmark
  class VectorBenchmark
    extend DaruBenchmark::Vector
    VECTOR_SIZE_POW_10 = [2, 3, 4, 5]

    def self.benchmark_daru_vector()
      VECTOR_SIZE_POW_10.each do |df_size|
        puts
        self.set_size(10**df_size)
        self.init()
        puts "Vector of size : 10 ** #{df_size} "
        self.benchmark_vector_creation()
        puts
        self.benchmark_vector_creation_realtime()
        puts
      end
    end
  end # end DataFrameBenchmark class
end # end DaruBenchmark

DaruBenchmark::VectorBenchmark.benchmark_daru_vector()

# Output
#
# Vector of size : 10 ** 2 
# Warming up --------------------------------------
#           Using list     6.207k i/100ms
#  Using new-with_size     4.890k i/100ms
# Calculating -------------------------------------
#           Using list     66.183k (± 4.7%) i/s -    335.178k in   5.075404s
#  Using new-with_size     49.953k (± 4.6%) i/s -    254.280k in   5.101054s

# Comparison:
#           Using list:    66183.2 i/s
#  Using new-with_size:    49952.5 i/s - 1.32x  slower


#        user     system      total        real
# Vector creation- Using list
#    0.000038   0.000001   0.000039 (  0.000036)
# Realtime : 0.00003555500006768852

#        user     system      total        real
# Vector creation- Using new_with_size
#    0.000060   0.000000   0.000060 (  0.000059)
# Realtime : 0.00005920300100115128



# Vector of size : 10 ** 3 
# Warming up --------------------------------------
#           Using list   925.000  i/100ms
#  Using new-with_size   664.000  i/100ms
# Calculating -------------------------------------
#           Using list      9.208k (± 4.4%) i/s -     46.250k in   5.032381s
#  Using new-with_size      6.742k (± 4.3%) i/s -     33.864k in   5.031739s

# Comparison:
#           Using list:     9207.6 i/s
#  Using new-with_size:     6742.4 i/s - 1.37x  slower


#        user     system      total        real
# Vector creation- Using list
#    0.000140   0.000000   0.000140 (  0.000138)
# Realtime : 0.00013806400238536298

#        user     system      total        real
# Vector creation- Using new_with_size
#    0.000246   0.000000   0.000246 (  0.000246)
# Realtime : 0.00024614600260974839



# Vector of size : 10 ** 4 
# Warming up --------------------------------------
#           Using list    87.000  i/100ms
#  Using new-with_size    63.000  i/100ms
# Calculating -------------------------------------
#           Using list    867.577  (± 3.7%) i/s -      4.350k in   5.020563s
#  Using new-with_size    642.508  (± 3.9%) i/s -      3.213k in   5.008347s

# Comparison:
#           Using list:      867.6 i/s
#  Using new-with_size:      642.5 i/s - 1.35x  slower


#        user     system      total        real
# Vector creation- Using list
#    0.001208   0.000009   0.001217 (  0.001216)
# Realtime : 0.00121632599984877743

#        user     system      total        real
# Vector creation- Using new_with_size
#    0.001636   0.000013   0.001649 (  0.001648)
# Realtime : 0.00164795700038666837



# Vector of size : 10 ** 5 
# Warming up --------------------------------------
#           Using list     7.000  i/100ms
#  Using new-with_size     5.000  i/100ms
# Calculating -------------------------------------
#           Using list     76.446  (± 5.2%) i/s -    385.000  in   5.051069s
#  Using new-with_size     56.552  (± 5.3%) i/s -    285.000  in   5.050629s

# Comparison:
#           Using list:       76.4 i/s
#  Using new-with_size:       56.6 i/s - 1.35x  slower


#        user     system      total        real
# Vector creation- Using list
#    0.019526   0.000000   0.019526 (  0.019528)
# Realtime : 0.01952805700057069771

#        user     system      total        real
# Vector creation- Using new_with_size
#    0.020253   0.000000   0.020253 (  0.020260)
# Realtime : 0.02025979799873312004

