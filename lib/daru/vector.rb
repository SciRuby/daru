require 'daru/maths/arithmetic/vector.rb'
require 'daru/maths/statistics/vector.rb'
require 'daru/plotting/gruff.rb'
require 'daru/plotting/nyaplot.rb'
require 'daru/accessors/array_wrapper.rb'
require 'daru/accessors/nmatrix_wrapper.rb'
require 'daru/accessors/gsl_wrapper.rb'
require 'daru/category.rb'

module Daru
  class Vector # rubocop:disable Metrics/ClassLength
    include Enumerable
    include Daru::Maths::Arithmetic::Vector
    include Daru::Maths::Statistics::Vector
    extend Gem::Deprecate

    class << self
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
      def new_with_size n, opts={}, &block
        value = opts.delete :value
        block ||= ->(_) { value }
        Daru::Vector.new Array.new(n, &block), opts
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
      def [](*indexes)
        values = indexes.map do |a|
          a.respond_to?(:to_a) ? a.to_a : a
        end.flatten
        Daru::Vector.new(values)
      end

      def _load(data) # :nodoc:
        h = Marshal.load(data)
        Daru::Vector.new(h[:data],
          index: h[:index],
          name: h[:name],
          dtype: h[:dtype], missing_values: h[:missing_values])
      end

      def coerce(data, options={})
        case data
        when Daru::Vector
          data
        when Array, Hash
          new(data, options)
        else
          raise ArgumentError, "Can't coerce #{data.class} to #{self}"
        end
      end
    end

    def size
      @data.size
    end

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

    def each_with_index &block
      return to_enum(:each_with_index) unless block_given?

      @data.to_a.zip(@index.to_a).each(&block)

      self
    end

    def map!(&block)
      return to_enum(:map!) unless block_given?
      @data.map!(&block)
      self
    end

    # The name of the Daru::Vector. String.
    attr_reader :name
    # The row index. Can be either Daru::Index or Daru::MultiIndex.
    attr_reader :index
    # The underlying dtype of the Vector. Can be either :array, :nmatrix or :gsl.
    attr_reader :dtype
    # If the dtype is :nmatrix, this attribute represents the data type of the
    # underlying NMatrix object. See NMatrix docs for more details on NMatrix
    # data types.
    attr_reader :nm_dtype
    # An Array or the positions in the vector that are being treated as 'missing'.
    attr_reader :missing_positions
    deprecate :missing_positions, :indexes, 2016, 10
    # Store a hash of labels for values. Supplementary only. Recommend using index
    # for proper usage.
    attr_accessor :labels
    # Store vector data in an array
    attr_reader :data
    # Ploting library being used for this vector
    attr_reader :plotting_library
    # TODO: Make private.
    attr_reader :nil_positions, :nan_positions

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
      if opts[:type] == :category
        # Initialize category type vector
        extend Daru::Category
        initialize_category source, opts
      else
        # Initialize non-category type vector
        initialize_vector source, opts
      end
    end

    def plotting_library= lib
      case lib
      when :gruff, :nyaplot
        @plotting_library = lib
        if Daru.send("has_#{lib}?".to_sym)
          extend Module.const_get(
            "Daru::Plotting::Vector::#{lib.to_s.capitalize}Library"
          )
        end
      else
        raise ArguementError, "Plotting library #{lib} not supported. "\
          'Supported libraries are :nyaplot and :gruff'
      end
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
      # Get array of positions indexes
      positions = @index.pos(*input_indexes)

      # If one object is asked return it
      return @data[positions] if positions.is_a? Numeric

      # Form a new Vector using positional indexes
      Daru::Vector.new(
        positions.map { |loc| @data[loc] },
        name: @name,
        index: @index.subset(*input_indexes), dtype: @dtype
      )
    end

    # Returns vector of values given positional values
    # @param positions [Array<object>] positional values
    # @return [object] vector
    # @example
    #   dv = Daru::Vector.new 'a'..'e'
    #   dv.at 0, 1, 2
    #   # => #<Daru::Vector(3)>
    #   #   0   a
    #   #   1   b
    #   #   2   c
    def at *positions
      # to be used to form index
      original_positions = positions
      positions = coerce_positions(*positions)
      validate_positions(*positions)

      if positions.is_a? Integer
        @data[positions]
      else
        values = positions.map { |pos| @data[pos] }
        Daru::Vector.new values, index: @index.at(*original_positions), dtype: dtype
      end
    end

    # Change value at given positions
    # @param positions [Array<object>] positional values
    # @param [object] val value to assign
    # @example
    #   dv = Daru::Vector.new 'a'..'e'
    #   dv.set_at [0, 1], 'x'
    #   dv
    #   # => #<Daru::Vector(5)>
    #   #   0   x
    #   #   1   x
    #   #   2   c
    #   #   3   d
    #   #   4   e
    def set_at positions, val
      validate_positions(*positions)
      positions.map { |pos| @data[pos] = val }
      update_position_cache
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
    def []=(*indexes, val)
      cast(dtype: :array) if val.nil? && dtype != :array

      guard_type_check(val)

      modify_vector(indexes, val)

      update_position_cache
    end

    # Two vectors are equal if they have the exact same index values corresponding
    # with the exact same elements. Name is ignored.
    def == other
      case other
      when Daru::Vector
        @index == other.index && size == other.size &&
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
          mod.apply_scalar_operator operator, @data, other
        end
      end
      alias_method operator, method if operator != :== && operator != :!=
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
    # @param bool_array [Daru::Core::Query::BoolArray, Array<TrueClass, FalseClass>] The
    #   collection containing the true of false values. Each element in the Vector
    #   corresponding to a `true` in the bool_arry will be returned alongwith it's
    #   index.
    # @example Usage of #where.
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
    def where bool_array
      Daru::Core::Query.vector_where self, bool_array
    end

    def head q=10
      self[0..(q-1)]
    end

    def tail q=10
      start = [size - q, 0].max
      self[start..(size-1)]
    end

    def empty?
      @index.empty?
    end

    def numeric?
      type == :numeric
    end

    def object?
      type == :object
    end

    # Reports whether missing data is present in the Vector.
    def has_missing_data?
      !indexes(*Daru::MISSING_VALUES).empty?
    end
    alias :flawed? :has_missing_data?
    deprecate :has_missing_data?, :include_values?, 2016, 10
    deprecate :flawed?, :include_values?, 2016, 10

    # Check if any one of mentioned values occur in the vector
    # @param values  [Array] values to check for
    # @return [true, false] returns true if any one of specified values
    #   occur in the vector
    # @example
    #   dv = Daru::Vector.new [1, 2, 3, 4, nil]
    #   dv.include_values? nil, Float::NAN
    #   # => true
    def include_values?(*values)
      values.any? { |v| include_with_nan? @data, v }
    end

    # @note Do not use it to check for Float::NAN as
    #   Float::NAN == Float::NAN is false
    # Return vector of booleans with value at ith position is either
    # true or false depending upon whether value at position i is equal to
    # any of the values passed in the argument or not
    # @param values [Array] values to equate with
    # @return [Daru::Vector] vector of boolean values
    # @example
    #   dv = Daru::Vector.new [1, 2, 3, 2, 1]
    #   dv.is_values 1, 2
    #   # => #<Daru::Vector(5)>
    #   #     0  true
    #   #     1  true
    #   #     2 false
    #   #     3  true
    #   #     4  true
    def is_values(*values)
      Daru::Vector.new values.map { |v| eq(v) }.inject(:|)
    end

    # Append an element to the vector by specifying the element and index
    def concat element, index
      raise IndexError, 'Expected new unique index' if @index.include? index

      @index |= [index]
      @data[@index[index]] = element

      update_position_cache
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
      raise ArgumentError, "Unsupported dtype #{opts[:dtype]}" unless %i[array nmatrix gsl].include?(dt)

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

      update_position_cache
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

    # Tells if vector is categorical or not.
    # @return [true, false] true if vector is of type category, false otherwise
    # @example
    #   dv = Daru::Vector.new [1, 2, 3], type: :category
    #   dv.category?
    #   # => true
    def category?
      type == :category
    end

    # Get index of element
    def index_of element
      case dtype
      when :array then @index.key(@data.index { |x| x.eql? element })
      else @index.key @data.index(element)
      end
    end

    # Keep only unique elements of the vector alongwith their indexes.
    def uniq
      uniq_vector = @data.uniq
      new_index   = uniq_vector.map { |element| index_of(element) }

      Daru::Vector.new uniq_vector, name: @name, index: new_index, dtype: @dtype
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
    def sort opts={}, &block
      opts = {ascending: true}.merge(opts)

      vector_index = resort_index(@data.each_with_index, opts, &block)
      vector, index = vector_index.transpose

      index = @index.reorder index

      Daru::Vector.new(vector, index: index, name: @name, dtype: @dtype)
    end

    # Sorts the vector according to it's`Index` values. Defaults to ascending
    # order sorting.
    #
    # @param [Hash] opts the options for sort_by_index method.
    # @option opts [Boolean] :ascending false, will sort `index` in
    #  descending order.
    #
    # @return [Vector] new sorted `Vector` according to the index values.
    #
    # @example
    #
    #   dv = Daru::Vector.new [11, 13, 12], index: [23, 21, 22]
    #   # Say you want to sort index in ascending order
    #   dv.sort_by_index(ascending: true)
    #   #=> Daru::Vector.new [13, 12, 11], index: [21, 22, 23]
    #   # Say you want to sort index in descending order
    #   dv.sort_by_index(ascending: false)
    #   #=> Daru::Vector.new [11, 12, 13], index: [23, 22, 21]
    def sort_by_index opts={}
      opts = {ascending: true}.merge(opts)
      _, new_order = resort_index(@index.each_with_index, opts).transpose

      reorder new_order
    end

    DEFAULT_SORTER = lambda { |(lv, li), (rv, ri)|
      case
      when lv.nil? && rv.nil?
        li <=> ri
      when lv.nil?
        -1
      when rv.nil?
        1
      else
        lv <=> rv
      end
    }

    # Just sort the data and get an Array in return using Enumerable#sort.
    # Non-destructive.
    # :nocov:
    def sorted_data &block
      @data.to_a.sort(&block)
    end
    # :nocov:

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

      keep_e, keep_i = each_with_index.reject { |n, _i| yield(n) }.transpose

      @data = cast_vector_to @dtype, keep_e
      @index = Daru::Index.new(keep_i)

      update_position_cache

      self
    end

    # Keep an element if block returns true. Destructive.
    def keep_if
      return to_enum(:keep_if) unless block_given?

      delete_if { |val| !yield(val) }
    end

    # Reports all values that doesn't comply with a condition.
    # Returns a hash with the index of data and the invalid data.
    def verify
      (0...size)
        .map { |i| [i, @data[i]] }
        .reject { |_i, val| yield(val) }
        .to_h
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
      split_data
        .flatten.uniq.compact.map do |key|
        [
          key,
          Daru::Vector.new(split_data.map { |v| split_value(key, v) })
        ]
      end.to_h
    end

    def split_by_separator_freq(sep=',')
      split_by_separator(sep).map { |k, v|
        [k, v.map(&:to_i).inject(:+)]
      }.to_h
    end

    def reset_index!
      @index = Daru::Index.new(Array.new(size) { |i| i })
      self
    end

    # Replace all nils in the vector with the value passed as an argument. Destructive.
    # See #replace_nils for non-destructive version
    #
    # == Arguments
    #
    # * +replacement+ - The value which should replace all nils
    def replace_nils! replacement
      indexes(*Daru::MISSING_VALUES).each do |idx|
        self[idx] = replacement
      end

      self
    end

    # Rolling fillna
    # replace all Float::NAN and NIL values with the preceeding or following value
    #
    # @param direction [Symbol] (:forward, :backward) whether replacement value is preceeding or following
    #
    # @example
    #  dv = Daru::Vector.new([1, 2, 1, 4, nil, Float::NAN, 3, nil, Float::NAN])
    #
    #   2.3.3 :068 > dv.rolling_fillna(:forward)
    #   => #<Daru::Vector(9)>
    #   0   1
    #   1   2
    #   2   1
    #   3   4
    #   4   4
    #   5   4
    #   6   3
    #   7   3
    #   8   3
    #
    def rolling_fillna!(direction=:forward)
      enum = direction == :forward ? index : index.reverse_each
      last_valid_value = 0
      enum.each do |idx|
        if valid_value?(self[idx])
          last_valid_value = self[idx]
        else
          self[idx] = last_valid_value
        end
      end
      self
    end

    # Non-destructive version of rolling_fillna!
    def rolling_fillna(direction=:forward)
      dup.rolling_fillna!(direction)
    end

    # Lags the series by `k` periods.
    #
    # Lags the series by `k` periods, "shifting" data and inserting `nil`s
    # from beginning or end of a vector, while preserving original vector's
    # size.
    #
    # `k` can be positive or negative integer. If `k` is positive, `nil`s
    # are inserted at the beginning of the vector, otherwise they are
    # inserted at the end.
    #
    # @param [Integer] k "shift" the series by `k` periods. `k` can be
    #   positive or negative. (default = 1)
    #
    # @return [Daru::Vector] a new vector with "shifted" inital values
    #   and `nil` values inserted. The return vector is the same length
    #   as the orignal vector.
    #
    # @example Lag a vector with different periods `k`
    #
    #   ts = Daru::Vector.new(1..5)
    #               # => [1, 2, 3, 4, 5]
    #
    #   ts.lag      # => [nil, 1, 2, 3, 4]
    #   ts.lag(1)   # => [nil, 1, 2, 3, 4]
    #   ts.lag(2)   # => [nil, nil, 1, 2, 3]
    #   ts.lag(-1)  # => [2, 3, 4, 5, nil]
    #
    def lag k=1
      case k
      when 0 then dup
      when 1...size
        copy([nil] * k + data.to_a)
      when -size..-1
        copy(data.to_a[k.abs...size])
      else
        copy([])
      end
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
      size - indexes(*Daru::MISSING_VALUES).size
    end
    deprecate :n_valid, :count_values, 2016, 10

    # Count the number of values specified
    # @param values [Array] values to count for
    # @return [Integer] the number of times the values mentioned occurs
    # @example
    #   dv = Daru::Vector.new [1, 2, 1, 2, 3, 4, nil, nil]
    #   dv.count_values nil
    #   # => 2
    def count_values(*values)
      positions(*values).size
    end

    # Returns *true* if an index exists
    def has_index? index
      @index.include? index
    end

    # @return [Daru::DataFrame] the vector as a single-vector dataframe
    def to_df
      Daru::DataFrame.new({@name => @data}, name: @name, index: @index)
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

    # Convert vector to nmatrix object
    # @param [Symbol] axis :horizontal or :vertical
    # @return [NMatrix] NMatrix object containing all values of the vector
    # @example
    #   dv = Daru::Vector.new [1, 2, 3]
    #   dv.to_nmatrix
    #   # =>
    #   # [
    #   #   [1, 2, 3] ]
    def to_nmatrix axis=:horizontal
      unless numeric? && !include?(nil)
        raise ArgumentError, 'Can not convert to nmatrix'\
          'because the vector is numeric'
      end

      case axis
      when :horizontal
        NMatrix.new [1, size], to_a
      when :vertical
        NMatrix.new [size, 1], to_a
      else
        raise ArgumentError, 'Invalid axis specified. '\
          'Valid axis are :horizontal and :vertical'
      end
    end

    # If dtype != gsl, will convert data to GSL::Vector with to_a. Otherwise returns
    # the stored GSL::Vector object.
    def to_gsl
      raise NoMethodError, 'Install gsl-nmatrix for access to this functionality.' unless Daru.has_gsl?
      if dtype == :gsl
        @data.data
      else
        GSL::Vector.alloc(reject_values(*Daru::MISSING_VALUES).to_a)
      end
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
    def to_html(threshold=30)
      table_thead = to_html_thead
      table_tbody = to_html_tbody(threshold)
      path = if index.is_a?(MultiIndex)
               File.expand_path('../iruby/templates/vector_mi.html.erb', __FILE__)
             else
               File.expand_path('../iruby/templates/vector.html.erb', __FILE__)
             end
      ERB.new(File.read(path).strip).result(binding)
    end

    def to_html_thead
      table_thead_path =
        if index.is_a?(MultiIndex)
          File.expand_path('../iruby/templates/vector_mi_thead.html.erb', __FILE__)
        else
          File.expand_path('../iruby/templates/vector_thead.html.erb', __FILE__)
        end
      ERB.new(File.read(table_thead_path).strip).result(binding)
    end

    def to_html_tbody(threshold=30)
      table_tbody_path =
        if index.is_a?(MultiIndex)
          File.expand_path('../iruby/templates/vector_mi_tbody.html.erb', __FILE__)
        else
          File.expand_path('../iruby/templates/vector_tbody.html.erb', __FILE__)
        end
      ERB.new(File.read(table_tbody_path).strip).result(binding)
    end

    def to_s
      "#<#{self.class}#{': ' + @name.to_s if @name}(#{size})#{':category' if category?}>"
    end

    # Create a summary of the Vector
    # @param indent_level [Fixnum] indent level
    # @return [String] String containing the summary of the Vector
    # @example
    #   dv = Daru::Vector.new [1, 2, 3]
    #   puts dv.summary
    #
    #   # =
    #   #   n :3
    #   #   non-missing:3
    #   #   median: 2
    #   #   mean: 2.0000
    #   #   std.dev.: 1.0000
    #   #   std.err.: 0.5774
    #   #   skew: 0.0000
    #   #   kurtosis: -2.3333
    def summary(indent_level=0)
      non_missing = size - count_values(*Daru::MISSING_VALUES)
      summary = '  =' * indent_level + "= #{name}" \
                "\n  n :#{size}" \
                "\n  non-missing:#{non_missing}"
      case type
      when :object
        summary << object_summary
      when :numeric
        summary << numeric_summary
      end
      summary.split("\n").join("\n" + '  ' * indent_level)
    end

    # Displays summary for an object type Vector
    # @return [String] String containing object vector summary
    def object_summary
      nval = count_values(*Daru::MISSING_VALUES)
      summary = "\n  factors: #{factors.to_a.join(',')}" \
                "\n  mode: #{mode.to_a.join(',')}" \
                "\n  Distribution\n"

      data = frequencies.sort.each_with_index.map do |v, k|
        [k, v, '%0.2f%%' % ((nval.zero? ? 1 : v.quo(nval))*100)]
      end

      summary + Formatters::Table.format(data)
    end

    # Displays summary for an numeric type Vector
    # @return [String] String containing numeric vector summary
    def numeric_summary
      summary = "\n  median: #{median}" +
                "\n  mean: %0.4f" % mean
      if sd
        summary << "\n  std.dev.: %0.4f" % sd +
                   "\n  std.err.: %0.4f" % se
      end

      if count_values(*Daru::MISSING_VALUES).zero?
        summary << "\n  skew: %0.4f" % skew +
                   "\n  kurtosis: %0.4f" % kurtosis
      end
      summary
    end

    # Over rides original inspect for pretty printing in irb
    def inspect spacing=20, threshold=15
      row_headers = index.is_a?(MultiIndex) ? index.sparse_tuples : index.to_a

      "#<#{self.class}(#{size})#{':category' if category?}>\n" +
        Formatters::Table.format(
          to_a.lazy.map { |v| [v] },
          headers: @name && [@name],
          row_headers: row_headers,
          threshold: threshold,
          spacing: spacing
        )
    end

    # Sets new index for vector. Preserves index->value correspondence.
    # Sets nil for new index keys absent from original index.
    # @note Unlike #reorder! which takes positions as input it takes
    #   index as an input to reorder the vector
    # @param [Daru::Index, Daru::MultiIndex] new_index new index to order with
    # @return [Daru::Vector] vector reindexed with new index
    def reindex! new_index
      values = []
      each_with_index do |val, i|
        values[new_index[i]] = val if new_index.include?(i)
      end
      values.fill(nil, values.size, new_index.size - values.size)

      @data = cast_vector_to @dtype, values
      @index = new_index

      update_position_cache

      self
    end

    # Reorder the vector with given positions
    # @note Unlike #reindex! which takes index as input, it takes
    #   positions as an input to reorder the vector
    # @param [Array] order the order to reorder the vector with
    # @return reordered vector
    # @example
    #   dv = Daru::Vector.new [3, 2, 1], index: ['c', 'b', 'a']
    #   dv.reorder! [2, 1, 0]
    #   # => #<Daru::Vector(3)>
    #   #   a   1
    #   #   b   2
    #   #   c   3
    def reorder! order
      @index = @index.reorder order
      data_array = order.map { |i| @data[i] }
      @data = cast_vector_to @dtype, data_array, @nm_dtype
      update_position_cache
      self
    end

    # Non-destructive version of #reorder!
    def reorder order
      dup.reorder! order
    end

    # Create a new vector with a different index, and preserve the indexing of
    # current elements.
    def reindex new_index
      dup.reindex!(new_index)
    end

    def index= idx
      idx = Index.coerce idx

      if idx.size != size
        raise ArgumentError,
          "Size of supplied index #{idx.size} does not match size of Vector"
      end

      unless idx.is_a?(Daru::Index)
        raise ArgumentError, 'Can only assign type Index and its subclasses.'
      end

      @index = idx
      self
    end

    # Give the vector a new name
    #
    # @param new_name [Symbol] The new name.
    def rename new_name
      @name = new_name
      self
    end

    alias_method :name=, :rename

    # Duplicated a vector
    # @return [Daru::Vector] duplicated vector
    def dup
      Daru::Vector.new @data.dup, name: @name, index: @index.dup
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
    def jackknife(estimators, k=1) # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
      raise "n should be divisible by k:#{k}" unless (size % k).zero?

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
    # @param as_a [Symbol] Passing :array will return only the elements
    # as an Array. Otherwise will return a Daru::Vector.
    #
    # @param _duplicate [Symbol] In case no missing data is found in the
    # vector, setting this to false will return the same vector.
    # Otherwise, a duplicate will be returned irrespective of
    # presence of missing data.

    def only_valid as_a=:vector, _duplicate=true
      # FIXME: Now duplicate is just ignored.
      #   There are no spec that fail on this case, so I'll leave it
      #   this way for now - zverok, 2016-05-07

      new_index = @index.to_a - indexes(*Daru::MISSING_VALUES)
      new_vector = new_index.map { |idx| self[idx] }

      if as_a == :vector
        Daru::Vector.new new_vector, index: new_index, name: @name, dtype: dtype
      else
        new_vector
      end
    end
    deprecate :only_valid, :reject_values, 2016, 10

    # Return a vector with specified values removed
    # @param values [Array] values to reject from resultant vector
    # @return [Daru::Vector] vector with specified values removed
    # @example
    #   dv = Daru::Vector.new [1, 2, nil, Float::NAN]
    #   dv.reject_values nil, Float::NAN
    #   # => #<Daru::Vector(2)>
    #   #   0   1
    #   #   1   2
    def reject_values(*values)
      resultant_pos = size.times.to_a - positions(*values)
      dv = at(*resultant_pos)
      # Handle the case when number of positions is 1
      # and hence #at doesn't return a vector
      if dv.is_a?(Daru::Vector)
        dv
      else
        pos = resultant_pos.first
        at(pos..pos)
      end
    end

    # Return indexes of values specified
    # @param values [Array] values to find indexes for
    # @return [Array] array of indexes of values specified
    # @example
    #   dv = Daru::Vector.new [1, 2, nil, Float::NAN], index: 11..14
    #   dv.indexes nil, Float::NAN
    #   # => [13, 14]
    def indexes(*values)
      index.to_a.values_at(*positions(*values))
    end

    # Replaces specified values with a new value
    # @param [Array] old_values array of values to replace
    # @param [object] new_value new value to replace with
    # @note It performs the replace in place.
    # @return [Daru::Vector] Same vector itself with values
    #   replaced with new value
    # @example
    #   dv = Daru::Vector.new [1, 2, :a, :b]
    #   dv.replace_values [:a, :b], nil
    #   dv
    #   # =>
    #   # #<Daru::Vector:19903200 @name = nil @metadata = {} @size = 4 >
    #   #     nil
    #   #   0   1
    #   #   1   2
    #   #   2 nil
    #   #   3 nil
    def replace_values(old_values, new_value)
      old_values = [old_values] unless old_values.is_a? Array
      size.times do |pos|
        set_at([pos], new_value) if include_with_nan? old_values, at(pos)
      end
      self
    end

    # Returns a Vector containing only missing data (preserves indexes).
    def only_missing as_a=:vector
      if as_a == :vector
        self[*indexes(*Daru::MISSING_VALUES)]
      elsif as_a == :array
        self[*indexes(*Daru::MISSING_VALUES)].to_a
      end
    end
    deprecate :only_missing, nil, 2016, 10

    # Returns a Vector with only numerical data. Missing data is included
    # but non-Numeric objects are excluded. Preserves index.
    def only_numerics
      numeric_indexes =
        each_with_index
        .select { |v, _i| v.is_a?(Numeric) || v.nil? }
        .map(&:last)

      self[*numeric_indexes]
    end

    DATE_REGEXP = /^(\d{2}-\d{2}-\d{4}|\d{4}-\d{2}-\d{2})$/

    # Returns the database type for the vector, according to its content
    def db_type
      # first, detect any character not number
      case
      when @data.any? { |v| v.to_s =~ DATE_REGEXP }
        'DATE'
      when @data.any? { |v| v.to_s =~ /[^0-9e.-]/ }
        'VARCHAR (255)'
      when @data.any? { |v| v.to_s =~ /\./ }
        'DOUBLE'
      else
        'INTEGER'
      end
    end

    # Copies the structure of the vector (i.e the index, size, etc.) and fills all
    # all values with nils.
    def clone_structure
      Daru::Vector.new(([nil]*size), name: @name, index: @index.dup)
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
        index:          @index
      )
    end

    # :nocov:
    def daru_vector(*)
      self
    end
    # :nocov:

    alias :dv :daru_vector

    # Converts a non category type vector to category type vector.
    # @param [Hash] opts options to convert to category
    # @option opts [true, false] :ordered Specify if vector is ordered or not.
    #   If it is ordered, it can be sorted and min, max like functions would work
    # @option opts [Array] :categories set categories in the specified order
    # @return [Daru::Vector] vector with type category
    def to_category opts={}
      dv = Daru::Vector.new to_a, type: :category, name: @name, index: @index
      dv.ordered = opts[:ordered] || false
      dv.categories = opts[:categories] if opts[:categories]
      dv
    end

    def method_missing(name, *args, &block)
      # FIXME: it is shamefully fragile. Should be either made stronger
      # (string/symbol dychotomy, informative errors) or removed totally. - zverok
      if name =~ /(.+)\=/
        self[$1.to_sym] = args[0]
      elsif has_index?(name)
        self[name]
      else
        super
      end
    end

    def respond_to_missing?(name, include_private=false)
      name.to_s.end_with?('=') || has_index?(name) || super
    end

    # Partition a numeric variable into categories.
    # @param [Array<Numeric>] partitions an array whose consecutive elements
    #   provide intervals for categories
    # @param [Hash] opts options to cut the partition
    # @option opts [:left, :right] :close_at specifies whether the interval closes at
    #   the right side of left side
    # @option opts [Array] :labels names of the categories
    # @return [Daru::Vector] numeric variable converted to categorical variable
    # @example
    #   heights = Daru::Vector.new [30, 35, 32, 50, 42, 51]
    #   height_cat = heights.cut [30, 40, 50, 60], labels=['low', 'medium', 'high']
    #   # => #<Daru::Vector(6)>
    #   #       0    low
    #   #       1    low
    #   #       2    low
    #   #       3   high
    #   #       4 medium
    #   #       5   high
    def cut partitions, opts={}
      close_at, labels = opts[:close_at] || :right, opts[:labels]
      partitions = partitions.to_a
      values = to_a.map { |val| cut_find_category partitions, val, close_at }
      cats = cut_categories(partitions, close_at)

      dv = Daru::Vector.new values,
        index: @index,
        type: :category,
        categories: cats

      # Rename categories if new labels provided
      if labels
        dv.rename_categories Hash[cats.zip(labels)]
      else
        dv
      end
    end

    def positions(*values)
      case values
      when [nil]
        nil_positions
      when [Float::NAN]
        nan_positions
      when [nil, Float::NAN], [Float::NAN, nil]
        nil_positions + nan_positions
      else
        size.times.select { |i| include_with_nan? values, @data[i] }
      end
    end

    def group_by(*args)
      to_df.group_by(*args)
    end

    private

    def copy(values)
      # Make sure values is right-justified to the size of the vector
      values.concat([nil] * (size-values.size)) if values.size < size
      Daru::Vector.new(values[0...size], index: @index, name: @name)
    end

    def nil_positions
      @nil_positions ||
        @nil_positions = size.times.select { |i| @data[i].nil? }
    end

    def nan_positions
      @nan_positions ||
        @nan_positions = size.times.select do |i|
          @data[i].respond_to?(:nan?) && @data[i].nan?
        end
    end

    # Helper method returning validity of arbitrary value
    def valid_value?(v)
      v.respond_to?(:nan?) && v.nan? || v.nil? ? false : true
    end

    def initialize_vector source, opts
      index, source = parse_source(source, opts)
      set_name opts[:name]

      @data  = cast_vector_to(opts[:dtype] || :array, source, opts[:nm_dtype])
      @index = Index.coerce(index || @data.size)

      guard_sizes!

      @possibly_changed_type = true
      # Include plotting functionality
      self.plotting_library = Daru.plotting_library
    end

    def parse_source source, opts
      if source.is_a?(Hash)
        [source.keys, source.values]
      else
        [opts[:index], source || []]
      end
    end

    def guard_sizes!
      if @index.size > @data.size
        cast(dtype: :array) # NM with nils seg faults
        @data.fill(nil, @data.size...@index.size)
      elsif @index.size < @data.size
        raise IndexError, "Expected index size >= vector size. Index size : #{@index.size}, vector size : #{@data.size}"
      end
    end

    def guard_type_check value
      @possibly_changed_type = true \
        if object? && (value.nil? || value.is_a?(Numeric)) ||
           numeric? && !value.is_a?(Numeric) && !value.nil?
    end

    def split_value key, v
      case
      when v.nil?           then nil
      when v.include?(key)  then 1
      else                       0
      end
    end

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
    # @param dtype [db_type] variable is set and the underlying data type of vector changed.
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

      @dtype = dtype
      new_vector
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

    # Raises IndexError when one of the positions is an invalid position
    def validate_positions *positions
      positions = [positions] if positions.is_a? Integer
      positions.each do |pos|
        raise IndexError, "#{pos} is not a valid position." if pos >= size
      end
    end

    # coerce ranges, integers and array in appropriate ways
    def coerce_positions *positions
      if positions.size == 1
        case positions.first
        when Integer
          positions.first
        when Range
          size.times.to_a[positions.first]
        else
          raise ArgumentError, 'Unkown position type.'
        end
      else
        positions
      end
    end

    # Helper method for []=.
    # Assigs existing index to another value
    def modify_vector(indexes, val)
      positions = @index.pos(*indexes)

      if positions.is_a? Numeric
        @data[positions] = val
      else
        positions.each { |pos| @data[pos] = val }
      end
    end

    # Helper method for []=.
    # Add a new index and assign it value
    def insert_vector(indexes, val)
      new_index = @index.add(*indexes)
      # May be create +=
      (new_index.size - @index.size).times { @data << val }
      @index = new_index
    end

    # Works similar to #[]= but also insert the vector in case index is not valid
    # It is there only to be accessed by Daru::DataFrame and not meant for user.
    def set indexes, val
      cast(dtype: :array) if val.nil? && dtype != :array
      guard_type_check(val)

      if @index.valid?(*indexes)
        modify_vector(indexes, val)
      else
        insert_vector(indexes, val)
      end

      update_position_cache
    end

    def cut_find_category partitions, val, close_at
      case close_at
      when :right
        right_index = partitions.index { |i| i > val }
        raise ArgumentError, 'Invalid partition' if right_index.nil?
        left_index = right_index - 1
        "#{partitions[left_index]}-#{partitions[right_index]-1}"
      when :left
        right_index = partitions.index { |i| i >= val }
        raise ArgumentError, 'Invalid partition' if right_index.nil?
        left_index = right_index - 1
        "#{partitions[left_index]+1}-#{partitions[right_index]}"
      else
        raise ArgumentError, "Invalid parameter #{close_at} to close_at."
      end
    end

    def cut_categories partitions, close_at
      case close_at
      when :right
        Array.new(partitions.size-1) do |left_index|
          "#{partitions[left_index]}-#{partitions[left_index+1]-1}"
        end
      when :left
        Array.new(partitions.size-1) do |left_index|
          "#{partitions[left_index]+1}-#{partitions[left_index+1]}"
        end
      end
    end

    def include_with_nan? array, value
      # Returns true if value is included in array.
      # Similar to include? but also works if value is Float::NAN
      if value.respond_to?(:nan?) && value.nan?
        array.any? { |i| i.respond_to?(:nan?) && i.nan? }
      else
        array.include? value
      end
    end

    def update_position_cache
      @nil_positions = nil
      @nan_positions = nil
    end

    def resort_index vector_index, opts
      if block_given?
        vector_index.sort { |(lv, _li), (rv, _ri)| yield(lv, rv) }
      else
        vector_index.sort(&DEFAULT_SORTER)
      end
        .tap { |res| res.reverse! unless opts[:ascending] }
    end
  end
end
