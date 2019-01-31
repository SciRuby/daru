
$:.unshift File.expand_path("../../../../lib", __FILE__)

require 'daru'
require 'benchmark/ips'
require 'benchmark'

module DaruBenchmark
  module Vector
    @@elements = nil
    @@vector = nil
    @@size = nil

    def set_size(vector_size)
      @@size = vector_size
    end

    # TODO:
    # - With categoricalIndex
    # - With MultiIndex
    def benchmark_vector_creation()   
      Benchmark.ips do |x|
        # Configure the number of seconds used during
        # the warmup phase (default 2) and calculation phase (default 5)
        x.config(:time => 5, :warmup => 2)

        # These parameters can also be configured this way
        x.time = 5
        x.warmup = 2

        # Typical mode, runs the block as many times as it can
        x.report("Using list") do 
          create_vector_from_array()
        end

        x.report("Using new-with_size") do
          create_vector_new_with_size()
        end

        # Compare the iterations per second of the various reports!
        x.compare!
      end
    end

    def benchmark_vector_creation_realtime()
      bench = Benchmark.bm do |x|
        puts 'Vector creation- Using list'
        report =x.report('') do
          create_vector_from_array()
        end
        puts("Realtime : %1.20f" % report.real)
      end
      puts
      bench = Benchmark.bm do |x|
        puts 'Vector creation- Using new_with_size'
        report =x.report('') do
          create_vector_new_with_size()
        end
        puts("Realtime : %1.20f" % report.real)
      end
      puts
    end

    def init()
      @@list = Array.new(@@size) { |i|  rand(1..9) }
      # p "list => #{@@list}"
    end

    def create_vector_from_array()
      @@vector = Daru::Vector.new(@@list)
      # p "vector.size => #{@@vector.size}"
    end

    def create_vector_new_with_size()
      @@vector = Daru::Vector.new_with_size(@@size)
      # p "vector => #{@@vector.size}"
    end
  end
end