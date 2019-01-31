
$:.unshift File.expand_path("../../../../lib", __FILE__)

require 'daru'
require 'benchmark'
require_relative 'vectorCreationBenchmark'

module DaruBenchmark
  module VectorSum
    extend DaruBenchmark::Vector

    def self.extended(base)
      base.send :extend, DaruBenchmark::Vector
    end

    def benchmark_vector_sum_realtime()
      self.create_vector_from_array()
      vect = DaruBenchmark::Vector::get_daru_vector()
      # p vect
      bench = Benchmark.bm do |x|
        puts 'Vector Sum '
        report =x.report('') do
          vect.sum
        end
        puts("Realtime : %1.20f" % report.real)
      end
      puts
    end
  end
end