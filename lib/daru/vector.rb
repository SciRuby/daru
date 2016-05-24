require 'daru/maths/arithmetic/vector.rb'
require 'daru/maths/statistics/vector.rb'
require 'daru/plotting/vector.rb'
require 'daru/accessors/array_wrapper.rb'
require 'daru/accessors/nmatrix_wrapper.rb'
require 'daru/accessors/gsl_wrapper.rb'

module Daru
  class Vector
    include Enumerable
    include Daru::Maths::Arithmetic::Vector
    include Daru::Maths::Statistics::Vector
    include Daru::Plotting::Vector if Daru.has_nyaplot?

    def each(&block)
      return to_enum(:each) unless block_given?

      @data.each(&block)
      self
    end

    def each_index(&block)
      return to_enum(:each_index) unless block_given?

      @index.each(&block)
      self
    end

    def each_with_index
      return to_enum(:each_with_index) unless block_given?

      @index.each { |i| yield(self[i], i) }
      self
    end

    def map!(&block)
      return to_enum(:map!) unless block_given?
      @data.map!(&block)
      update
      self
    end

    # The name of the Daru::Vector. String.
    attr_reader :name
    # The row index. Can be either Daru::Index or Daru::MultiIndex.
    attr_reader :index
    # The total number of elements of the vector.
    attr_reader :size
    # The underlying dtype of the Vector. Can be either :array, :nmatrix or :gsl.
    attr_reader :dtype
    # If the dtype is :nmatrix, this attribute represents the data type of the
    # underlying NMatrix object. See NMatrix docs for more details on NMatrix
    # data types.
    attr_reader :nm_dtype
    # An Array or the positions in the vector that are being treated as 'missing'.
    attr_reader :missing_positions
    # Store a hash of labels for values. Supplementary only. Recommend using index
    # for proper usage.
    attr_accessor :labels
    # Store vector data in an array
    attr_reader :data
    # Attach arbitrary metadata to vector (usu a hash)
    attr_accessor :metadata

    # Create a Vector object.
    #
    # == Arguments
    #
    # @param source[Array,Hash] - Supply elements in the form of an Array or a
    # Hash. If Array, a numeric index will be created if not supplied in the
    # options. Specifying more index elements than actual values in *source*
    # will insert *nil* into the surplus index elements. When a Hash is specified,
    # the keys of the Hash are taken as the index elements and the corresponding
    # values as the values that populate the vector.
    #
    # == Options
    #
    # * +:name+  - Name of the vector
    #
    # * +:index+ - Index of the vector
    #
    # * +:dtype+ - The underlying data type. Can be :array, :nmatrix or :gsl.
    # Default :array.
    #
    # * +:nm_dtype+ - For NMatrix, the data type of the numbers. See the NMatrix docs for
    # further information on supported data type.
    #
    # * +:missing_values+ - An Array of the values that are to be treated as 'missing'.
    # nil is the default missing value.
    #
    # == Usage
    #
    #   vecarr = Daru::Vector.new [1,2,3,4], index: [:a, :e, :i, :o]
    #   vechsh = Daru::Vector.new({a: 1, e: 2, i: 3, o: 4})
    def initialize source, opts={}
      index = nil
      if source.is_a?(Hash)
        index  = source.keys
        source = source.values
      else
        index  = opts[:index]
        source ||= []
      end
      name = opts[:name]
      set_name name

      @metadata = opts[:metadata] || {}

      @data  = cast_vector_to(opts[:dtype] || :array, source, opts[:nm_dtype])
      @index = try_create_index(index || @data.size)

      if @index.size > @data.size
        cast(dtype: :array) # NM with nils seg faults
        (@index.size - @data.size).times { @data << nil }
      elsif @index.size < @data.size
        raise IndexError, "Expected index size >= vector size. Index size : #{@index.size}, vector size : #{@data.size}"
      end

      @possibly_changed_type = true
      set_missing_values opts[:missing_values]
      set_missing_positions
      set_size
    end

    # Create a new vector by specifying the size and an optional value
    # and block to generate values.
    #
    # == Description
    #
    # The *new_with_size* class method lets you create a Daru::Vector
    # by specifying the size as the argument. The optional block, if
    # supplied, is run once for populating each element in the Vector.
    #
    # The result of each run of the block is the value that is ultimately
    # assigned to that position in the Vector.
    #
    # == Options
    # :value
    # All the rest like .new
    def self.new_with_size n, opts={}, &block
      value = opts[:value]
      opts.delete :value
      if block
        Daru::Vector.new Array.new(n) { |i| block.call(i) }, opts
      else
        Daru::Vector.new Array.new(n) { value }, opts
      end
    end

    # Create a vector using (almost) any object
    # * Array: flattened
    # * Range: transformed using to_a
    # * Daru::Vector
    # * Numeric and string values
    #
    # == Description
    #
    # The `Vector.[]` class method creates a vector from almost any
    # object that has a `#to_a` method defined on it. It is similar
    # to R's `c` method.
    #
    # == Usage
    #
    #   a = Daru::Vector[1,2,3,4,6..10]
    #   #=>
    #   # <Daru::Vector:99448510 @name = nil @size = 9 >
    #   #   nil
    #   # 0   1
    #   # 1   2
    #   # 2   3
    #   # 3   4
    #   # 4   6
    #   # 5   7
    #   # 6   8
    #   # 7   9
    #   # 8  10
    def self.[](*args)
      values = []
      args.each do |a|
        case a
        when Array
          values.concat a.flatten
        when Daru::Vector
          values.concat a.to_a
        when Range
          values.concat a.to_a
        else
          values << a
        end
      end
      Daru::Vector.new(values)
    end

    # Get one or more elements with specified index or a range.
    #
    # == Usage
    #   # For vectors employing single layer Index
    #
    #   v[:one, :two] # => Daru::Vector with indexes :one and :two
    #   v[:one]       # => Single element
    #   v[:one..:three] # => Daru::Vector with indexes :one, :two and :three
    #
    #   # For vectors employing hierarchial multi index
    #
    def [](*input_indexes)
      # Get a proper index object
      indexes = @index[*input_indexes]

      # If one object is asked return it
      return @data[indexes] if indexes.is_a? Numeric

      # Form a new Vector using indexes and return it
      Daru::Vector.new(
        indexes.map { |loc| @data[@index[loc]] },
        name: @name, metadata: @metadata.dup, index: indexes.conform(input_indexes), dtype: @dtype
      )
    end

    # Just like in Hashes, you can specify the index label of the Daru::Vector
    # and assign an element an that place in the Daru::Vector.
    #
    # == Usage
    #
    #   v = Daru::Vector.new([1,2,3], index: [:a, :b, :c])
    #   v[:a] = 999
    #   #=>
    #   ##<Daru::Vector:90257920 @name = nil @size = 3 >
    #   #    nil
    #   #  a 999
    #   #  b   2
    #   #  c   3
    def []=(*location, value)
      cast(dtype: :array) if value.nil? && dtype != :array

      @possibly_changed_type = true if @type == :object  && (value.nil? ||
        value.is_a?(Numeric))
      @possibly_changed_type = true if @type == :numeric && (!value.is_a?(Numeric) &&
        !value.nil?)

      pos = @index[*location]

      if pos.is_a?(Numeric)
        @data[pos] = value
      else
        pos.each { |tuple| self[tuple] = value }

        # FIXME: Can't guess how to activate this rescue branch -- zverok
        #
        # begin
        #   pos.each { |tuple| self[tuple] = value }
        # rescue NoMethodError
        #   raise IndexError, "Specified index #{pos.inspect} does not exist."
        # end
      end

      set_size
      set_missing_positions unless Daru.lazy_update
    end

    # The values to be treated as 'missing'. *nil* is the default missing
    # type. To set missing values see the missing_values= method.
    def missing_values
      @missing_values.keys
    end

    # Assign an Array to treat certain values as 'missing'.
    #
    # == Usage
    #
    #   v = Daru::Vector.new [1,2,3,4,5]
    #   v.missing_values = [3]
    #   v.update
    #   v.missing_positions
    #   #=> [2]
    def missing_values= values
      set_missing_values values
      set_missing_positions unless Daru.lazy_update
    end

    # Method for updating the metadata (i.e. missing value positions) of the
    # after assingment/deletion etc. are complete. This is provided so that
    # time is not wasted in creating the metadata for the vector each time
    # assignment/deletion of elements is done. Updating data this way is called
    # lazy loading. To set or unset lazy loading, see the .lazy_update= method.
    def update
      Daru.lazy_update and set_missing_positions
    end

    # Two vectors are equal if the have the exact same index values corresponding
    # with the exact same elements. Name is ignored.
    def == other
      case other
      when Daru::Vector
        @index == other.index && @size == other.size &&
          @index.all? { |index| self[index] == other[index] }
      else
        super
      end
    end

    # !@method eq
    #   Uses `==` and returns `true` for each **equal** entry
    #   @param [#==, Daru::Vector] If scalar object, compares it with each
    #     element in self. If Daru::Vector, compares elements with same indexes.
    #   @example (see #where)
    # !@method not_eq
    #   Uses `!=` and returns `true` for each **unequal** entry
    #   @param [#!=, Daru::Vector] If scalar object, compares it with each
    #     element in self. If Daru::Vector, compares elements with same indexes.
    #   @example (see #where)
    # !@method lt
    #   Uses `<` and returns `true` for each entry **less than** the supplied object
    #   @param [#<, Daru::Vector] If scalar object, compares it with each
    #     element in self. If Daru::Vector, compares elements with same indexes.
    #   @example (see #where)
    # !@method lteq
    #   Uses `<=` and returns `true` for each entry **less than or equal to** the supplied object
    #   @param [#<=, Daru::Vector] If scalar object, compares it with each
    #     element in self. If Daru::Vector, compares elements with same indexes.
    #   @example (see #where)
    # !@method mt
    #   Uses `>` and returns `true` for each entry **more than** the supplied object
    #   @param [#>, Daru::Vector] If scalar object, compares it with each
    #     element in self. If Daru::Vector, compares elements with same indexes.
    #   @example (see #where)
    # !@method mteq
    #   Uses `>=` and returns `true` for each entry **more than or equal to** the supplied object
    #   @param [#>=, Daru::Vector] If scalar object, compares it with each
    #     element in self. If Daru::Vector, compares elements with same indexes.
    #   @example (see #where)

    # Define the comparator methods with metaprogramming. See documentation
    # written above for functionality of each method. Use these methods with the
    # `where` method to obtain the corresponding Vector/DataFrame.
    {
      eq: :==,
      not_eq: :!=,
      lt: :<,
      lteq: :<=,
      mt: :>,
      mteq: :>=
    }.each do |method, operator|
      define_method(method) do |other|
        mod = Daru::Core::Query
        if other.is_a?(Daru::Vector)
          mod.apply_vector_operator operator, self, other
        else
          mod.apply_scalar_operator operator, @data,other
        end
      end
    end
    alias :gt :mt
    alias :gteq :mteq

    # Comparator for checking if any of the elements in *other* exist in self.
    #
    # @param [Array, Daru::Vector] other A collection which has elements that
    #   need to be checked for in self.
    # @example Usage of `in`.
    #   vector = Daru::Vector.new([1,2,3,4,5])
    #   vector.where(vector.in([3,5]))
    #   #=>
    #   ##<Daru::Vector:82215960 @name = nil @size = 2 >
    #   #    nil
    #   #  2   3
    #   #  4   5
    def in other
      other = Hash[other.zip(Array.new(other.size, 0))]
      Daru::Core::Query::BoolArray.new(
        @data.each_with_object([]) do |d, memo|
          memo << (other.key?(d) ? true : false)
        end
      )
    end

    # Return a new vector based on the contents of a boolean array. Use with the
    # comparator methods to obtain meaningful results. See this notebook for
    # a good overview of using #where.
    #
    # @param [Daru::Core::Query::BoolArray, Array<TrueClass, FalseClass>] bool_arry The
    #   collection containing the true of false values. Each element in the Vector
    #   corresponding to a `true` in the bool_arry will be returned alongwith it's
    #   index.
    # @exmaple Usage of #where.
    #   vector = Daru::Vector.new([2,4,5,51,5,16,2,5,3,2,1,5,2,5,2,1,56,234,6,21])
    #
    #   # Simple logic statement passed to #where.
    #   vector.where(vector.eq(5).or(vector.eq(1)))
    #   # =>
    #   ##<Daru::Vector:77626210 @name = nil @size = 7 >
    #   #    nil
    #   #  2   5
    #   #  4   5
    #   #  7   5
    #   # 10   1
    #   # 11   5
    #   # 13   5
    #   # 15   1
    #
    #   # A somewhat more complex logic statement
    #   vector.where((vector.eq(5) | vector.lteq(1)) & vector.in([4,5,1]))
    #   #=>
    #   ##<Daru::Vector:81072310 @name = nil @size = 7 >
    #   #    nil
    #   #  2   5
    #   #  4   5
    #   #  7   5
    #   # 10   1
    #   # 11   5
    #   # 13   5
    #   # 15   1
    def where bool_arry
      Daru::Core::Query.vector_where @data.to_a, @index.to_a, bool_arry, dtype
    end

    def head q=10
      self[0..(q-1)]
    end

    def tail q=10
      start = [@size - q, 0].max
      self[start..(@size-1)]
    end

    def empty?
      @index.empty?
    end

    # Reports whether missing data is present in the Vector.
    def has_missing_data?
      !missing_positions.empty?
    end
    alias :flawed? :has_missing_data?

    # Append an element to the vector by specifying the element and index
    def concat element, index
      raise IndexError, 'Expected new unique index' if @index.include? index

      @index |= [index]
      @data[@index[index]] = element

      set_size
      set_missing_positions unless Daru.lazy_update
    end
    alias :push :concat
    alias :<< :concat

    # Cast a vector to a new data type.
    #
    # == Options
    #
    # * +:dtype+ - :array for Ruby Array. :nmatrix for NMatrix.
    def cast opts={}
      dt = opts[:dtype]
      raise ArgumentError, "Unsupported dtype #{opts[:dtype]}" unless
        dt == :array || dt == :nmatrix || dt == :gsl

      @data = cast_vector_to dt unless @dtype == dt
    end

    # Delete an element by value
    def delete element
      delete_at index_of(element)
    end

    # Delete element by index
    def delete_at index
      @data.delete_at @index[index]
      @index = Daru::Index.new(@index.to_a - [index])

      set_size
      set_missing_positions unless Daru.lazy_update
    end

    # The type of data contained in the vector. Can be :object or :numeric. If
    # the underlying dtype is an NMatrix, this method will return the data type
    # of the NMatrix object.
    #
    # Running through the data to figure out the kind of data is delayed to the
    # last possible moment.
    def type
      return @data.nm_dtype if dtype == :nmatrix

      if @type.nil? || @possibly_changed_type
        @type = :numeric
        each do |e|
          next if e.nil? || e.is_a?(Numeric)
          @type = :object
          break
        end
        @possibly_changed_type = false
      end

      @type
    end

    # Get index of element
    def index_of element
      case dtype
      when :array then @index.key @data.index { |x| x.eql? element }
      else @index.key @data.index(element)
      end
    end

    # Keep only unique elements of the vector alongwith their indexes.
    def uniq
      uniq_vector = @data.uniq
      new_index   = uniq_vector.each_with_object([]) do |element, acc|
        acc << index_of(element)
      end

      Daru::Vector.new uniq_vector, name: @name, metadata: @metadata.dup, index: new_index, dtype: @dtype
    end

    def any? &block
      @data.data.any?(&block)
    end

    def all? &block
      @data.data.all?(&block)
    end

    # Sorts a vector according to its values. If a block is specified, the contents
    # will be evaluated and data will be swapped whenever the block evaluates
    # to *true*. Defaults to ascending order sorting. Any missing values will be
    # put at the end of the vector. Preserves indexing. Default sort algorithm is
    # quick sort.
    #
    # == Options
    #
    # * +:ascending+ - if false, will sort in descending order. Defaults to true.
    #
    # * +:type+ - Specify the sorting algorithm. Only supports quick_sort for now.
    # == Usage
    #
    #   v = Daru::Vector.new ["My first guitar", "jazz", "guitar"]
    #   # Say you want to sort these strings by length.
    #   v.sort(ascending: false) { |a,b| a.length <=> b.length }
    def sort opts={}
      opts = {
        ascending: true
      }.merge(opts)

      vector_index = @data.each_with_index
      vector_index =
        if block_given?
          vector_index.sort { |a,b| yield(a[0], b[0]) }
        else
          vector_index.sort { |(av, ai), (bv, bi)|
            if !av.nil? && !bv.nil?
              av <=> bv
            elsif av.nil? && bv.nil?
              ai <=> bi
            elsif av.nil?
              opts[:ascending] ? -1 : 1
            else
              opts[:ascending] ? 1 : -1
            end
          }
        end
      vector_index.reverse! unless opts[:ascending]
      vector, index = vector_index.transpose
      old_index = @index.to_a
      index = index.map { |i| old_index[i] }

      Daru::Vector.new(vector, index: index, name: @name, metadata: @metadata.dup, dtype: @dtype)
    end

    # Just sort the data and get an Array in return using Enumerable#sort.
    # Non-destructive.
    # :nocov:
    def sorted_data &block
      @data.to_a.sort(&block)
    end
    # :nocov:

    # Returns *true* if the value passed is actually exists or is not marked as
    # a *missing value*.
    def exists? value
      # FIXME: I'm not sure how this method should really work,
      # or whether it is needed at all. - zverok
      idx = index_of(value)
      !!idx && !@missing_values.key?(self[idx])
    end

    # Like map, but returns a Daru::Vector with the returned values.
    def recode dt=nil, &block
      return to_enum(:recode) unless block_given?

      dup.recode! dt, &block
    end

    # Destructive version of recode!
    def recode! dt=nil, &block
      return to_enum(:recode!) unless block_given?

      @data.map!(&block).data
      @data = cast_vector_to(dt || @dtype)
      self
    end

    # Delete an element if block returns true. Destructive.
    def delete_if
      return to_enum(:delete_if) unless block_given?

      keep_e = []
      keep_i = []
      each_with_index do |n, i|
        unless yield(n)
          keep_e << n
          keep_i << i
        end
      end

      @data = cast_vector_to @dtype, keep_e
      @index = Daru::Index.new(keep_i)
      set_missing_positions unless Daru.lazy_update
      set_size

      self
    end

    # Keep an element if block returns true. Destructive.
    def keep_if
      return to_enum(:keep_if) unless block_given?

      keep_e = []
      keep_i = []
      each_with_index do |n, i|
        if yield(n)
          keep_e << n
          keep_i << i
        end
      end

      @data = cast_vector_to @dtype, keep_e
      @index = Daru::Index.new(keep_i)
      set_missing_positions unless Daru.lazy_update
      set_size

      self
    end

    # Reports all values that doesn't comply with a condition.
    # Returns a hash with the index of data and the invalid data.
    def verify
      h = {}
      (0...size).each do |i|
        h[i] = @data[i] unless yield(@data[i])
      end

      h
    end

    # Return an Array with the data splitted by a separator.
    #   a=Daru::Vector.new(["a,b","c,d","a,b","d"])
    #   a.splitted
    #     =>
    #   [["a","b"],["c","d"],["a","b"],["d"]]
    def splitted sep=','
      @data.map do |s|
        if s.nil?
          nil
        elsif s.respond_to? :split
          s.split sep
        else
          [s]
        end
      end
    end

    # Returns a hash of Vectors, defined by the different values
    # defined on the fields
    # Example:
    #
    #  a=Daru::Vector.new(["a,b","c,d","a,b"])
    #  a.split_by_separator
    #  =>  {"a"=>#<Daru::Vector:0x7f2dbcc09d88
    #        @data=[1, 0, 1]>,
    #       "b"=>#<Daru::Vector:0x7f2dbcc09c48
    #        @data=[1, 1, 0]>,
    #      "c"=>#<Daru::Vector:0x7f2dbcc09b08
    #        @data=[0, 1, 1]>}
    #
    def split_by_separator sep=','
      split_data = splitted sep
      factors = split_data.flatten.uniq.compact

      out = factors.map { |x| [x, []] }.to_h

      split_data.each do |r|
        if r.nil?
          factors.each do |f|
            out[f].push(nil)
          end
        else
          factors.each do |f|
            out[f].push(r.include?(f) ? 1 : 0)
          end
        end
      end

      out.map { |k, v| [k, Daru::Vector.new(v)] }.to_h
    end

    def split_by_separator_freq(sep=',')
      split_by_separator(sep).map do |k, v|
        [k, v.inject { |s,x| s+x.to_i }]
      end.to_h
    end

    def reset_index!
      @index = Daru::Index.new(Array.new(size) { |i| i })
      self
    end

    # Returns a vector which has *true* in the position where the element in self
    # is nil, and false otherwise.
    #
    # == Usage
    #
    #   v = Daru::Vector.new([1,2,4,nil])
    #   v.is_nil?
    #   # =>
    #   #<Daru::Vector:89421000 @name = nil @size = 4 >
    #   #      nil
    #   #  0  false
    #   #  1  false
    #   #  2  false
    #   #  3  true
    def is_nil?
      nil_truth_vector = clone_structure
      @index.each do |idx|
        nil_truth_vector[idx] = self[idx].nil? ? true : false
      end

      nil_truth_vector
    end

    # Opposite of #is_nil?
    def not_nil?
      nil_truth_vector = clone_structure
      @index.each do |idx|
        nil_truth_vector[idx] = self[idx].nil? ? false : true
      end

      nil_truth_vector
    end

    # Replace all nils in the vector with the value passed as an argument. Destructive.
    # See #replace_nils for non-destructive version
    #
    # == Arguments
    #
    # * +replacement+ - The value which should replace all nils
    def replace_nils! replacement
      missing_positions.each do |idx|
        self[idx] = replacement
      end

      self
    end

    # Lags the series by k periods.
    #
    # The convention is to set the oldest observations (the first ones
    # in the series) to nil so that the size of the lagged series is the
    # same as the original.
    #
    # Usage:
    #
    #   ts = Daru::Vector.new((1..10).map { rand })
    #           # => [0.69, 0.23, 0.44, 0.71, ...]
    #
    #   ts.lag   # => [nil, 0.69, 0.23, 0.44, ...]
    #   ts.lag(2) # => [nil, nil, 0.69, 0.23, ...]
    def lag k=1
      return dup if k == 0

      dat = @data.to_a.dup
      (dat.size - 1).downto(k) { |i| dat[i] = dat[i - k] }
      (0...k).each { |i| dat[i] = nil }

      Daru::Vector.new(dat, index: @index, name: @name, metadata: @metadata.dup)
    end

    def detach_index
      Daru::DataFrame.new(
        index: @index.to_a,
        values: @data.to_a
      )
    end

    # Non-destructive version of #replace_nils!
    def replace_nils replacement
      dup.replace_nils!(replacement)
    end

    # number of non-missing elements
    def n_valid
      @size - missing_positions.size
    end

    # Returns *true* if an index exists
    def has_index? index
      @index.include? index
    end

    # Convert Vector to a horizontal or vertical Ruby Matrix.
    #
    # == Arguments
    #
    # * +axis+ - Specify whether you want a *:horizontal* or a *:vertical* matrix.
    def to_matrix axis=:horizontal
      if axis == :horizontal
        Matrix[to_a]
      elsif axis == :vertical
        Matrix.columns([to_a])
      else
        raise ArgumentError, "axis should be either :horizontal or :vertical, not #{axis}"
      end
    end

    # If dtype != gsl, will convert data to GSL::Vector with to_a. Otherwise returns
    # the stored GSL::Vector object.
    def to_gsl
      raise NoMethodError, 'Install gsl-nmatrix for access to this functionality.' unless Daru.has_gsl?
      dtype == :gsl ? @data.data : GSL::Vector.alloc(only_valid(:array).to_a)
    end

    # Convert to hash (explicit). Hash keys are indexes and values are the correspoding elements
    def to_h
      @index.map { |index| [index, self[index]] }.to_h
    end

    # Return an array
    def to_a
      @data.to_a
    end

    # Convert the hash from to_h to json
    def to_json(*)
      to_h.to_json
    end

    # Convert to html for iruby
    def to_html threshold=30
      name = @name || 'nil'
      html = '<table>' \
        '<tr>' \
          '<th colspan="2">' \
            "Daru::Vector:#{object_id} " + "size: #{size}" \
          '</th>' \
        '</tr>'
      html += '<tr><th> </th><th>' + name.to_s + '</th></tr>'
      @index.each_with_index do |index, num|
        html += '<tr><td>' + index.to_s + '</td>' + '<td>' + self[index].to_s + '</td></tr>'

        next if num <= threshold - 2
        html += '<tr><td>...</td><td>...</td></tr>'

        last_index = @index.to_a.last
        html += '<tr>' \
                  '<td>' + last_index.to_s       + '</td>' \
                  '<td>' + self[last_index].to_s + '</td>' \
                '</tr>'
        break
      end
      html += '</table>'

      html
    end

    def to_s
      to_html
    end

    # Create a summary of the Vector using Report Builder.
    def summary(method=:to_text)
      ReportBuilder.new(no_title: true).add(self).send(method)
    end

    # :nocov:
    def report_building b
      b.section(name: name) do |s|
        s.text "n :#{size}"
        s.text "n valid:#{n_valid}"
        if @type == :object
          s.text  "factors: #{factors.to_a.join(',')}"
          s.text  "mode: #{mode}"

          s.table(name: 'Distribution') do |t|
            frequencies.sort_by(&:to_s).each do |k,v|
              key = @index.include?(k) ? @index[k] : k
              t.row [key, v, ('%0.2f%%' % (v.quo(n_valid)*100))]
            end
          end
        end

        s.text "median: #{median}" if @type==:numeric || @type==:numeric
        if @type==:numeric
          s.text 'mean: %0.4f' % mean
          if sd
            s.text 'std.dev.: %0.4f' % sd
            s.text 'std.err.: %0.4f' % se
            s.text 'skew: %0.4f' % skew
            s.text 'kurtosis: %0.4f' % kurtosis
          end
        end
      end
    end
    # :nocov:

    # Over rides original inspect for pretty printing in irb
    def inspect spacing=20, threshold=15
      longest =
        [
          @name.to_s.size,
          (@index.to_a.map(&:to_s).map(&:size).max || 0),
          (@data.map(&:to_s).map(&:size).max || 0),
          3 # 'nil'.size
        ].max

      content   = ''
      longest   = spacing if longest > spacing
      name      = @name || 'nil'
      metadata  = @metadata || 'nil'
      formatter = "\n%#{longest}.#{longest}s %#{longest}.#{longest}s"
      # content  += "\n#<#{self.class}:#{object_id} @name = #{name} @metadata = #{metadata} @size = #{size} >"
      content  += "#<#{self.class}:#{object_id} @name = #{name} @metadata = #{metadata} @size = #{size} >"

      content += formatter % ['', name]
      @index.each_with_index do |index, num|
        content += formatter % [index.to_s, (self[*index] || 'nil').to_s]
        if num >= threshold - 1
          content += formatter % ['...', '...']
          break
        end
      end
      # content += "\n" -- FIXME: I'm removing \n before/after because it is unusual for Ruby's inspects. -- zverok, 2016-05-19

      content
    end

    # Create a new vector with a different index, and preserve the indexing of
    # current elements.
    def reindex new_index
      vector = Daru::Vector.new([], index: new_index, name: @name, metadata: @metadata.dup)

      new_index.each do |idx|
        vector[idx] = @index.include?(idx) ? self[idx] : nil
      end

      vector
    end

    def index= idx
      raise ArgumentError,
        "Size of supplied index #{index.size} does not match size of DataFrame" if
        idx.size != size
      raise ArgumentError, 'Can only assign type Index and its subclasses.' unless
        idx.is_a?(Daru::Index)

      @index = idx
      self
    end

    # Give the vector a new name
    #
    # @param new_name [Symbol] The new name.
    def rename new_name
      @name = new_name
    end

    # Duplicate elements and indexes
    def dup
      Daru::Vector.new @data.dup, name: @name, metadata: @metadata.dup, index: @index.dup
    end

    # == Bootstrap
    # Generate +nr+ resamples (with replacement) of size  +s+
    # from vector, computing each estimate from +estimators+
    # over each resample.
    # +estimators+ could be
    # a) Hash with variable names as keys and lambdas as  values
    #   a.bootstrap(:log_s2=>lambda {|v| Math.log(v.variance)},1000)
    # b) Array with names of method to bootstrap
    #   a.bootstrap([:mean, :sd],1000)
    # c) A single method to bootstrap
    #   a.jacknife(:mean, 1000)
    # If s is nil, is set to vector size by default.
    #
    # Returns a DataFrame where each vector is a vector
    # of length +nr+ containing the computed resample estimates.
    def bootstrap(estimators, nr, s=nil)
      s ||= size
      h_est, es, bss = prepare_bootstrap(estimators)

      nr.times do
        bs = sample_with_replacement(s)
        es.each do |estimator|
          bss[estimator].push(h_est[estimator].call(bs))
        end
      end

      es.each do |est|
        bss[est] = Daru::Vector.new bss[est]
      end

      Daru::DataFrame.new bss
    end

    # == Jacknife
    # Returns a dataset with jacknife delete-+k+ +estimators+
    # +estimators+ could be:
    # a) Hash with variable names as keys and lambdas as values
    #   a.jacknife(:log_s2=>lambda {|v| Math.log(v.variance)})
    # b) Array with method names to jacknife
    #   a.jacknife([:mean, :sd])
    # c) A single method to jacknife
    #   a.jacknife(:mean)
    # +k+ represent the block size for block jacknife. By default
    # is set to 1, for classic delete-one jacknife.
    #
    # Returns a dataset where each vector is an vector
    # of length +cases+/+k+ containing the computed jacknife estimates.
    #
    # == Reference:
    # * Sawyer, S. (2005). Resampling Data: Using a Statistical Jacknife.
    def jackknife(estimators, k=1)
      raise "n should be divisible by k:#{k}" unless size % k==0

      nb = (size / k).to_i
      h_est, es, ps = prepare_bootstrap(estimators)

      est_n = es.map { |v| [v, h_est[v].call(self)] }.to_h

      nb.times do |i|
        other = @data.dup
        other.slice!(i*k, k)
        other = Daru::Vector.new other

        es.each do |estimator|
          # Add pseudovalue
          ps[estimator].push(
            nb * est_n[estimator] - (nb-1) * h_est[estimator].call(other)
          )
        end
      end

      es.each do |est|
        ps[est] = Daru::Vector.new ps[est]
      end
      Daru::DataFrame.new ps
    end

    # Creates a new vector consisting only of non-nil data
    #
    # == Arguments
    #
    # @as_a [Symbol] Passing :array will return only the elements
    # as an Array. Otherwise will return a Daru::Vector.
    #
    # @duplicate [Symbol] In case no missing data is found in the
    # vector, setting this to false will return the same vector.
    # Otherwise, a duplicate will be returned irrespective of
    # presence of missing data.
    def only_valid as_a=:vector, duplicate=true
      return dup if !has_missing_data? && as_a == :vector && duplicate
      return self if !has_missing_data? && as_a == :vector && !duplicate
      return to_a if !has_missing_data? && as_a != :vector

      new_index = @index.to_a - missing_positions
      new_vector = new_index.map do |idx|
        self[idx]
      end

      return new_vector if as_a != :vector

      Daru::Vector.new new_vector, index: new_index, name: @name, metadata: @metadata.dup, dtype: dtype
    end

    # Returns a Vector containing only missing data (preserves indexes).
    def only_missing as_a=:vector
      if as_a == :vector
        self[*missing_positions]
      elsif as_a == :array
        self[*missing_positions].to_a
      end
    end

    # Returns a Vector with only numerical data. Missing data is included
    # but non-Numeric objects are excluded. Preserves index.
    def only_numerics
      numeric_indexes = []

      each_with_index do |v, i|
        numeric_indexes << i if v.is_a?(Numeric) || @missing_values.key?(v)
      end

      self[*numeric_indexes]
    end

    # Returns the database type for the vector, according to its content
    def db_type
      # first, detect any character not number
      if @data.find { |v| v.to_s=~/\d{2,2}-\d{2,2}-\d{4,4}/ } ||
         @data.find { |v| v.to_s=~/\d{4,4}-\d{2,2}-\d{2,2}/ }

        return 'DATE'
      elsif @data.find { |v| v.to_s=~/[^0-9e.-]/ }
        return 'VARCHAR (255)'
      elsif @data.find { |v| v.to_s=~/\./ }
        return 'DOUBLE'
      else
        return 'INTEGER'
      end
    end

    # Copies the structure of the vector (i.e the index, size, etc.) and fills all
    # all values with nils.
    def clone_structure
      Daru::Vector.new(([nil]*@size), name: @name, metadata: @metadata.dup, index: @index.dup)
    end

    # Save the vector to a file
    #
    # == Arguments
    #
    # * filename - Path of file where the vector is to be saved
    def save filename
      Daru::IO.save self, filename
    end

    def _dump(*) # :nodoc:
      Marshal.dump(
        data:           @data.to_a,
        dtype:          @dtype,
        name:           @name,
        metadata:       @metadata,
        index:          @index,
        missing_values: @missing_values
      )
    end

    def self._load(data) # :nodoc:
      h = Marshal.load(data)
      Daru::Vector.new(h[:data],
        index: h[:index],
        name: h[:name], metadata: h[:metadata],
        dtype: h[:dtype], missing_values: h[:missing_values])
    end

    # :nocov:
    def daru_vector(*)
      self
    end
    # :nocov:

    alias :dv :daru_vector

    def method_missing(name, *args, &block)
      # FIXME: it is shamefully fragile. Should be either made stronger
      # (string/symbol dychotomy, informative errors) or removed totally. - zverok
      if name =~ /(.+)\=/
        self[$1.to_sym] = args[0]
      elsif has_index?(name)
        self[name]
      else
        super(name, *args, &block)
      end
    end

    private

    # For an array or hash of estimators methods, returns
    # an array with three elements
    # 1.- A hash with estimators names as keys and lambdas as values
    # 2.- An array with estimators names
    # 3.- A Hash with estimators names as keys and empty arrays as values
    def prepare_bootstrap(estimators)
      h_est = estimators
      h_est = [h_est] unless h_est.is_a?(Array) || h_est.is_a?(Hash)

      if h_est.is_a? Array
        h_est = h_est.map do |est|
          [est, ->(v) { Daru::Vector.new(v).send(est) }]
        end.to_h
      end
      bss = h_est.keys.map { |v| [v, []] }.to_h

      [h_est, h_est.keys, bss]
    end

    # Note: To maintain sanity, this _MUST_ be the _ONLY_ place in daru where the
    # @dtype variable is set and the underlying data type of vector changed.
    def cast_vector_to dtype, source=nil, nm_dtype=nil
      source = @data.to_a if source.nil?

      new_vector =
        case dtype
        when :array   then Daru::Accessors::ArrayWrapper.new(source, self)
        when :nmatrix then Daru::Accessors::NMatrixWrapper.new(source, self, nm_dtype)
        when :gsl then Daru::Accessors::GSLWrapper.new(source, self)
        when :mdarray then raise NotImplementedError, 'MDArray not yet supported.'
        else raise ArgumentError, "Unknown dtype #{dtype}"
        end

      @dtype = dtype || :array
      new_vector
    end

    def set_size
      @size = @data.size
    end

    def set_name name # rubocop:disable Style/AccessorMethodName
      @name =
        if name.is_a?(Numeric)  then name
        elsif name.is_a?(Array) then name.join # in case of MultiIndex tuple
        elsif name              then name # anything but Numeric or nil
        else
          nil
        end
    end

    def set_missing_positions
      @missing_positions = []
      @index.each do |e|
        @missing_positions << e if @missing_values.key?(self[e])
      end
    end

    def try_create_index potential_index
      if potential_index.is_a?(Daru::MultiIndex) || potential_index.is_a?(Daru::Index)
        potential_index
      else
        Daru::Index.new(potential_index)
      end
    end

    # Setup missing_values. The missing_values instance variable is set
    # as a Hash for faster lookup times.
    def set_missing_values values_arry # rubocop:disable Style/AccessorMethodName
      @missing_values = {}
      @missing_values[nil] = 0
      if values_arry
        values_arry.each do |e|
          # If dtype is :gsl then missing values have to be converted to float
          e = e.to_f if dtype == :gsl && e.is_a?(Numeric)
          @missing_values[e] = 0
        end
      end
    end
  end
end
