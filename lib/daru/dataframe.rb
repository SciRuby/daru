$:.unshift File.dirname(__FILE__)

require 'accessors/dataframe_by_row.rb'
require 'accessors/dataframe_by_vector.rb'
require 'maths/arithmetic/dataframe.rb'
require 'maths/statistics/dataframe.rb'
require 'plotting/dataframe.rb'
require 'io/io.rb'

module Daru
  class DataFrame

    include Daru::Maths::Arithmetic::DataFrame
    include Daru::Maths::Statistics::DataFrame
    include Daru::Plotting::DataFrame

    class << self
      # Load data from a CSV file. Specify an optional block to grab the CSV 
      # object and pre-condition it.
      # 
      # == Arguments
      # 
      # * path - Path of the file to load specified as a String.
      # 
      # == Options
      # 
      # Accepts the same options as the Daru::DataFrame constructor and uses those
      # to eventually construct the resulting DataFrame.
      def from_csv path, opts={}, &block
        Daru::IO.from_csv path, opts, &block      
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
      clone   = true unless opts[:clone] == false
      @name   = (opts[:name] || SecureRandom.uuid).to_sym
      @data   = []

      if source.empty?
        @vectors = create_index vectors
        @index   = create_index index
        create_empty_vectors
      else
        case source
        when Array
          if source.all? { |s| s.is_a?(Array) }
            raise ArgumentError, "Number of vectors (#{vectors.size}) should \
              equal order size (#{source.size})" if source.size != vectors.size

            @index   = create_index(index || source[0].size)
            @vectors = create_index(vectors)

            @vectors.each_with_index do |vec,idx|
              @data << Daru::Vector.new(source[idx], index: @index)
            end
          elsif source.all? { |s| s.is_a?(Daru::Vector) }
            hsh = {}
            vectors.each_with_index do |name, idx|
              hsh[name] = source[idx]
            end
            initialize(hsh, index: index, order: vectors, name: @name)
          else # array of hashes
            if vectors.nil?
              @vectors = Daru::Index.new source[0].keys.map(&:to_sym)
            else
              @vectors = Daru::Index.new (vectors + (source[0].keys - vectors)).uniq.map(&:to_sym)
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
              @index = create_index index
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

                @index.each do |idx|
                  @data[@vectors[vector]][idx] = source[vector][idx]
                end
              end
            else
              @data.concat source.values
            end
          else
            @index = create_index(index || source.values[0].size)

            @vectors.each do |name|
              @data << Daru::Vector.new(source[name].dup, name: set_name(name), index: @index)
            end
          end
        end
      end

      set_size
      validate
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
      name   = args[0]
      axis   = args[1]
      vector = args[-1]

      axis = (!axis.is_a?(Symbol) and (axis != :vector or axis != :row)) ? :vector : axis
      if axis == :vector
        insert_or_modify_vector name, vector
      elsif axis == :row        
        insert_or_modify_row name, vector
      else
        raise IndexError, "Expected axis to be row or vector, not #{axis}."
      end
    end

    # Access a vector or set/create a vector. Refer #[] and #[]= docs for details.
    # 
    # == Usage
    #   df.vector[:a] # access vector named ':a'
    #   df.vector[:b] = [1,2,3] # set vector ':b' to [1,2,3]
    def vector
      Daru::Accessors::DataFrameByVector.new(self)
    end

    # Access a vector by name.
    def column name
      vector[name]
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
    def dup
      src = {}
      @vectors.each do |vector|
        src[vector] = @data[@vectors[vector]].dup
      end

      Daru::DataFrame.new src, order: @vectors.dup, index: @index.dup, name: @name
    end

    # Returns a 'view' of the DataFrame, i.e the object ID's of vectors are
    # preserved.
    # 
    # == Arguments
    # 
    # +vectors_to_clone+ - Names of vectors to clone. Optional. Will return
    # a view of the whole data frame otherwise.
    def clone *vectors_to_clone
      return super if vectors_to_clone.empty?

      h = vectors_to_clone.inject({}) do |hsh, vec|
        hsh[vec] = self[vec]
        hsh
      end
      Daru::DataFrame.new(h, clone: false)
    end

    # Creates a new duplicate dataframe containing only rows 
    # without a single missing value.
    def dup_only_valid
      rows_with_nil = @data.inject([]) do |memo, vector|
        memo.concat vector.missing_positions
        memo
      end.uniq

      row_indexes = Array.new(nrows) { |i| i }
      self.row[*(row_indexes - rows_with_nil)]
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

    # Map each vector. Returns a DataFrame whose vectors are modified according
    # to the value returned by the block. As is the case with Enumerable#map,
    # the object returned by each block must be a Daru::Vector for the dataframe
    # to remain relevant.
    def map_vectors(&block)
      return to_enum(:map_vectors) unless block_given?

      self.dup.map_vectors!(&block)
    end

    # Destructive form of #map_vectors
    def map_vectors!(&block)
      return to_enum(:map_vectors!) unless block_given?

      @data.map!(&block)
      self
    end

    # Map vectors alongwith the index.
    def map_vectors_with_index(&block)
      return to_enum(:map_vectors_with_index) unless block_given?

      df = self.dup
      df.each_vector_with_index do |vector, name|
        df[name, :vector] = yield(vector, name)
      end

      df
    end

    # Map each row
    def map_rows(&block)
      return to_enum(:map_rows) unless block_given?

      df = self.dup
      df.each_row_with_index do |row, index|
        df[index, :row] = yield(row)
      end

      df
    end

    def map_rows_with_index(&block)
      return to_enum(:map_rows_with_index) unless block_given?

      df = self.dup
      df.each_row_with_index do |row, index|
        df[index, :row] = yield(row, index)
      end

      df
    end

    # Retrieves a Daru::Vector, based on the result of calculation 
    # performed on each case.
    def collect_rows
      data = []
      each_row do |row|
        data.push yield(row)
      end

      Daru::Vector.new(data)
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
        @index = reassign_index_as(@index.to_a - [idx])
        self.each_vector do |vector|
          vector.delete_at idx
        end
      else
        raise IndexError, "Index #{index} does not exist."
      end

      set_size
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
      !!@vectors[*vector]
    end

    # The first ten elements of the DataFrame
    #
    # @param [Fixnum] quantity (10) The number of elements to display from the top.
    def head quantity=10
      self[0..quantity, :row]
    end

    # The last ten elements of the DataFrame
    # 
    # @param [Fixnum] quantity (10) The number of elements to display from the bottom.
    def tail quantity=10
      self[(@size - quantity)..(@size-1), :row]
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

    # Return the names of all the numeric vectors. Will include vectors with nils
    # alongwith numbers.
    def numeric_vectors
      numerics = []

      each_vector do |vec|
        numerics << vec.name if(vec.type == :numeric)
      end
      numerics
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
      raise ArgumentError, "Specify grouping index" if !opts[:index] or opts[:index].empty?

      index   = opts[:index]
      vectors = opts[:vectors] || []
      aggregate_function = opts[:agg] || :mean
      values = 
      if opts[:values].is_a?(Symbol)
        [opts[:values]]
      elsif opts[:values].is_a?(Array)
        opts[:values]
      else # nil
        (@vectors.to_a - (index | vectors)) & numeric_vectors
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

        df_index = Daru::MultiIndex.new(symbolize(super_hash.keys))

        vector_indexes = []
        super_hash.each_value do |sub_hash|
          vector_indexes.concat sub_hash.keys
        end
        df_vectors = Daru::MultiIndex.new symbolize(vector_indexes.uniq)
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

    # Convert all vectors of type *:numeric* into a Matrix.
    def to_matrix
      numerics_as_arrays = []
      each_vector do |vector|
        numerics_as_arrays << vector.to_a if(vector.type == :numeric)
      end

      Matrix.columns numerics_as_arrays
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
      html  = '<table><tr><th></th>'
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
          break
        end
      end
      html += '</table>'

      html
    end

    def to_s
      to_html
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
        vector[vector_name].cast(dtype: dtype)
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
                 @vectors.map(&:to_s).map(&:size).max, 
                 @index  .map(&:to_s).map(&:size).max,
                 @data   .map{ |v|  v.map(&:to_s).map(&:size).max }.max].max

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
      @index == other.index and @size == other.size and @vectors == other.vectors and 
      @vectors.all? { |vector| self[vector, :vector] == other[vector, :vector] }
    end

    def method_missing(name, *args, &block)
      if md = name.match(/(.+)\=/)
        insert_or_modify_vector name[/(.+)\=/].delete("=").to_sym, args[0]
      elsif self.has_vector? name
        self[name, :vector]
      else
        super(name, *args, &block)
      end
    end

   private

    def possibly_multi_index? index
      if @index.is_a?(MultiIndex)
        Daru::MultiIndex.new(index)
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
      mvalues = vector_order.inject([]) { |a, vector_name| a << vector[vector_name][mindex]; a }
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
        vec = vector[vector_name]
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
      if @vectors.is_a?(MultiIndex)
        pos = vectors_index_for names

        if pos.is_a?(Integer)
          return @data[pos]
        else # MultiIndex
          new_vectors = pos.map do |tuple|
            @data[vectors_index_for(names + tuple)]
          end
          Daru::DataFrame.new(new_vectors, index: @index, order: Daru::MultiIndex.new(pos.to_a))
        end
      else
        unless names[1]
          pos = vectors_index_for location
          return @data[pos]
        end

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
        pos = row_index_for names
        if pos.is_a?(Integer)
          return Daru::Vector.new(populate_row_for(pos), index: @vectors, name: pos)
        else
          new_rows =
          if location.is_a?(Range)
            pos.map { |tuple| populate_row_for(tuple) }
          else
            pos.map { |tuple| populate_row_for(names + tuple) }
          end
          
          Daru::DataFrame.rows(new_rows, order: @vectors, name: @name, 
            index: Daru::MultiIndex.new(pos.to_a))
        end
      else
        if names[1].nil? 
          if location.is_a?(Range)
            index_arry = @index.to_a

            range = 
            if location.first.is_a?(Numeric)
              location
            else
              first_index = index_arry.index location.first
              last_index  = index_arry.index location.last

              first_index..last_index
            end

            names = index_arry[range]
          else
            row  = []
            name = named_index_for names[0]
            @vectors.each do |vector|
              row << @data[@vectors[vector]][name]
            end

            return Daru::Vector.new(row, index: @vectors, name: set_name(name))
          end
        end
        # Access multiple rows
        rows = []
        names.each do |name|
          rows << self.row[name]
        end
        
        Daru::DataFrame.rows rows, name: @name        
      end
    end

    def row_index_for location
      if @index.include?(location) or location[0].is_a?(Range)
        @index[location]
      elsif location[0].is_a?(Integer)
        location[0]
      end
    end

    def populate_row_for pos
      @vectors.map do |vector|
        @data[@vectors[vector]][pos]
      end
    end

    def insert_or_modify_vector name, vector
      @vectors = reassign_index_as(@vectors + name)
      v        = nil

      if vector.is_a?(Daru::Vector)
        v = Daru::Vector.new [], name: set_name(name), index: @index
        @index.each do |idx|
          v[idx] = vector[idx]
        end
      else
        raise Exception, "Specified vector of length #{vector.size} cannot be inserted in DataFrame of size #{@size}" if
          @size != vector.size

        v = Daru::Vector.new(vector, name: set_name(name), index: @index)
      end

      @data[@vectors[name]] = v
    end

    def insert_or_modify_row name, vector      
      if @index.include? name
        v = vector.dv(name, @vectors, @dtype) 

        @vectors.each do |vector|
          @data[@vectors[vector]][name] = v[vector] 
        end
      else
        @index = reassign_index_as(@index + name)
        v      = Daru::Vector.new(vector, name: set_name(name), index: @vectors)

        @vectors.each do |vector|
          @data[@vectors[vector]].concat v[vector], name
        end
      end

      set_size
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
      vectors = source.keys.sort if vectors.nil?

      unless vectors.is_a?(Index) or vectors.is_a?(MultiIndex)
        @vectors = Daru::Index.new (vectors + (source.keys - vectors)).uniq.map(&:to_sym)
      else
        @vectors = vectors
      end
    end

    def all_vectors_have_equal_indexes? source
      idx = source.values[0].index

      source.all? do |name, vector|
        idx == vector.index
      end
    end

    def reassign_index_as new_index
      Daru::Index.new new_index
    end

    def create_index index
      index.is_a?(MultiIndex) ? index : Daru::Index.new(index)
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