$:.unshift File.expand_path("../../../lib", __FILE__)

require_relative './vector/vectorSumBenchmark'

module DaruBenchmark
  class VectorBenchmark
    extend DaruBenchmark::VectorSum
    VECTOR_SIZE_POW_10 = [2, 3, 4, 5]

    def self.benchmark_daru_vector_sum()
      VECTOR_SIZE_POW_10.each do |df_size|
        puts
        self.set_size(10**df_size)
        self.init()
        puts "Vector of size : 10 ** #{df_size} "
        self.benchmark_vector_sum_realtime()
        puts
      end
    end
  end # end VectorBenchmark class
end # end DaruBenchmark

DaruBenchmark::VectorBenchmark.benchmark_daru_vector_sum()

# Output

# Vector of size : 10 ** 2 
#        user     system      total        real
# Vector Sum 
#    0.000017   0.000004   0.000021 (  0.000018)
# Realtime : 0.00001798800076358020



# Vector of size : 10 ** 3 
#        user     system      total        real
# Vector Sum 
#    0.000077   0.000016   0.000093 (  0.000093)
# Realtime : 0.00009332499757874757



# Vector of size : 10 ** 4 
#        user     system      total        real
# Vector Sum 
#    0.000808   0.000075   0.000883 (  0.000880)
# Realtime : 0.00088038299873005599



# Vector of size : 10 ** 5 
#        user     system      total        real
# Vector Sum 
#    0.008766   0.000156   0.008922 (  0.008918)
# Realtime : 0.00891789000161224976
