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
    @@array_of_hashes = []
    @@hash_list = nil
    @@hash_vector = nil
    @@df_colmn_size = 2 # fixed 2 column for testing
    @@column_vector_name = [] # it is :a, :b after creating 

    def set_df(set_df)
      @@df = set_df
    end

    def get_df
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

      # column name
      create_column_vector_symbol()
      
      create_array_of_hashes()

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
          # p "list of lists rows =>  #{@@df.nrows}"
          # p "list of lists col => #{@@df.ncols}"
        end

        x.report("Using list of Vector") do
          create_df_listOfVector()
          # p "list of Vector rows =>  #{@@df.nrows}"
          # p "list of Vector col => #{@@df.ncols}"
        end

        x.report("Using list of Hashes") do
          create_df_using_list_with_hash()
          # p "list of Hashes rows =>  #{@@df.nrows}"
          # p "list of Hashes col => #{@@df.ncols}"
        end

        x.report("Using Hash of lists") do
          create_df_using_hash_with_list()
          # p "Hash of lists rows =>  #{@@df.nrows}"
          # p "Hash of lists col => #{@@df.ncols}"
        end

        x.report("Using Hash of Vector") do
          create_df_using_hash_with_vector()
          # p "Hash of Vector rows =>  #{@@df.nrows}"
          # p "Hash of Vector col => #{@@df.ncols}"
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

    def create_df_listOfHash()
      # creaating dataframe of size =  size * 2
      @@df= Daru::DataFrame.new(
        @@array_of_hashes
      )
    end

    def create_df_using_list_with_hash()
      @@df = Daru::DataFrame.new(
        @@array_of_hashes
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
      @@rows = Array.new(@@df_colmn_size) { 
        Array.new(@@df_row_size) { rand(1..9) } 
      }
      # p @@rows
    end

    def rows_to_vectors()
      @@rows_vectors = @@rows.map { |r| Daru::Vector.new r }
    end

    def create_column_vector_symbol()
      @@column_vector_name = generate_symbols_for_colmn_name(@@df_colmn_size-1)
    end

    def create_array_of_hashes()
      col_0 = Array.new(@@df_row_size) { rand(1..9) }
      col_1 = Array.new(@@df_row_size) { rand(1..9) }

      col_0.zip(col_1.map {|i| i}).each do |tuple|   
        @@array_of_hashes.append(
          { @@column_vector_name[0] => tuple[0],
            @@column_vector_name[1] => tuple[1],
          }
        )
      end

    end

    def rows_to_vectors_with_index()
      @@rows_vectors = @@rows.map { |r| Daru::Vector.new r, index: [:a,:b] }
    end

    def generate_symbols_for_colmn_name(size)
      (10..(10 + size)).map{|i| (i.to_s 36).to_sym}
    end

    def create_hash_with_list()
      @@hash_list = {}
      @@column_vector_name.each do |colmn|  
        @@hash_list[colmn] = Array.new(@@df_row_size) { rand(1..9) }
      end
    end

    def create_hash_with_vector()
      @@hash_vector = {}
      @@column_vector_name.each do |colmn|  
        @@hash_vector[colmn] = Daru::Vector.new(Array.new(@@df_row_size) { rand(1..9) })
      end
    end
  end
  # TODO: for DataFrame having MultiIndex
end