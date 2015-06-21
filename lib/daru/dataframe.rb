$:.unshift File.dirname(__FILE__)

require 'accessors/dataframe_by_row.rb'
require 'maths/arithmetic/dataframe.rb'
require 'maths/statistics/dataframe.rb'
require 'plotting/dataframe.rb'
require 'io/io.rb'

module Daru
  class DataFrame

    include Daru::Maths::Arithmetic::DataFrame
    include Daru::Maths::Statistics::DataFrame
    include Daru::Plotting::DataFrame if Daru.has_nyaplot?

    class << self
      # Load data from a CSV file. Specify an optional block to grab the CSV 
      # object and pre-condition it (for example use the `convert` or 
      # `header_convert` methods).
      # 
      # == Arguments
      # 
      # * path - Path of the file to load specified as a String.
      # 
      # == Options
      # 
      # Accepts the same options as the Daru::DataFrame constructor and CSV.open()
      # and uses those to eventually construct the resulting DataFrame.
      #
      # == Verbose Description
      #
      # You can specify all the options to the `.from_csv` function that you 
      # do to the Ruby `CSV.read()` function, since this is what is used internally.
      #
      # For example, if the columns in your CSV file are separated by something 
      # other that commas, you can use the `:col_sep` option. If you want to 
      # convert numeric values to numbers and not keep them as strings, you can 
      # use the `:converters` option and set it to `:numeric`.
      #
      # The `.from_csv` function uses the following defaults for reading CSV files 
      # (that are passed into the `CSV.read()` function):
      #
      #   {
      #     :col_sep           => ',',
      #     :converters        => :numeric
      #   }
      def from_csv path, opts={}, &block
        Daru::IO.from_csv path, opts, &block      
      end

      # Read data from an Excel file into a DataFrame.
      # 
      # == Arguments
      # 
      # * path - Path of the file to be read.
      # 
      # == Options
      # 
      # *:worksheet_id - ID of the worksheet that is to be read.
      def from_excel path, opts={}, &block      
        Daru::IO.from_excel path, opts, &block
      end

      # Read a database query and returns a Dataset
      #
      # USE:
      #
      #  dbh = DBI.connect("DBI:Mysql:database:localhost", "user", "password")
      #  Daru::DataFrame.from_sql(dbh, "SELECT * FROM test")
      def from_sql dbh, query
        Daru::IO.from_sql dbh, query
      end

      # Read the database from a plaintext file. For this method to work,
      # the data should be present in a plain text file in columns. See
      # spec/fixtures/bank2.dat for an example.
      # 
      # == Arguments
      # 
      # * path - Path of the file to be read.
      # * fields - Vector names of the resulting database.
      # 
      # == Usage
      # 
      #   df = Daru::DataFrame.from_plaintext 'spec/fixtures/bank2.dat', [:v1,:v2,:v3,:v4,:v5,:v6]
      def from_plaintext path, fields
        Daru::IO.from_plaintext path, fields
      end

      # Create DataFrame by specifying rows as an Array of Arrays or Array of
      # Daru::Vector objects.
      def rows source, opts={}
        df = nil
        if source.all? { |v| v.size == source[0].size }
          first = source[0]
          index = []
          opts[:order] ||=
          if first.is_a?(Daru::Vector) # assume that all are Vectors
            source.each { |vec| index << vec.name }
            first.index.to_a
          elsif first.is_a?(Array)
            Array.new(first.size) { |i| i.to_s }
          end

          if source.all? { |s| s.is_a?(Array) }
            df = Daru::DataFrame.new(source.transpose, opts)
          else # array of Daru::Vectors
            df = Daru::DataFrame.new({}, opts)
            source.each_with_index do |row, idx|
              df[(index[idx] || idx), :row] = row
            end
          end
        else
          raise SizeError, "All vectors must have same length"
        end

        df
      end

      # Generates a new dataset, using three vectors
      # - Rows
      # - Columns
      # - Values
      #
      # For example, you have these values
      #
      #   x   y   v
      #   a   a   0
      #   a   b   1
      #   b   a   1
      #   b   b   0
      #
      # You obtain
      #   id  a   b
      #    a  0   1
      #    b  1   0
      #
      # Useful to process outputs from databases
      def crosstab_by_assignation rows, columns, values
        raise "Three vectors should be equal size" if 
          rows.size != columns.size or rows.size!=values.size

        cols_values = columns.factors
        cols_n      = cols_values.size

        h_rows = rows.factors.inject({}) do |a,v| 
          a[v] = cols_values.inject({}) do |a1,v1| 
            a1[v1]=nil 
            a1
          end
          a
        end

        values.each_index do |i|
          h_rows[rows[i]][columns[i]] = values[i]
        end
        df = Daru::DataFrame.new({}, order: [:_id] + cols_values.to_a)

        rows.factors.each do |row|
          n_row = Array.new(cols_n+1)
          n_row[0] = row
          cols_values.each_index do |i|
            n_row[i+1] = h_rows[row][cols_values[i]]
          end

          df.add_row(n_row)
        end
        df.update
        df
      end
    end

    # The vectors (columns) index of the DataFrame
    attr_reader :vectors

    # The index of the rows of the DataFrame
    attr_reader :index

    # The name of the DataFrame
    attr_reader :name

    # The number of rows present in the DataFrame
    attr_reader :size

    # DataFrame basically consists of an Array of Vector objects.
    # These objects are indexed by row and column by vectors and index Index objects.
    #
    # == Arguments
    # 
    # * source - Source from the DataFrame is to be initialized. Can be a Hash
    # of names and vectors (array or Daru::Vector), an array of arrays or
    # array of Daru::Vectors.
    # 
    # == Options
    # 
    # +:order+ - An *Array*/*Daru::Index*/*Daru::MultiIndex* containing the order in 
    # which Vectors should appear in the DataFrame.
    # 
    # +:index+ - An *Array*/*Daru::Index*/*Daru::MultiIndex* containing the order
    # in which rows of the DataFrame will be named.
    # 
    # +:name+  - A name for the DataFrame.
    #
    # +:clone+ - Specify as *true* or *false*. When set to false, and Vector
    # objects are passed for the source, the Vector objects will not duplicated
    # when creating the DataFrame. Will have no effect if Array is passed in 
    # the source, or if the passed Daru::Vectors have different indexes. 
    # Default to *true*.
    # 
    # == Usage
    #   df = Daru::DataFrame.new({a: [1,2,3,4], b: [6,7,8,9]}, order: [:b, :a], 
    #     index: [:a, :b, :c, :d], name: :spider_man)
    # 
    #   # => 
    #   # <Daru::DataFrame:80766980 @name = spider_man @size = 4>
    #   #             b          a 
    #   #  a          6          1 
    #   #  b          7          2 
    #   #  c          8          3 
    #   #  d          9          4 
    def initialize source, opts={}
      vectors = opts[:order]
      index   = opts[:index]
      clone   = opts[:clone] == false ? false : true
      @data   = []

      temp_name = opts[:name]
      @name   = temp_name || SecureRandom.uuid

      if source.empty?
        @vectors = try_create_index vectors
        @index   = try_create_index index
        create_empty_vectors
      else
        case source
        when Array
          if source.all? { |s| s.is_a?(Array) }
            raise ArgumentError, "Number of vectors (#{vectors.size}) should \
              equal order size (#{source.size})" if source.size != vectors.size

            @index   = try_create_index(index || source[0].size)
            @vectors = try_create_index(vectors)

            @vectors.each_with_index do |vec,idx|
              @data << Daru::Vector.new(source[idx], index: @index)
            end
          elsif source.all? { |s| s.is_a?(Daru::Vector) }
            hsh = {}
            vectors.each_with_index do |name, idx|
              hsh[name] = source[idx]
            end
            initialize(hsh, index: index, order: vectors, name: @name, clone: clone)
          else # array of hashes
            if vectors.nil?
              @vectors = Daru::Index.new source[0].keys
            else
              @vectors = Daru::Index.new(
                (vectors + (source[0].keys - vectors)).uniq)
            end
            @index = Daru::Index.new(index || source.size)

            @vectors.each do |name|
              v = []
              source.each do |hsh|
                v << (hsh[name] || hsh[name.to_s])
              end

              @data << Daru::Vector.new(v, name: set_name(name), index: @index)
            end
          end
        when Hash
          create_vectors_index_with vectors, source
          if all_daru_vectors_in_source? source
            if !index.nil?
              @index = try_create_index index
            elsif all_vectors_have_equal_indexes?(source)
              @index = source.values[0].index.dup
            else
              all_indexes = []
              source.each_value do |vector|
                all_indexes << vector.index.to_a
              end
              # sort only if missing indexes detected
              all_indexes.flatten!.uniq!.sort!

              @index = Daru::Index.new all_indexes
              clone = true
            end

            if clone
              @vectors.each do |vector|
                @data << Daru::Vector.new([], name: vector, index: @index)
                v = @data[@vectors[vector]]

                @index.each do |idx|
                  if source[vector].index.include? idx
                    v[idx] = source[vector][idx]
                  else
                    v[idx] = nil
                  end
                end
              end
            else
              @data.concat source.values
            end
          else
            @index = try_create_index(index || source.values[0].size)

            @vectors.each do |name|
              @data << Daru::Vector.new(source[name].dup, name: set_name(name), index: @index)
            end
          end
        end
      end

      set_size
      validate
      update
    end

    # Access row or vector. Specify name of row/vector followed by axis(:row, :vector).
    # Defaults to *:vector*. Use of this method is not recommended for accessing 
    # rows or vectors. Use df.row[:a] for accessing row with index ':a' or 
    # df.vector[:vec] for accessing vector with index *:vec*.
    def [](*names)
      if names[-1] == :vector or names[-1] == :row
        axis = names[-1]
        names = names[0..-2]
      else
        axis = :vector
      end

      if axis == :vector
        access_vector *names
      elsif axis == :row
        access_row *names
      else
        raise IndexError, "Expected axis to be row or vector not #{axis}"
      end
    end

    # Insert a new row/vector of the specified name or modify a previous row.
    # Instead of using this method directly, use df.row[:a] = [1,2,3] to set/create
    # a row ':a' to [1,2,3], or df.vector[:vec] = [1,2,3] for vectors.
    # 
    # In case a Daru::Vector is specified after the equality the sign, the indexes
    # of the vector will be matched against the row/vector indexes of the DataFrame
    # before an insertion is performed. Unmatched indexes will be set to nil.
    def []=(*args)
      axis = args.include?(:row) ? :row : :vector
      args.delete :vector
      args.delete :row

      name = args[0..-2]
      vector = args[-1]

      if axis == :vector
        insert_or_modify_vector name, vector
      elsif axis == :row        
        insert_or_modify_row name, vector
      else
        raise IndexError, "Expected axis to be row or vector, not #{axis}."
      end
    end

    # Access a vector by name.
    def column name
      vector[name]
    end

    def add_row row, index=nil
      self.row[index || @size] = row
    end

    def add_vector n, vector
      self[n] = vector
    end

    # Access a row or set/create a row. Refer #[] and #[]= docs for details.
    # 
    # == Usage
    #   df.row[:a] # access row named ':a'
    #   df.row[:b] = [1,2,3] # set row ':b' to [1,2,3]
    def row
      Daru::Accessors::DataFrameByRow.new(self)
    end

    # Duplicate the DataFrame entirely.
    # 
    # == Arguments
    # 
    # * +vectors_to_dup+ - An Array specifying the names of Vectors to 
    # be duplicated. Will duplicate the entire DataFrame if not specified.
    def dup vectors_to_dup=nil
      vectors_to_dup = @vectors.to_a unless vectors_to_dup

      if vectors.is_a?(MultiIndex)
        src = []
        vectors_to_dup.each do |vec|
          src << @data[@vectors[vec]].dup
        end
      else
        src = {}
        vectors_to_dup.each do |vector|
          src[vector] = @data[@vectors[vector]].dup
        end
      end
      new_order = Daru::Index.new(vectors_to_dup)

      Daru::DataFrame.new src, order: new_order, index: @index.dup, name: @name, clone: true
    end

    # Only clone the structure of the DataFrame.
    def clone_structure
      Daru::DataFrame.new([], order: @vectors.dup, index: @index.dup, name: @name)
    end

    # Returns a 'view' of the DataFrame, i.e the object ID's of vectors are
    # preserved.
    # 
    # == Arguments
    # 
    # +vectors_to_clone+ - Names of vectors to clone. Optional. Will return
    # a view of the whole data frame otherwise.
    def clone *vectors_to_clone
      vectors_to_clone.flatten! unless vectors_to_clone.all? { |a| !a.is_a?(Array) }
      return super if vectors_to_clone.empty?

      h = vectors_to_clone.inject({}) do |hsh, vec|
        hsh[vec] = self[vec]
        hsh
      end
      Daru::DataFrame.new(h, clone: false)
    end

    # Returns a 'shallow' copy of DataFrame if missing data is not present, 
    # or a full copy of only valid data if missing data is present.
    def clone_only_valid
      if has_missing_data?
        dup_only_valid
      else
        clone
      end
    end

    # Creates a new duplicate dataframe containing only rows 
    # without a single missing value.
    def dup_only_valid vecs=nil
      rows_with_nil = @data.inject([]) do |memo, vector|
        memo.concat vector.missing_positions
        memo
      end.uniq

      row_indexes = @index.to_a
      (vecs.nil? ? self : dup(vecs)).row[*(row_indexes - rows_with_nil)]
    end

    # Iterate over each vector
    def each_vector(&block)
      return to_enum(:each_vector) unless block_given?

      @data.each(&block)

      self
    end

    alias_method :each_column, :each_vector

    # Iterate over each vector alongwith the name of the vector
    def each_vector_with_index(&block)
      return to_enum(:each_vector_with_index) unless block_given?

      @vectors.each do |vector|
        yield @data[@vectors[vector]], vector
      end 

      self
    end

    alias_method :each_column_with_index, :each_vector_with_index

    # Iterate over each row
    def each_row(&block)
      return to_enum(:each_row) unless block_given?

      @index.each do |index|
        yield access_row(index)
      end

      self
    end

    def each_row_with_index(&block)
      return to_enum(:each_row_with_index) unless block_given?

      @index.each do |index|
        yield access_row(index), index
      end

      self
    end

    # Iterate over each row or vector of the DataFrame. Specify axis
    # by passing :vector or :row as the argument. Default to :vector.
    #
    # == Description
    #
    # `#each` works exactly like Array#each. The default mode for `each` 
    # is to iterate over the columns of the DataFrame. To iterate over 
    # rows you must pass the axis, i.e `:row` as an argument.
    # 
    # == Arguments
    # 
    # * +axis+ - The axis to iterate over. Can be :vector (or :column)
    # or :row. Default to :vector.
    def each axis=:vector, &block
      if axis == :vector or axis == :column
        each_vector(&block)
      elsif axis == :row
        each_row(&block)
      else
        raise ArgumentError, "Unknown axis #{axis}"
      end
    end

    # Iterate over a row or vector and return results in a Daru::Vector.
    # Specify axis with :vector or :row. Default to :vector.
    #
    # == Description
    #
    # The #collect iterator works similar to #map, the only difference 
    # being that it returns a Daru::Vector comprising of the results of 
    # each block run. The resultant Vector has the same index as that 
    # of the axis over which collect has iterated. It also accepts the 
    # optional axis argument.
    #
    # == Arguments
    # 
    # * +axis+ - The axis to iterate over. Can be :vector (or :column)
    # or :row. Default to :vector.
    def collect axis=:vector, &block
      if axis == :vector or axis == :column
        collect_vectors(&block)
      elsif axis == :row
        collect_rows(&block)
      else
        raise ArgumentError, "Unknown axis #{axis}"
      end
    end

    # Map over each vector or row of the data frame according to
    # the argument specified. Will return an Array of the resulting
    # elements. To map over each row/vector and get a DataFrame,
    # see #recode.
    # 
    # == Description
    # 
    # The #map iterator works like Array#map. The value returned by 
    # each run of the block is added to an Array and the Array is 
    # returned. This method also accepts an axis argument, like #each. 
    # The default is :vector.
    # 
    # == Arguments
    # 
    # * +axis+ - The axis to map over. Can be :vector (or :column) or :row.
    # Default to :vector.
    def map axis=:vector, &block
      if axis == :vector or axis == :column
        map_vectors(&block)
      elsif axis == :row
        map_rows(&block)
      else
        raise ArgumentError, "Unknown axis #{axis}"
      end
    end

    # Destructive map. Modifies the DataFrame. Each run of the block
    # must return a Daru::Vector. You can specify the axis to map over
    # as the argument. Default to :vector.
    # 
    # == Arguments
    # 
    # * +axis+ - The axis to map over. Can be :vector (or :column) or :row.
    # Default to :vector.
    def map! axis=:vector, &block
      if axis == :vector or axis == :column
        map_vectors!(&block)
      elsif axis == :row
        map_rows!(&block)
      end
    end

    # Maps over the DataFrame and returns a DataFrame. Each run of the
    # block must return a Daru::Vector object. You can specify the axis
    # to map over. Default to :vector.
    #
    # == Description
    #
    # Recode works similarly to #map, but an important difference between 
    # the two is that recode returns a modified Daru::DataFrame instead 
    # of an Array. For this reason, #recodeexpects that every run of the 
    # block to return a Daru::Vector.
    #
    # Just like map and each, recode also accepts an optional _axis_ argument.
    # 
    # == Arguments
    # 
    # * +axis+ - The axis to map over. Can be :vector (or :column) or :row.
    # Default to :vector.
    def recode axis=:vector, &block
      if axis == :vector or axis == :column
        recode_vectors(&block)
      elsif axis == :row
        recode_rows(&block)
      end
    end

    # Retain vectors or rows if the block returns a truthy value.
    # 
    # == Description
    # 
    # For filtering out certain rows/vectors based on their values, 
    # use the #filter method. By default it iterates over vectors and 
    # keeps those vectors for which the block returns true. It accepts 
    # an optional axis argument which lets you specify whether you want 
    # to iterate over vectors or rows.
    # 
    # == Arguments
    # 
    # * +axis+ - The axis to map over. Can be :vector (or :column) or :row.
    # Default to :vector.
    # 
    # == Usage
    # 
    #   # Filter vectors
    #
    #   df.filter do |vector|
    #     vector.type == :numeric and vector.median < 50
    #   end
    #
    #   # Filter rows
    #
    #   df.filter(:row) do |row|
    #     row[:a] + row[:d] < 100
    #   end
    def filter axis=:vector, &block
      if axis == :vector or axis == :column
        filter_vectors(&block)
      elsif axis == :row
        filter_rows(&block)
      end
    end

    def recode_vectors &block
      block_given? or return to_enum(:recode_vectors) 

      df = self.dup
      df.each_vector_with_index do |v, i|
        ret = yield v
        ret.is_a?(Daru::Vector) or 
          raise TypeError, "Every iteration must return Daru::Vector not #{ret.class}"
        df[*i] = ret
      end

      df
    end

    def recode_rows &block
      block_given? or return to_enum(:recode_rows)

      df = self.dup
      df.each_row_with_index do |r, i|
        ret = yield r
        ret.is_a?(Daru::Vector) or raise TypeError, "Every iteration must return Daru::Vector not #{ret.class}"
        df.row[i] = ret
      end

      df
    end

    # Map each vector and return an Array.
    def map_vectors(&block)
      return to_enum(:map_vectors) unless block_given?

      arry = []
      @data.each do |vec|
        arry << yield(vec)
      end

      arry
    end

    # Destructive form of #map_vectors
    def map_vectors!(&block)
      return to_enum(:map_vectors!) unless block_given?

      vectors.dup.each do |n|
        v = yield self[n]
        v.is_a?(Daru::Vector) or raise TypeError, "Must return a Daru::Vector not #{v.class}"
        self[n] = v
      end

      self
    end

    # Map vectors alongwith the index.
    def map_vectors_with_index(&block)
      return to_enum(:map_vectors_with_index) unless block_given?

      dt = []
      each_vector_with_index do |vector, name|
        dt << yield(vector, name)
      end

      dt
    end

    # Map each row
    def map_rows(&block)
      return to_enum(:map_rows) unless block_given?

      dt = []
      each_row do |row|
        dt << yield(row)
      end

      dt
    end

    def map_rows_with_index(&block)
      return to_enum(:map_rows_with_index) unless block_given?

      dt = []
      each_row_with_index do |row, index|
        dt << yield(row, index)
      end

      dt
    end

    def map_rows!(&block)
      return to_enum(:map_rows!) unless block_given?

      index.dup.each do |i|
        r = yield self.row[i]
        r.is_a?(Daru::Vector) or raise TypeError, "Returned object must be Daru::Vector not #{r.class}"
        self.row[i] = r
      end

      self
    end

    # Retrieves a Daru::Vector, based on the result of calculation 
    # performed on each row.
    def collect_rows &block
      return to_enum(:collect_rows) unless block_given?

      data = []
      each_row do |row|
        data.push yield(row)
      end

      Daru::Vector.new(data, index: @index)
    end

    def collect_row_with_index &block
      return to_enum(:collect_row_with_index) unless block_given?

      data = []
      each_row_with_index do |row, i|
        data.push yield(row, i)
      end

      Daru::Vector.new(data, index: @index)
    end

    # Retrives a Daru::Vector, based on the result of calculation
    # performed on each vector.
    def collect_vectors &block
      return to_enum(:collect_vectors) unless block_given?

      data = []
      each_vector do |vec|
        data.push yield(vec)
      end

      Daru::Vector.new(data, index: @vectors)
    end

    def collect_vector_with_index &block
      return to_enum(:collect_vector_with_index) unless block_given?

      data = []
      each_vector_with_index do |vec, i|
        data.push yield(vec, i)
      end

      Daru::Vector.new(data, index: @vectors)
    end

    # Generate a matrix, based on vector names of the DataFrame.
    #
    # @return {::Matrix}
    def collect_matrix
      return to_enum(:collect_matrix) unless block_given?

      vecs = vectors.to_a
      rows = vecs.collect { |row|
        vecs.collect { |col|
          yield row,col
        }
      }

      Matrix.rows(rows)
    end


    # Delete a vector
    def delete_vector vector
      if @vectors.include? vector
        @data.delete_at @vectors[vector]
        @vectors = Daru::Index.new @vectors.to_a - [vector]
      else
        raise IndexError, "Vector #{vector} does not exist."
      end

      self
    end

    # Delete a row
    def delete_row index
      idx = named_index_for index

      if @index.include? idx
        @index = Daru::Index.new(@index.to_a - [idx])
        self.each_vector do |vector|
          vector.delete_at idx
        end
      else
        raise IndexError, "Index #{index} does not exist."
      end

      set_size
    end

    # Creates a DataFrame with the random data, of n size.
    # If n not given, uses original number of rows.
    #
    # @return {Daru::DataFrame}
    def bootstrap(n=nil)
      n ||= nrows
      ds_boot = Daru::DataFrame.new({}, order: @vectors)
      n.times do
        ds_boot.add_row(row[rand(n)])
      end
      ds_boot.update
      ds_boot
    end

    def keep_row_if &block
      deletion = []

      @index.each do |index|
        keep_row = yield access_row(index)

        deletion << index unless keep_row
      end
      deletion.each { |idx| 
        delete_row idx 
      }
    end

    def keep_vector_if &block
      @vectors.each do |vector|
        keep_vector = yield @data[@vectors[vector]], vector
        
        delete_vector vector unless keep_vector
      end
    end

    # creates a new vector with the data of a given field which the block returns true
    def filter_vector vec
      d = []
      each_row do |row|
        d.push(row[vec]) if yield row
      end

      Daru::Vector.new(d)
    end

    # Iterates over each row and retains it in a new DataFrame if the block returns
    # true for that row.
    def filter_rows &block
      return to_enum(:filter_rows) unless block_given?

      df = Daru::DataFrame.new({}, order: @vectors.to_a)
      marked = []

      @index.each do |index|
        keep_row = yield access_row(index)
        marked << index if keep_row
      end

      marked.each do |idx|
        df.row[idx] = self[idx, :row]
      end

      df
    end

    # Iterates over each vector and retains it in a new DataFrame if the block returns
    # true for that vector.
    def filter_vectors &block
      return to_enum(:filter_vectors) unless block_given?
      
      df = self.dup
      df.keep_vector_if &block

      df
    end

    # Test each row with one or more tests. Each test is a Proc with the form
    # *Proc.new {|row| row[:age] > 0}*
    # 
    # The function returns an array with all errors.
    def verify(*tests)
      if(tests[0].is_a? Symbol)
        id = tests[0]
        tests.shift
      else
        id = @vectors.first
      end

      vr = []
      i  = 0
      each(:row) do |row|
        i += 1
        tests.each do |test|
          if !test[2].call(row)
            values = ""
            if test[1].size>0
              values = " (" + test[1].collect{ |k| "#{k}=#{row[k]}" }.join(", ") + ")"
            end
            vr.push("#{i} [#{row[id]}]: #{test[0]}#{values}")
          end
        end
      end
      vr
    end

    # DSL for yielding each row and returning a Daru::Vector based on the
    # value each run of the block returns.
    # 
    # == Usage
    # 
    #   a1 = Daru::Vector.new([1, 2, 3, 4, 5, 6, 7])
    #   a2 = Daru::Vector.new([10, 20, 30, 40, 50, 60, 70])
    #   a3 = Daru::Vector.new([100, 200, 300, 400, 500, 600, 700])
    #   ds = Daru::DataFrame.new({ :a => a1, :b => a2, :c => a3 })
    #   total = ds.vector_by_calculation { a + b + c }
    #   # <Daru::Vector:82314050 @name = nil @size = 7 >
    #   #   nil
    #   # 0 111
    #   # 1 222
    #   # 2 333
    #   # 3 444
    #   # 4 555
    #   # 5 666
    #   # 6 777
    def vector_by_calculation &block
      a = []
      each_row do |r|
        a.push r.instance_eval(&block)
      end

      Daru::Vector.new a, index: @index
    end

    # Returns a vector, based on a string with a calculation based
    # on vector.
    # 
    # The calculation will be eval'ed, so you can put any variable
    # or expression valid on ruby.
    # 
    # For example:
    #   a = Daru::Vector.new [1,2]
    #   b = Daru::Vector.new [3,4]
    #   ds = Daru::DataFrame.new({:a => a,:b => b})
    #   ds.compute("a+b")
    #   => Vector [4,6]
    def compute text, &block
      return instance_eval(&block) if block_given?
      instance_eval(text) 
    end

    # Return a vector with the number of missing values in each row.
    # 
    # == Arguments
    # 
    # * +missing_values+ - An Array of the values that should be 
    # treated as 'missing'. The default missing value is *nil*.
    def missing_values_rows missing_values=[nil]
      number_of_missing = []
      each_row do |row|
        row.missing_values = missing_values
        number_of_missing << row.missing_positions.size
      end

      Daru::Vector.new number_of_missing, index: @index, name: "#{@name}_missing_rows"
    end

    # TODO: remove next version
    alias :vector_missing_values :missing_values_rows

    def has_missing_data?
      !!@data.any? { |v| v.has_missing_data? }
    end

    alias :flawed? :has_missing_data?

    # Return a nested hash using vector names as keys and an array constructed of 
    # hashes with other values. If block provided, is used to provide the
    # values, with parameters +row+ of dataset, +current+ last hash on 
    # hierarchy and +name+ of the key to include
    def nest *tree_keys, &block
      tree_keys = tree_keys[0] if tree_keys[0].is_a? Array
      out = {}

      each_row do |row|
        current = out
        # Create tree
        tree_keys[0, tree_keys.size-1].each do |f|
          root = row[f]
          current[root] ||= {}
          current = current[root]
        end
        name = row[tree_keys.last]
        if !block
          current[name] ||= []
          current[name].push(row.to_hash.delete_if { |key,value| tree_keys.include? key})
        else
          current[name] = block.call(row, current,name)
        end
      end

      out
    end

    def vector_count_characters vecs=nil
      vecs ||= @vectors.to_a

      collect_row_with_index do |row, i|
        vecs.inject(0) do |memo, vec|
          memo + (row[vec].nil? ? 0 : row[vec].to_s.size)
        end
      end
    end

    def add_vectors_by_split(name,join='-',sep=Daru::SPLIT_TOKEN)
      split = self[name].split_by_separator(sep)
      split.each { |k,v| self[(name.to_s + join + k.to_s).to_sym] = v }
    end

    # Return the number of rows and columns of the DataFrame in an Array.
    def shape
      [@index.size, @vectors.size]
    end

    # The number of rows
    def nrows
      shape[0]
    end

    # The number of vectors
    def ncols
      shape[1]
    end

    # Check if a vector is present
    def has_vector? vector
      @vectors.include? vector
    end

    def any? axis=:vector, &block
      if axis == :vector or axis == :column
        @data.any?(&block)
      elsif axis == :row
        each_row do |row|
          return true if yield(row)
        end
        return false
      else
        raise ArgumentError, "Unidentified axis #{axis}"
      end
    end

    def all? axis=:vector, &block
      if axis == :vector or axis == :column
        @data.all?(&block)
      elsif axis == :row
        each_row do |row|
          return false unless yield(row)
        end
        return true
      else
        raise ArgumentError, "Unidentified axis #{axis}"
      end
    end

    # The first ten elements of the DataFrame
    #
    # @param [Fixnum] quantity (10) The number of elements to display from the top.
    def head quantity=10
      self[0..(quantity-1), :row]
    end

    # The last ten elements of the DataFrame
    # 
    # @param [Fixnum] quantity (10) The number of elements to display from the bottom.
    def tail quantity=10
      self[(@size - quantity)..(@size-1), :row]
    end

    # Returns a vector with sum of all vectors specified in the argument. 
    # Tf vecs parameter is empty, sum all numeric vector.
    def vector_sum vecs=nil
      vecs ||= numeric_vectors
      sum = Daru::Vector.new [0]*@size, index: @index, name: @name, dtype: @dtype

      vecs.each do |n|
        sum += self[n]
      end

      sum
    end

    # Calculate mean of the rows of the dataframe.
    # 
    # == Arguments
    # 
    # * +max_missing+ - The maximum number of elements in the row that can be
    # zero for the mean calculation to happen. Default to 0.
    def vector_mean max_missing=0
      mean_vec = Daru::Vector.new [0]*@size, index: @index, name: "mean_#{@name}"

      each_row_with_index do |row, i|
        mean_vec[i] = row.missing_positions.size > max_missing ? nil : row.mean
      end

      mean_vec
    end

    # Group elements by vector to perform operations on them. Returns a 
    # Daru::Core::GroupBy object.See the Daru::Core::GroupBy docs for a detailed
    # list of possible operations.
    # 
    # == Arguments
    # 
    # * vectors - An Array contatining names of vectors to group by.
    # 
    # == Usage
    # 
    #   df = Daru::DataFrame.new({
    #     a: %w{foo bar foo bar   foo bar foo foo},
    #     b: %w{one one two three two two one three},
    #     c:   [1  ,2  ,3  ,1    ,3  ,6  ,3  ,8],
    #     d:   [11 ,22 ,33 ,44   ,55 ,66 ,77 ,88]
    #   })
    #   df.group_by([:a,:b,:c]).groups
    #   #=> {["bar", "one", 2]=>[1],
    #   # ["bar", "three", 1]=>[3],
    #   # ["bar", "two", 6]=>[5],
    #   # ["foo", "one", 1]=>[0],
    #   # ["foo", "one", 3]=>[6],
    #   # ["foo", "three", 8]=>[7],
    #   # ["foo", "two", 3]=>[2, 4]}
    def group_by vectors
      vectors = [vectors] if vectors.is_a?(Symbol)
      vectors.each { |v| raise(ArgumentError, "Vector #{v} does not exist") unless
        has_vector?(v) }
        
      Daru::Core::GroupBy.new(self, vectors)
    end

    def reindex_vectors! new_vectors
      raise ArgumentError, "Number of vectors passed into function (#{new_vectors.size}) should equal that present in the DataFrame (#{@vectors.size})" if 
        @vectors.size != new_vectors.size

      @vectors = Daru::Index.new new_vectors, new_vectors.map { |e| @vectors[e] }
    end

    # Change the index of the DataFrame and its underlying vectors. Destructive.
    # 
    # @param [Symbol, Array] new_index Specify an Array if 
    def reindex! new_index
      raise ArgumentError, "Index size must equal dataframe size" if new_index.is_a?(Array) and new_index.size != @size

      @index = possibly_multi_index?(new_index == :seq ? @size : new_index)
      @data.map! do |vector|
        vector.reindex possibly_multi_index?(@index.to_a)
      end

      self
    end

    # Non-destructive version of #reindex!
    def reindex new_index
      self.dup.reindex! new_index
    end

    # Return the indexes of all the numeric vectors. Will include vectors with nils
    # alongwith numbers.
    def numeric_vectors
      numerics = []

      each_vector_with_index do |vec, i|
        numerics << i if(vec.type == :numeric)
      end
      numerics
    end

    def numeric_vector_names
      numerics = []

      each_vector do |vec, i|
        numerics << vec.name if(vec.type == :numeric)
      end
      numerics
    end

    # Return a DataFrame of only the numerical Vectors. If clone: false
    # is specified as option, only a *view* of the Vectors will be
    # returned. Defaults to clone: true.
    def only_numerics opts={}
      cln = opts[:clone] == false ? false : true
      nv = numeric_vectors
      arry = nv.inject([]) do |arr, v|
        arr << self[v]
        arr
      end

      order = Index.new(nv)
      Daru::DataFrame.new(arry, clone: cln, order: order, index: @index)
    end

    # Generate a summary of this DataFrame with ReportBuilder.
    def summary(method = :to_text)
      ReportBuilder.new(no_title: true).add(self).send(method)
    end

    def report_building(b) # :nodoc: #
      b.section(:name=>@name) do |g|
        g.text "Number of rows: #{nrows}"
        @vectors.each do |v|
          g.text "Element:[#{v}]"
          g.parse_element(self[v])
        end
      end
    end

    # Sorts a dataframe (ascending/descending)according to the given sequence of 
    # vectors, using the attributes provided in the blocks.
    # 
    # @param order [Array] The order of vector names in which the DataFrame
    #   should be sorted.
    # @param [Hash] opts The options to sort with.
    # @option opts [TrueClass,FalseClass,Array] :ascending (true) Sort in ascending
    #   or descending order. Specify Array corresponding to *order* for multiple
    #   sort orders.
    # @option opts [Hash] :by ({|a,b| a <=> b}) Specify attributes of objects to
    #   to be used for sorting, for each vector name in *order* as a hash of 
    #   vector name and lambda pairs. In case a lambda for a vector is not
    #   specified, the default will be used.
    # 
    # == Usage
    #   
    #   df = Daru::DataFrame.new({a: [-3,2,-1,4], b: [4,3,2,1]})
    #   
    #   #<Daru::DataFrame:140630680 @name = 04e00197-f8d5-4161-bca2-93266bfabc6f @size = 4>
    #   #            a          b 
    #   # 0         -3          4 
    #   # 1          2          3 
    #   # 2         -1          2 
    #   # 3          4          1 
    #   df.sort([:a], by: { a: lambda { |a,b| a.abs <=> b.abs } })  
    def sort! vector_order, opts={}
      raise ArgumentError, "Required atleast one vector name" if vector_order.size < 1
      opts = {
        ascending: true,
        type: :quick_sort,
        by: {}
      }.merge(opts)

      opts[:by]        = create_logic_blocks vector_order, opts[:by]
      opts[:ascending] = sort_order_array vector_order, opts[:ascending]
      index = @index.to_a
      send(opts[:type], vector_order, index, opts[:by], opts[:ascending])
      reindex! index
    end

    # Non-destructive version of #sort!
    def sort vector_order, opts={}
      self.dup.sort! vector_order, opts
    end

    # Pivots a data frame on specified vectors and applies an aggregate function
    # to quickly generate a summary.
    # 
    # == Options
    # 
    # +:index+ - Keys to group by on the pivot table row index. Pass vector names
    # contained in an Array.
    # 
    # +:vectors+ - Keys to group by on the pivot table column index. Pass vector
    # names contained in an Array.
    # 
    # +:agg+ - Function to aggregate the grouped values. Default to *:mean*. Can
    # use any of the statistics functions applicable on Vectors that can be found in 
    # the Daru::Statistics::Vector module.
    # 
    # +:values+ - Columns to aggregate. Will consider all numeric columns not 
    # specified in *:index* or *:vectors*. Optional.
    # 
    # == Usage
    # 
    #   df = Daru::DataFrame.new({
    #     a: ['foo'  ,  'foo',  'foo',  'foo',  'foo',  'bar',  'bar',  'bar',  'bar'], 
    #     b: ['one'  ,  'one',  'one',  'two',  'two',  'one',  'one',  'two',  'two'],
    #     c: ['small','large','large','small','small','large','small','large','small'],
    #     d: [1,2,2,3,3,4,5,6,7],
    #     e: [2,4,4,6,6,8,10,12,14]
    #   })
    #   df.pivot_table(index: [:a], vectors: [:b], agg: :sum, values: :e)
    # 
    #   #=> 
    #   # #<Daru::DataFrame:88342020 @name = 08cdaf4e-b154-4186-9084-e76dd191b2c9 @size = 2>
    #   #            [:e, :one] [:e, :two] 
    #   #     [:bar]         18         26 
    #   #     [:foo]         10         12 
    def pivot_table opts={}
      raise ArgumentError, 
        "Specify grouping index" if !opts[:index] or opts[:index].empty?

      index   = opts[:index]
      vectors = opts[:vectors] || []
      aggregate_function = opts[:agg] || :mean
      values = 
      if opts[:values].is_a?(Symbol)
        [opts[:values]]
      elsif opts[:values].is_a?(Array)
        opts[:values]
      else # nil
        (@vectors.to_a - (index | vectors)) & numeric_vector_names
      end
      
      raise IndexError, "No numeric vectors to aggregate" if values.empty?

      grouped  = group_by(index)

      unless vectors.empty?
        super_hash = {}
        values.each do |value|
          grouped.groups.each do |group_name, row_numbers|
            super_hash[group_name] ||= {}

            row_numbers.each do |num|
              arry = []
              arry << value
              vectors.each { |v| arry << self[v][num] }
              sub_hash = super_hash[group_name]
              sub_hash[arry] ||= []

              sub_hash[arry] << self[value][num]
            end
          end
        end

        super_hash.each_value do |sub_hash|
          sub_hash.each do |group_name, aggregates|
            sub_hash[group_name] = Daru::Vector.new(aggregates).send(aggregate_function)
          end
        end

        df_index = Daru::MultiIndex.from_tuples symbolize(super_hash.keys)

        vector_indexes = []
        super_hash.each_value do |sub_hash|
          vector_indexes.concat sub_hash.keys
        end
        df_vectors = Daru::MultiIndex.from_tuples symbolize(vector_indexes.uniq)
        pivoted_dataframe = Daru::DataFrame.new({}, index: df_index, order: df_vectors)

        super_hash.each do |row_index, sub_h|
          sub_h.each do |vector_index, val|
            pivoted_dataframe[symbolize(vector_index)][symbolize(row_index)] = val
          end
        end
        return pivoted_dataframe
      else
        grouped.send(aggregate_function)
      end
    end

    # Merge vectors from two DataFrames. In case of name collision, 
    # the vectors names are changed to x_1, x_2 ....
    #
    # @return {Daru::DataFrame}
    def merge other_df
      raise "Number of rows must be equal in this: #{nrows} and other: #{other_df.nrows}" unless nrows == other_df.nrows

      new_fields = (@vectors.to_a + other_df.vectors.to_a)
                        .recode_repeated
                        .map(&:to_sym)
      df_new     = DataFrame.new({}, order: new_fields)

      (0...nrows).to_a.each do |i|
        row = self.row[i].to_a + other_df.row[i].to_a
        df_new.add_row(row)
      end

      df_new.update
      df_new
    end

    # Join 2 DataFrames by given fields
    # type is one of :left and :inner, default is :left
    #
    # Untested! Use at your own risk.
    # 
    # @return {Daru::DataFrame}
    def join(other_ds,fields_1=[],fields_2=[],type=:left)
      fields_new = other_ds.vectors.to_a - fields_2
      fields     =     self.vectors.to_a + fields_new

      other_ds_hash = {}
      other_ds.each_row do |row|
        key = row.to_hash.select { |k,v| fields_2.include?(k) }.values
        value = row.to_hash.select { |k,v| fields_new.include?(k) }

        if other_ds_hash[key].nil?
          other_ds_hash[key] = [value]
        else
          other_ds_hash[key] << value
        end
      end

      new_ds = DataFrame.new({}, order: fields)

      self.each_row do |row|
        key = row.to_hash.select{|k,v| fields_1.include?(k)}.values
        new_case = row.to_hash

        if other_ds_hash[key].nil?
          if type == :left
            fields_new.each{|field| new_case[field] = nil}
            new_ds.add_row(Daru::Vector.new(new_case))
          end
        else
          other_ds_hash[key].each do |new_values|
            new_ds.add_row(Daru::Vector.new(new_case.merge(new_values)))
          end
        end
      end

      new_ds
    end


    # Creates a new dataset for one to many relations
    # on a dataset, based on pattern of field names.
    #
    # for example, you have a survey for number of children
    # with this structure:
    #   id, name, child_name_1, child_age_1, child_name_2, child_age_2
    # with
    #   ds.one_to_many([:id], "child_%v_%n"
    # the field of first parameters will be copied verbatim
    # to new dataset, and fields which responds to second
    # pattern will be added one case for each different %n.
    # 
    # == Usage
    #   cases=[
    #     ['1','george','red',10,'blue',20,nil,nil],
    #     ['2','fred','green',15,'orange',30,'white',20],
    #     ['3','alfred',nil,nil,nil,nil,nil,nil]
    #   ]
    #   ds=Daru::DataFrame.rows(cases, order: [:id, :name, :car_color1, :car_value1, :car_color2, :car_value2, :car_color3, :car_value3])
    #   ds.one_to_many([:id],'car_%v%n').to_matrix
    #   => Matrix[
    #      ["red", "1", 10],
    #      ["blue", "1", 20],
    #      ["green", "2", 15],
    #      ["orange", "2", 30],
    #      ["white", "2", 20]
    #      ]
    #
    def one_to_many(parent_fields, pattern)
      re      = Regexp.new pattern.gsub("%v","(.+?)").gsub("%n","(\\d+?)")
      ds_vars = parent_fields.dup
      vars    = []
      max_n   = 0
      h       = parent_fields.inject({}) { |a,v| 
        a[v] = Daru::Vector.new([])
        a 
      }
      # Adding _row_id
      h['_col_id'] = Daru::Vector.new([])
      ds_vars.push('_col_id')

      @vectors.each do |f|
        if f =~ re
          if !vars.include? $1
            vars.push($1)
            h[$1] = Daru::Vector.new([])
          end
          max_n = $2.to_i if max_n < $2.to_i
        end
      end
      ds = DataFrame.new(h, order: ds_vars+vars)

      each_row do |row|
        row_out = {}
        parent_fields.each do |f|
          row_out[f] = row[f]
        end

        max_n.times do |n1|
          n  = n1+1
          any_data = false
          vars.each do |v|
            data = row[pattern.gsub("%v",v.to_s).gsub("%n",n.to_s)]
            row_out[v] = data
            any_data = true if !data.nil?
          end

          if any_data
            row_out['_col_id'] = n
            ds.add_row(row_out)
          end
        end
      end
      ds.update
      ds
    end

    def add_vectors_by_split_recode(name_, join='-', sep=Daru::SPLIT_TOKEN)
      split = self[name_].split_by_separator(sep)
      i = 1
      split.each { |k,v|
        new_field = name_.to_s + join + i.to_s
        v.rename name_.to_s + ":" + k.to_s
        self[new_field.to_sym] = v
        i += 1
      }
    end

    # Create a sql, basen on a given Dataset
    # 
    # == Arguments
    # 
    # * table - String specifying name of the table that will created in SQL.
    # * charset - Character set. Default is "UTF8".
    # 
    # == Usage
    #
    #  ds = Daru::DataFrame.new({
    #   :id   => Daru::Vector.new([1,2,3,4,5]),
    #   :name => Daru::Vector.new(%w{Alex Peter Susan Mary John})
    #  })
    #  ds.create_sql('names')
    #   ==>"CREATE TABLE names (id INTEGER,\n name VARCHAR (255)) CHARACTER SET=UTF8;"
    #
    def create_sql(table,charset="UTF8")
      sql    = "CREATE TABLE #{table} ("
      fields = self.vectors.to_a.collect do |f|
        v = self[f]
        f.to_s + " " + v.db_type
      end

      sql + fields.join(",\n ")+") CHARACTER SET=#{charset};"
    end

    # Convert all numeric vectors to GSL::Matrix
    def to_gsl
      numerics_as_arrays = []
      numeric_vectors.each do |n|
        numerics_as_arrays << self[n].to_a
      end

      GSL::Matrix.alloc *numerics_as_arrays.transpose
    end

    # Convert all vectors of type *:numeric* into a Matrix.
    def to_matrix
      numerics_as_arrays = []
      each_vector do |vector|
        numerics_as_arrays << vector.to_a if(vector.type == :numeric)
      end

      Matrix.columns numerics_as_arrays
    end

    # Return a Nyaplot::DataFrame from the data of this DataFrame.
    def to_nyaplotdf
      Nyaplot::DataFrame.new(to_a[0])
    end

    # Convert all vectors of type *:numeric* and not containing nils into an NMatrix.
    def to_nmatrix
      numerics_as_arrays = []
      each_vector do |vector|
        numerics_as_arrays << vector.to_a if(vector.type == :numeric and 
          vector.missing_positions.size == 0)
      end

      numerics_as_arrays.transpose.to_nm
    end
    
    # Converts the DataFrame into an array of hashes where key is vector name
    # and value is the corresponding element. The 0th index of the array contains 
    # the array of hashes while the 1th index contains the indexes of each row 
    # of the dataframe. Each element in the index array corresponds to its row 
    # in the array of hashes, which has the same index.
    def to_a
      arry = [[],[]]
      self.each_row do |row|
        arry[0] << row.to_hash
      end
      arry[1] = @index.to_a

      arry
    end

    def to_json no_index=true
      if no_index
        self.to_a[0].to_json
      else
        self.to_a.to_json
      end
    end

    # Converts DataFrame to a hash with keys as vector names and values as
    # the corresponding vectors.
    def to_hash
      hsh = {}
      @vectors.each_with_index do |vec_name, idx|
        hsh[vec_name] = @data[idx]
      end

      hsh
    end

    # Convert to html for IRuby.
    def to_html threshold=30
      html = "<table>" + 
        "<tr>" +
          "<th colspan=\"#{@vectors.size+1}\">" + 
            "Daru::DataFrame:#{self.object_id} " + " rows: #{nrows} " + " cols: #{ncols}" 
          "</th>" +
        "</tr>"
      html +='<tr><th></th>'
      @vectors.each { |vector| html += '<th>' + vector.to_s + '</th>' }
      html += '</tr>'

      @index.each_with_index do |index, num|
        html += '<tr>'
        html += '<td>' + index.to_s + '</td>'

        self.row[index].each do |element|
          html += '<td>' + element.to_s + '</td>'
        end

        html += '</tr>'
        if num > threshold
          html += '<tr>'
          (@vectors + 1).size.times { html += '<td>...</td>' }
          html += '</tr>'

          last_index = @index.to_a.last
          last_row = self.row[last_index]
          html += '<tr>'
          html += "<td>" + last_index.to_s + "</td>"
          (0..(ncols - 1)).to_a.each do |i|
            html += '<td>' + last_row[i].to_s + '</td>' 
          end
          html += '</tr>'
          break
        end
      end
      html += '</table>'

      html
    end

    def to_s
      to_html
    end

    # Method for updating the metadata (i.e. missing value positions) of the
    # after assingment/deletion etc. are complete. This is provided so that
    # time is not wasted in creating the metadata for the vector each time
    # assignment/deletion of elements is done. Updating data this way is called
    # lazy loading. To set or unset lazy loading, see the .lazy_update= method.
    def update
      @data.each { |v| v.update } if Daru.lazy_update
    end

    def rename new_name
      if new_name.is_a?(Numeric)
        @name = new_name 
        return
      end
      @name = new_name.to_sym
    end

    # Write this DataFrame to a CSV file.
    #
    # == Arguements
    #
    # * filename - Path of CSV file where the DataFrame is to be saved.
    # 
    # == Options
    # 
    # * convert_comma - If set to *true*, will convert any commas in any
    # of the data to full stops ('.').
    # All the options accepted by CSV.read() can also be passed into this 
    # function.
    def write_csv filename, opts={}
      Daru::IO.dataframe_write_csv self, filename, opts
    end

    # Write this dataframe to an Excel Spreadsheet
    # 
    # == Arguments
    # 
    # * filename - The path of the file where the DataFrame should be written.
    def write_excel filename, opts={}
      Daru::IO.dataframe_write_excel self, filename, opts
    end

    # Insert each case of the Dataset on the selected table
    #
    # == Arguments
    # 
    # * dbh - DBI database connection object.
    # * query - Query string.
    # 
    # == Usage
    #
    #  ds = Daru::DataFrame.new({:id=>Daru::Vector.new([1,2,3]), :name=>Daru::Vector.new(["a","b","c"])})
    #  dbh = DBI.connect("DBI:Mysql:database:localhost", "user", "password")
    #  ds.write_sql(dbh,"test")
    def write_sql dbh, table
      Daru::IO.dataframe_write_sql self, dbh, table
    end


    # Use marshalling to save dataframe to a file.
    def save filename
      Daru::IO.save self, filename
    end

    def _dump depth
      Marshal.dump({
        data:  @data, 
        index: @index.to_a, 
        order: @vectors.to_a,
        name:  @name
        })
    end

    def self._load data
      h = Marshal.load data
      Daru::DataFrame.new(h[:data], 
        index: h[:index], 
        order: h[:order],
        name:  h[:name])
    end

    # Change dtypes of vectors by supplying a hash of :vector_name => :new_dtype
    # 
    # == Usage
    #   df = Daru::DataFrame.new({a: [1,2,3], b: [1,2,3], c: [1,2,3]})
    #   df.recast a: :nmatrix, c: :nmatrix
    def recast opts={}
      opts.each do |vector_name, dtype|
        self[vector_name].cast(dtype: dtype)
      end
    end

    # Transpose a DataFrame, tranposing elements and row, column indexing.
    def transpose
      arrys = []
      each_vector do |vec|
        arrys << vec.to_a
      end

      Daru::DataFrame.new(arrys.transpose, index: @vectors, order: @index, dtype: @dtype, name: @name)
    end

    # Pretty print in a nice table format for the command line (irb/pry/iruby)
    def inspect spacing=10, threshold=15
      longest = [@name.to_s.size,
                 (@vectors.map(&:to_s).map(&:size).max || 0), 
                 (@index  .map(&:to_s).map(&:size).max || 0),
                 (@data   .map{ |v| v.map(&:to_s).map(&:size).max}.max || 0)].max

      name      = @name || 'nil'
      content   = ""
      longest   = spacing if longest > spacing
      formatter = "\n"

      (@vectors.size + 1).times { formatter += "%#{longest}.#{longest}s " }
      content += "\n#<" + self.class.to_s + ":" + self.object_id.to_s + " @name = " + 
                    name.to_s + " @size = " + @size.to_s + ">"
      content += sprintf formatter, "" , *@vectors.map(&:to_s)
      row_num  = 1

      self.each_row_with_index do |row, index|
        content += sprintf formatter, index.to_s, *row.to_hash.values.map { |e| (e || 'nil').to_s }
        row_num += 1
        if row_num > threshold
          dots = []

          (@vectors.size + 1).times { dots << "..." }
          content += sprintf formatter, *dots
          break
        end
      end
      content += "\n"

      content
    end

    def == other
      self.class == other.class   and 
      @size      == other.size    and 
      @index     == other.index   and
      @vectors   == other.vectors and 
      @vectors.to_a.all? { |v| self[v] == other[v] }
    end

    def method_missing(name, *args, &block)
      if md = name.match(/(.+)\=/)
        insert_or_modify_vector name[/(.+)\=/].delete("=").to_sym, args[0]
      elsif self.has_vector? name
        self[name]
      else
        super(name, *args, &block)
      end
    end

   private

    def possibly_multi_index? index
      if @index.is_a?(MultiIndex)
        Daru::MultiIndex.from_tuples(index)
      else
        Daru::Index.new(index)
      end
    end

    def quick_sort vector_order, index, by, ascending
      recursive_quick_sort vector_order, index, by, ascending, 0, @size-1
    end

    # == Arguments
    # 
    # vector_order - 
    # index - 
    # by -
    # ascending -
    # left_lower -
    # right_upper -
    def recursive_quick_sort vector_order, index, by, ascending, left_lower, right_upper
      if left_lower < right_upper
        left_upper, right_lower = partition(vector_order, index, by, ascending, left_lower, right_upper)
        if left_upper - left_lower < right_upper - right_lower
          recursive_quick_sort(vector_order, index, by, ascending, left_lower, left_upper)
          recursive_quick_sort(vector_order, index, by, ascending, right_lower, right_upper)
        else
          recursive_quick_sort(vector_order, index, by, ascending, right_lower, right_upper)
          recursive_quick_sort(vector_order, index, by, ascending, left_lower, left_upper)
        end
      end
    end

    def partition vector_order, index, by, ascending, left_lower, right_upper
      mindex = (left_lower + right_upper) / 2
      mvalues = vector_order.inject([]) { |a, vector_name| a << self[vector_name][mindex]; a }
      i = left_lower
      j = right_upper
      descending = ascending.map { |a| !a }

      i += 1 while(keep?(i, mvalues, vector_order, ascending , by, 0))
      j -= 1 while(keep?(j, mvalues, vector_order, descending, by, 0))

      while i < j - 1
        @data.each do |vector|
          vector[i], vector[j] = vector[j], vector[i]
        end
        index[i], index[j] = index[j], index[i]
        i += 1
        j -= 1

        i += 1 while(keep?(i, mvalues, vector_order, ascending , by,0))
        j -= 1 while(keep?(j, mvalues, vector_order, descending, by,0))
      end

      if i <= j
        if i < j
          @data.each do |vector|
            vector[i], vector[j] = vector[j], vector[i]
          end
          index[i], index[j] = index[j], index[i]
        end
        i += 1
        j -= 1
      end

      [j,i]
    end

    def keep? current_index, mvalues, vector_order, sort_order, by, vector_order_index
      vector_name = vector_order[vector_order_index]
      if vector_name
        vec = self[vector_name]
        eval = by[vector_name].call(vec[current_index], mvalues[vector_order_index])

        if sort_order[vector_order_index] # sort in ascending order
          return false if eval == 1
          return true if eval == -1
          if eval == 0
            keep?(current_index, mvalues, vector_order, sort_order, by, vector_order_index + 1)
          end
        else # sort in descending order
          return false if eval == -1
          return true  if eval == 1
          if eval == 0
            keep?(current_index, mvalues, vector_order, sort_order, by, vector_order_index + 1)
          end
        end
      end
    end

    def create_logic_blocks vector_order, by={}
      universal_block = lambda { |a,b| a <=> b }
      vector_order.each do |vector|
        by[vector] ||= universal_block
      end

      by
    end

    def sort_order_array vector_order, ascending
      if ascending.is_a?(Array)
        raise ArgumentError, "Specify same number of vector names and sort orders" if
          vector_order.size != ascending.size
        return ascending
      else
        Array.new(vector_order.size, ascending)
      end
    end

    def vectors_index_for location
      if @vectors.include?(location)
        @vectors[location]
      elsif location[0].is_a?(Integer)
        location[0]
      end
    end

    def access_vector *names
      location = names[0]

      return dup(@vectors[location]) if location.is_a?(Range)
      if @vectors.is_a?(MultiIndex)
        pos = @vectors[names]

        if pos.is_a?(Integer)
          return @data[pos]
        else # MultiIndex
          new_vectors = pos.map do |tuple|
            @data[@vectors[tuple]]
          end

          if !location.is_a?(Range) and names.size < @vectors.width
            pos = pos.drop_left_level names.size
          end

          Daru::DataFrame.new(
            new_vectors, index: @index, order: pos)
        end
      else
        return @data[@vectors[location]] unless names[1]

        new_vcs = {}
        names.each do |name|
          name = name.to_sym unless name.is_a?(Integer)
          new_vcs[name] = @data[@vectors[name]]
        end
        Daru::DataFrame.new new_vcs, order: new_vcs.keys, index: @index, name: @name
      end
    end

    def access_row *names
      location = names[0]

      if @index.is_a?(MultiIndex)
        pos = @index[names]
        if pos.is_a?(Integer)
          return Daru::Vector.new(populate_row_for(pos), index: @vectors, name: pos)
        else
          new_rows = pos.map { |tuple| populate_row_for(tuple) }
          
          if !location.is_a?(Range) and names.size < @index.width
            pos = pos.drop_left_level names.size
          end

          Daru::DataFrame.rows(
            new_rows, order: @vectors, name: @name, index: pos)
        end
      else
        if names[1].nil? 
          if location.is_a?(Range)
            names = @index[location]
          else
            row  = []
            name = @index[location]
            @vectors.each do |vector|
              row << @data[@vectors[vector]][name]
            end

            return Daru::Vector.new(row, index: @vectors, name: set_name(location))
          end
        end
        # Access multiple rows
        rows = []
        names.each do |name|
          rows << self.row[name]
        end
        
        Daru::DataFrame.rows rows, index: names ,name: @name        
      end
    end

    def populate_row_for pos
      @vectors.map do |vector|
        @data[@vectors[vector]][pos]
      end
    end

    def insert_or_modify_vector name, vector
      unless @vectors.is_a?(MultiIndex)   
        name = name[0]
      end

      @vectors = @vectors | [name] if !@vectors.include?(name)
      v        = nil
      
      if @index.empty?
        v = vector.is_a?(Daru::Vector) ? vector : Daru::Vector.new(vector.to_a)  
        @index = v.index
        @data[@vectors[name]] = v
        set_size

        @data.map! do |v|
          if v.size == 0
            Daru::Vector.new([nil]*@size, name: set_name(name), index: @index)
          else
            v
          end
        end
      else
        if vector.is_a?(Daru::Vector)
          v = Daru::Vector.new [], name: set_name(name), index: @index
          @index.each do |idx|
            if vector.index.include? idx
              v[idx] = vector[idx]
            else
              v[idx] = nil
            end
          end
        else
          raise SizeError,
            "Specified vector of length #{vector.size} cannot be inserted in DataFrame of size #{@size}" if
            @size != vector.size

          v = Daru::Vector.new(vector, name: set_name(name), index: @index)
        end

        @data[@vectors[name]] = v
      end
    end

    def insert_or_modify_row name, vector    
      if index.is_a?(MultiIndex)
        # TODO
      else
        name = name[0]
        v =
        if vector.is_a?(Daru::Vector)
          vector
        else
          Daru::Vector.new(vector, name: set_name(name), index: @vectors)
        end

        if @index.include? name
          @vectors.each do |vector|
            if v.index.include? vector
              @data[@vectors[vector]][name] = v[vector]
            else
              @data[@vectors[vector]][name] = nil
            end
          end
        else
          @index = @index | [name]
          @vectors.each do |vector|
            @data[@vectors[vector]].concat v[vector], name
          end
        end

        set_size
      end
    end

    def create_empty_vectors
      @vectors.each do |name|
        @data << Daru::Vector.new([], name: set_name(name), index: @index)
      end
    end

    def validate_labels
      raise IndexError, "Expected equal number of vector names (#{@vectors.size}) for number of vectors (#{@data.size})." if 
        @vectors and @vectors.size != @data.size

      raise IndexError, "Expected number of indexes same as number of rows" if
        @index and @data[0] and @index.size != @data[0].size
    end

    def validate_vector_sizes
      @data.each do |vector|
        raise IndexError, "Expected vectors with equal length" if vector.size != @size
      end
    end

    def validate
      validate_labels
      validate_vector_sizes
    end

    def all_daru_vectors_in_source? source
      source.values.all? do |vector|
        vector.is_a?(Daru::Vector)
      end
    end

    def set_size
      @size = @index.size
    end

    def named_index_for index
      if @index.include? index
        index
      elsif @index.key index
        @index.key index
      else
        raise IndexError, "Specified index #{index} does not exist."
      end
    end

    def create_vectors_index_with vectors, source
      vectors = source.keys.sort_by { |a| a.to_s } if vectors.nil?

      @vectors =
      unless vectors.is_a?(Index) or vectors.is_a?(MultiIndex)
        Daru::Index.new((vectors + (source.keys - vectors)).uniq)
      else
        vectors
      end
    end

    def all_vectors_have_equal_indexes? source
      idx = source.values[0].index

      source.all? do |name, vector|
        idx == vector.index
      end
    end

    def try_create_index index
      index.kind_of?(Index) ? index : Daru::Index.new(index)
    end

    def set_name potential_name
      potential_name.is_a?(Array) ? potential_name.join.to_sym : potential_name
    end

    def symbolize arry
      symbolized_arry = 
      if arry.all? { |e| e.is_a?(Array) }
        arry.map do |sub_arry|
          sub_arry.map do |e|
            e.is_a?(Numeric) ? e : e.to_sym
          end
        end
      else
        arry.map { |e| e.is_a?(Numeric) ? e : e.to_sym }
      end

      symbolized_arry
    end
  end
end