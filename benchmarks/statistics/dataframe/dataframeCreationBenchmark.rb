$:.unshift File.expand_path("../../../../lib", __FILE__)

require 'daru'
require 'benchmark/ips'

module DaruBenchmark
  # TDOD exception handling
  module DataFrame
    @@df = nil
    @@df_row_size = nil
    @@rows = nil
    @@rows_vectors = nil
    @@hash_list = nil
    @@hash_vector = nil
    @@df_colmn_size = 2

    def set(set_df)
      @@df = set_df
    end

    def get
      @@df
    end

    def set_df_row_size(set_size)
      @@df_row_size = set_size
    end

    def get_df_row_size
      @@df_row_size
    end

    def init()
      create_rows()
      rows_to_vectors()
      create_hash_with_list()
      create_hash_with_vector()
    end

    def benchmark_dataframe_creation
      Benchmark.ips do |x|
        # Configure the number of seconds used during
        # the warmup phase (default 2) and calculation phase (default 5)
        x.config(:time => 5, :warmup => 2)

        # These parameters can also be configured this way
        x.time = 5
        x.warmup = 2

        # Typical mode, runs the block as many times as it can
        x.report("Using list of lists") do 
          create_df_listOfLists()
        end

        x.report("Using list of Vector") do
          create_df_listOfVector()
        end

        x.report("Using Hash of lists") do
          create_df_using_hash_with_list()
        end

        x.report("Using Hash of Vector") do
          create_df_using_hash_with_vector()
        end

        # Compare the iterations per second of the various reports!
        x.compare!
      end
    end

    # Methods to create DF with different data format
    def create_df_listOfLists()
      # for size * size dataframe
      # @df= Daru::DataFrame.new(
      #   Array.new(size) { Array.new(size) { size*rand(1..9) }  }
      # )

      # creaating dataframe of size =  size * 2
      @@df= Daru::DataFrame.new(
        @@rows
      )
      # p 'Size of the dataframe: (row x coln) : ' + @@df.shape.to_s 
    end

    # with index option
    def create_df_listOfLists_with_index()
      # pass
    end

    def create_df_listOfVector()
      # creaating dataframe of size =  size * 2
      @@df= Daru::DataFrame.new(
        @@rows_vectors
      )
    end

    # TODO: exception handling if @@hash_list is nil
    def create_df_using_hash_with_list()
      # creaating dataframe of size =  size * 2
      @@df= Daru::DataFrame.new(
        @@hash_list
      )
    end

    def create_df_using_hash_with_vector()
      # creaating dataframe of size =  size * 2
      @@df= Daru::DataFrame.new(
        @@hash_vector
      )
    end


    # Helping methods
    def create_rows()
      @@rows = Array.new(@@df_row_size) { Array.new(2) { rand(1..9) } }
    end

    def rows_to_vectors()
      @@rows_vectors = @@rows.map { |r| Daru::Vector.new r }
    end

    def rows_to_vectors_with_index()
      @@rows_vectors = @@rows.map { |r| Daru::Vector.new r, index: [:a,:b] }
    end

    def generate_symbols_for_colmn_name(size)
      (10..(10 + size)).map{|i| (i.to_s 36).to_sym}
    end

    def create_hash_with_list()
      @@hash_list = Hash.new []
      generate_symbols_for_colmn_name(@@df_colmn_size).each do |colmn|  
        @@hash_list[colmn] = Array.new(@@df_row_size) { rand(1..9) }
      end
    end

    def create_hash_with_vector()
      @@hash_vector = Hash.new []
      generate_symbols_for_colmn_name(@@df_colmn_size).each do |colmn|  
        @@hash_vector[colmn] = Daru::Vector.new(Array.new(@@df_row_size) { rand(1..9) })
      end
    end
  end
  # TODO: for DataFrame having MultiIndex
end