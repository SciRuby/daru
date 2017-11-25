require 'idempotent_enumerable'

require 'daru/maths/arithmetic/vector.rb'
require 'daru/maths/statistics/vector.rb'
require 'daru/plotting/gruff.rb'
require 'daru/plotting/nyaplot.rb'
require 'daru/accessors/array_wrapper.rb'
require 'daru/accessors/nmatrix_wrapper.rb'
require 'daru/accessors/gsl_wrapper.rb'
require 'daru/category.rb'

module Daru
  # Vector is one-dimensional, non-unique, ordered list of values with labels and optional name.
  #
  # It is one of a base data structures of Daru, alongside with DataFrame (two-dimensional data
  # table consisting of Vectors).
  #
  # Vector behaves like an Array (values in vector can be enumerated and addressed by numeric positions)
  # and a Hash (addressed by labels in vector's Index) at the same time.
  #
  # TODO: This description should be extended and examples added. IdempotentEnumerable behavior should
  # be shown.
  #
  class Vector
    extend Gem::Deprecate
    extend Forwardable

    include IdempotentEnumerable
    idempotent_enumerable.constructor = :new_from_pairs

    include Maths::Arithmetic::Vector
    include Maths::Statistics::Vector

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
      def new_with_size(n, opts={}, &block)
        value = opts.delete :value
        block ||= ->(_) { value }
        Daru::Vector.new Array.new(n, &block), opts
      end

      def new_from_pairs(pairs)
        new(pairs.map(&:last), index: pairs.map(&:first))
      end

      def empty
        @empty ||= new([]).freeze
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

    # Store vector data in an array
    attr_reader :data
    # Ploting library being used for this vector
    attr_reader :plotting_library

    def_delegators :@data, :to_a, :size, :empty?

    # Create Vector from Array or Hash.
    #
    # @param source [Array, Hash] Array of vector values or hash of `{index label => vector value}`.
    #   In the former case, `index` parameter is ignored.
    # @param name [String] Optional vector name.
    # @param index [Daru::Index, Array, Hash] Any object from which {Index} can be constructed. If
    #   index size is lower than values size, error is raised. If index size is greater, vector is
    #   padded with `nil`s. If index is omitted, default counting index (0, 1, 2) will be created.
    #
    # @example
    #    Daru::Vector.new([100, 200, 300], name: :salary, index: %w[Jill John Mary])
    #    # => #<Daru::Vector(3)>
    #    #         salary
    #    #   Jill    100
    #    #   John    200
    #    #   Mary    300
    #    Daru::Vector.new([100, 200, 300])
    #    # => #<Daru::Vector(3)>
    #    #       0    100
    #    #       1    200
    #    #       2    300
    #    Daru::Vector.new(Jill: 100, John: 200, Mary: 300)
    #    # => #<Daru::Vector(3)>
    #    #   Jill    100
    #    #   John    200
    #    #   Mary    300
    #
    def initialize(source, name: nil, index: nil)
      source, index = source.values, source.keys if source.is_a?(Hash)
      data = source.to_a
      reset!(index, data)

      @name = name
    end

    # @private
    def initialize_dup(other)
      reset!(other.index.dup, other.data.dup)
      @name = other.name
    end

    # Two vectors are equal if they have the exact same index values corresponding
    # with the exact same elements. Name is ignored.
    #
    # @param other [Vector]
    # @return [true, false]
    def ==(other)
      other.is_a?(Daru::Vector) && @index == other.index && @data == other.data
    end

    # @return [Sring]
    def inspect(spacing=20, threshold=15)
      row_headers = index.is_a?(MultiIndex) ? index.sparse_tuples : index.to_a

      "#<#{self.class}(#{size})#{':category' if category?}>\n" +
        Formatters::Table.format(
          to_a.lazy.map { |v| [v] },
          headers: name && [name],
          row_headers: row_headers,
          threshold: threshold,
          spacing: spacing
        )
    end

    # @return [String]
    def to_s
      "#<#{self.class}#{': ' + @name.to_s if @name}(#{size})#{':category' if category?}>"
    end

    # Type of the underlying data: `:numeric` (if only numbers/nils) or `:object` for generic data.
    #
    # @return [Symbol]
    def type
      data.all? { |e| e.is_a?(Numeric) || e.nil? } ? :numeric : :object
    end

    # If all data is numeric
    #
    # @see #type
    def numeric?
      type == :numeric
    end

    # If all data is of generic types (not all numeric).
    #
    # @see #type
    def object?
      type == :object
    end

    # Fetching and slicing =========================================================================

    # Get element(s) from vector by index values or numeric positions.
    #
    # The logic of deciding if it is index value or position is following:
    # * if any of input values is present in index, all input values are decided to be values from
    #   index (even if the values are positive integers);
    # * if none of values are in the index, but all of them are positive integers, they are decided
    #   to be numeric positions;
    # * otherwise, `IndexError` is raised.
    #
    # @overload [](label)
    #   @param label Label from index.
    #   @return One value from vector corresponding to this label.
    # @overload [](position)
    #   @note If index has this value, it is considered to be index label, not numeric position.
    #   @example
    #     vector = Vector.new(%[a b c], index: [1, 2, 3])
    #     vector[0] # => a
    #     vector[1] # => a, treated as label
    #   @param position [Integer] Numeric position in vector.
    #   @return One value from vector corresponding to this position.
    # @overload [](*labels)
    #   @param labels [Array] Labels from index.
    #   @return [Array] Value from vector corresponding to these labels.
    # @overload [](*positions)
    #   @note If index has ANY of the provided values, ALL of them treated as index labels, not positions.
    #   @param positions [Array<Integer>] Numeric positions in vector.
    #   @return [Array] Values from vector corresponding to these positions.
    # @overload [](labels_range)
    #   @param labels_range [Range] Labels range from index.
    #   @return Values corresponding to index part between range begin and end. If range end is not in
    #     index, returns values from range begin to the vector end. If range begin is not in the index,
    #     returns nil
    # @overload [](positions_range)
    #   @note If index has either range beginning, or range end, the range is considered to be index
    #     labels, not numeric positions.
    #   @param positions_range [Range<Integer>] Range of numeric positions in vector.
    #   @return [Array] Values from vector corresponding to range.
    #
    # @example
    #   # TODO
    #
    def [](*labels_or_positions)
      positions = index.pos(*labels_or_positions)

      return data[positions] if positions.is_a?(Integer)

      Daru::Vector.new(
        data.values_at(*positions),
        name: name,
        index: index.keys_at(*positions)
      )
    end

    # Fetches singular value, or a subset of vector by positional values.
    #
    # @param positions [Array<Integer>] positional values
    # @return [Vector]
    #
    # @example
    #   dv = Daru::Vector.new 'a'..'e'
    #   dv.at 0, 1, 2
    #   # => #<Daru::Vector(3)>
    #   #   0   a
    #   #   1   b
    #   #   2   c
    def at(*positions)
      positions = coerce_positions(*positions)
      validate_positions(*positions)

      # FIXME: maybe always return array?
      return data[positions] if positions.is_a? Integer
      Daru::Vector.new data.values_at(*positions), index: index.keys_at(*positions)
    end

    def values_at(*positions)
      positions = coerce_positions(*positions)
      validate_positions(*positions)

      data.values_at(*positions)
    end

    # Examining/querying ===========================================================================

    # Returns index label for the specified value.
    #
    # @return [Integer, nil]
    def index_of(element)
      index.label(data.index(element))
    end

    # Check if any of values occur in the vector. Unlike standard `Enumerable#include?` also handles
    # `Float::NAN` inclusion (usual pattern for "nothing here" for numeric computations with homogenous
    # data types, when `nil` is not appropriate).
    #
    # @param values [Array] values to check for
    # @example
    #   dv = Daru::Vector.new [1, 2, 3, 4, nil]
    #   dv.include_values? nil, Float::NAN
    #   # => true
    def include_values?(*values)
      values.any? { |v| include_with_nan? data, v }
    end

    # If vector's index includes label specified
    #
    # @param label Label from vector's index.
    def has_label?(label)
      index.include? label
    end

    # TODO: deprecate
    alias has_index? has_label?

    # Count the number of specified values' entries in vector.
    #
    # @param values [Array] values to count
    # @return [Integer] the number of times the values mentioned occurs
    # @example
    #   dv = Daru::Vector.new [1, 2, 1, 2, 3, 4, nil, nil]
    #   dv.count_values nil
    #   # => 2
    def count_values(*values)
      positions(*values).size
    end

    # List of numeric positions for vector values provided.
    #
    # @note
    #   Positions are ordered ascending, regardless of argument values order.
    #
    # @param values [Array] Values to fetch positions of.
    # @return [Array<Integer>]
    def positions(*values)
      data
        .each_with_index
        .select { |val, _i| values.any? { |test| eq_with_nan?(val, test) } }
        .map(&:last)
    end

    # Enumerable-alike =============================================================================

    # Enumerates all (label, value) pairs in the index.
    #
    # @see each_value, each_label
    #
    # @example
    #   # TODO
    #
    # @return [Enumerator, self]
    def each
      return to_enum(:each) unless block_given?

      index.each_with_index { |idx, i| yield(idx, data[i]) }
      self
    end

    # Produces new Vector with the same index and name as current one, and values processed by
    # block passed.
    #
    # @example:
    #   vector = Daru::Vector.new([100, 200, 300], name: :salary, index: %w[Jill John Mary])
    #   vector.recode { |val| val / 100.0 }
    #   # => #<Daru::Vector(3)>
    #   #        salary
    #   #   Jill    1.0
    #   #   John    2.0
    #   #   Mary    3.0
    #
    # @return [Vector]
    def recode(&block)
      return to_enum(:recode) unless block_given?

      dup.recode!(&block)
    end

    # Destructive version of {#recode}
    # FIXME: methods are documented in inconsistent order (compare with reindex/reorder)
    #
    # @return [self]
    def recode!(&block)
      return to_enum(:recode!) unless block_given?

      data.map!(&block)
      self
    end

    # Sorts the vector according to its index.
    #
    # @return [Vector]
    #
    # @example
    #   dv = Daru::Vector.new [11, 13, 12], index: [23, 21, 22]
    #   dv.sort_by_index
    #   # => Daru::Vector.new [13, 12, 11], index: [21, 22, 23]
    def sort_by_index
      sort_by(&:first)
    end

    # Produce vector with uniq elements of current one. If optional block is provided, it is used
    # to decide whether element is uniq, otherwise it is just a simple "uniq by value".
    #
    # @yield [idx, val] Block that should return truthy or falsy values.
    # @yieldparam idx Index label
    # @yieldparam val Vector value
    #
    # @return [Vector]
    def uniq
      new_index, new_values =
        each
        .group_by { |idx, val| block_given? ? yield(idx, val) : val }
        .map { |_, group| group.first }.transpose

      Vector.new new_values, index: new_index
    end

    # Return a vector with specified values removed.
    #
    # @param values [Array] values to reject from resultant vector
    # @return [Daru::Vector] vector with specified values removed
    # @example
    #   dv = Daru::Vector.new [1, 2, nil, Float::NAN]
    #   dv.reject_values nil, Float::NAN
    #   # => #<Daru::Vector(2)>
    #   #   0   1
    #   #   1   2
    def reject_values(*values)
      positions = size.times.to_a - positions(*values)
      positions.count == 1 ? at(positions.first..positions.first) : at(*positions)
    end

    # Modify vector elements =======================================================================

    # Assign value(s) by index labels or numeric positions.
    #
    # @param labels_or_positions The same set of possible values as for {#[]}: one, or array, or range
    #   of index labels, or numeric positions.
    # @param val Value to assign to all places referred to by `labels_or_positions`.
    #
    # @see []
    # @example
    #   v = Daru::Vector.new([1,2,3], index: %i[a b c])
    #   v[:a] = 999
    #   v[:b, :c] = 888
    #   v
    #   # => #<Daru::Vector(3)>
    #   #   a 999
    #   #   b 888
    #   #   c 888
    def []=(*labels_or_positions, val)
      positions = index.pos(*labels_or_positions)

      if positions.is_a? Numeric
        data[positions] = val
      else
        positions.each { |pos| data[pos] = val }
      end
    end

    # Deletes element from vector by index label.
    #
    # @param label Label to delete element at
    # @return Deleted element or nil if label was not in the vector
    def delete_at(label)
      pos = index[*label] or return nil
      @index = index.except(label)
      data.delete_at(pos)
    end

    # Deletes an element from vector by value.
    # If element is present several times, all entries are deleted.
    #
    # @param element Element to delete
    # @return Deleted element or nil if element was not in the vector
    def delete(element)
      positions = data.each_with_index.select { |val, _| val == element }.map(&:last)
      return nil if positions.empty?
      @data.reject! { |val| val == element }
      @index = index.except(*positions.map { |pos| index.label(pos) })
      element
    end

    # Give the vector a new name
    #
    # @param new_name [Symbol, String] The new name.
    # @return [self]
    def rename!(new_name)
      @name = new_name
      self
    end

    # Create the copy of vector with a new name.
    #
    # @param new_name [Symbol, String] The new name.
    # @return [Vector]
    def rename(new_name)
      dup.rename(new_name)
    end

    # Reorders vector according to new index provided. If the label of a new index was present in
    # the vector, corresponding value is preserved, otherwise value is filled with `nil`.
    #
    # @see #reorder! to change vector order according to positions list provided
    # @param [Daru::Index, Daru::MultiIndex] new_index new index to order with
    # @return [self]
    def reindex!(new_index)
      new_data = index[*new_index.to_a].map { |pos| pos.nil? ? nil : data[pos] }

      reset!(new_index, new_data)

      self
    end

    # Non-destructive version of {#reindex!}.
    #
    # @return [Vector]
    def reindex(new_index)
      dup.reindex!(new_index)
    end

    # Reorder the vector with given positions.
    #
    # @see #reindex! to change vector order according to new index labels
    # @param positions [Array<Integer>] List of current vector positions in desired order.
    # @return [self]
    # @example
    #   dv = Daru::Vector.new [3, 2, 1], index: ['c', 'b', 'a']
    #   dv.reorder! [2, 1, 0]
    #   # => #<Daru::Vector(3)>
    #   #   a   1
    #   #   b   2
    #   #   c   3
    def reorder!(positions)
      reset!(index.reorder(positions), data.values_at(*positions))
      self
    end

    # Non-destructive version of {#reorder!}.
    #
    # @param positions [Array<Integer>] List of current vector positions in desired order.
    # @return [Vector]
    def reorder(positions)
      dup.reorder! positions
    end

    # Replaces vector's index with default one: `0, 1, 2, ...size-1`.
    #
    # @return [self]
    def reset_index!
      reset!(nil, data)
      self
    end

    # Non-destructive version of {#reset_index!}.
    #
    # @return [Vector]
    def reset_index
      dup.reset_index!
    end

    # Replace all empty values (NAN and nil) with next or previous value of the vector.
    #
    #
    # @param direction [:forward, :backward] "Forward" means that vector filling is done from start
    #   to end (non-empty value "spreads" forward on all empty positions), "backward" means the other
    #   way. Empty values at the beginning (if forward) or end (if backward) are filled with 0.
    # @return [self]
    #
    # @example
    #   dv = Daru::Vector.new([1, 2, nil, 4])
    #   dv.rolling_fillna!
    #   # => #<Daru::Vector(4)>
    #   #   0   1
    #   #   1   2
    #   #   2   2
    #   #   3   4
    #
    #   dv = Daru::Vector.new([1, 2, nil, 4])
    #   dv.rolling_fillna!(:backward)
    #   # => #<Daru::Vector(4)>
    #   #   0   1
    #   #   1   2
    #   #   2   4
    #   #   3   4
    def rolling_fillna!(direction=:forward)
      enum = direction == :forward ? data.each_with_index : data.each_with_index.reverse_each
      last_valid_value = 0
      enum.each do |val, i|
        if valid_value?(val)
          last_valid_value = val
        else
          data[i] = last_valid_value
        end
      end
      self
    end

    # Non-destructive version of {#rolling_fillna!}
    #
    # @param direction [:forward, :backward] "Forward" means that vector filling is done from start
    #   to end (non-empty value "spreads" forward on all empty positions), "backward" means the other
    #   way. Empty values at the beginning (if forward) or end (if backward) are filled with 0.
    # @return [Vector]
    def rolling_fillna(direction=:forward)
      dup.rolling_fillna!(direction)
    end

    # "Lags" the vector by specified amount of periods.
    #
    # Data is shifted forwards (if `periods` is positive) or backwards (if negative) and padded with
    # nils.
    #
    # @param periods [Integer] Shift amount.
    # @return [self]
    #
    # @example
    #   Daru::Vector.new(1..3).lag!
    #   # => #<Daru::Vector(3)>
    #   #   0 nil
    #   #   1   1
    #   #   2   2
    #   Daru::Vector.new(1..3).lag!(-2)
    #   # => #<Daru::Vector(3)>
    #   #   0   3
    #   #   1 nil
    #   #   2 nil
    #   Daru::Vector.new(1..3).lag!(100)
    #   # => #<Daru::Vector(3)>
    #   #   0 nil
    #   #   1 nil
    #   #   2 nil
    #
    def lag!(periods=1)
      case periods
      when 0 then self
      when 1...size
        reset!(index, ([nil] * periods + data)[0...size])
      when -size..-1
        reset!(index, data[periods.abs...size])
      else
        reset!(index, [])
      end
      self
    end

    # Non-destructive version of {#lag!}
    #
    # @param periods [Integer] Shift amount.
    # @return [Vector]
    def lag(periods=1)
      dup.lag!(periods)
    end

    # Replaces specified values with a new value.
    #
    # @param old_values [Object, Array] Value, or array of values, to replace.
    # @param new_value New value to replace with.
    # @return [self]
    # @example
    #   dv = Daru::Vector.new [1, 2, :a, :b]
    #   dv.replace_values! [:a, :b], nil
    #   dv
    #   # =>
    #   # #<Daru::Vector:19903200 @name = nil @metadata = {} @size = 4 >
    #   #     nil
    #   #   0   1
    #   #   1   2
    #   #   2 nil
    #   #   3 nil
    def replace_values!(old_values, new_value)
      old_values = Array(old_values)
      data.each_with_index { |val, i| data[i] = new_value if include_with_nan?(old_values, val) }
      self
    end

    # Non-destructive version of {#replace_values!}
    #
    # @param old_values [Object, Array] Value, or array of values, to replace.
    # @param new_value New value to replace with.
    # @return [Vector]
    def replace_values(old_values, new_value)
      dup.replace_values!(old_values, new_value)
    end

    # NOT REFACTORED CODE STARTS BELOW THIS LINE ===================================================
    public

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
    def set_at(positions, val)
      validate_positions(*positions)
      positions.map { |pos| @data[pos] = val }
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
    def concat(element, index)
      raise IndexError, 'Expected new unique index' if @index.include? index

      @index |= [index]
      @data[@index[index]] = element
    end
    alias :push :concat
    alias :<< :concat

    # Cast a vector to a new data type.
    #
    # == Options
    #
    # * +:dtype+ - :array for Ruby Array. :nmatrix for NMatrix.
    def cast(opts={})
      dt = opts[:dtype]
      raise ArgumentError, "Unsupported dtype #{opts[:dtype]}" unless %i[array nmatrix gsl].include?(dt)

      @data = cast_vector_to dt unless @dtype == dt
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

    # @return [Daru::DataFrame] the vector as a single-vector dataframe
    def to_df
      Daru::DataFrame.new({name => data}, name: name, index: index)
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

    # Converts a non category type vector to category type vector.
    # @param [Hash] opts options to convert to category
    # @option opts [true, false] :ordered Specify if vector is ordered or not.
    #   If it is ordered, it can be sorted and min, max like functions would work
    # @option opts [Array] :categories set categories in the specified order
    # @return [Daru::Vector] vector with type category
    def to_category(opts={})
      dv = Daru::Vector.new to_a, type: :category, name: @name, index: @index
      dv.ordered = opts[:ordered] || false
      dv.categories = opts[:categories] if opts[:categories]
      dv
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
    def cut(partitions, opts={})
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

    def group_by(*args)
      to_df.group_by(*args)
    end

    private

    def copy(values)
      # Make sure values is right-justified to the size of the vector
      values.concat([nil] * (size-values.size)) if values.size < size
      Daru::Vector.new(values[0...size], index: @index, name: @name)
    end

    # Helper method returning validity of arbitrary value
    def valid_value?(v)
      v.respond_to?(:nan?) && v.nan? || v.nil? ? false : true
    end

    def initialize_vector(source, opts)
      index, source = parse_source(source, opts)
      set_name opts[:name]

      @data  = cast_vector_to(opts[:dtype] || :array, source, opts[:nm_dtype])
      @index = Index.coerce(index || (@data.size.zero? ? [] : 0...@data.size))

      guard_sizes!

      @possibly_changed_type = true
      # Include plotting functionality
      self.plotting_library = Daru.plotting_library
    end

    def parse_source(source, opts)
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
        raise ArgumentError,
          "Expected index size >= vector size. Index size : #{@index.size}, vector size : #{@data.size}"
      end
    end

    def split_value(key, v)
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
    def cast_vector_to(dtype, source=nil, nm_dtype=nil)
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

    def set_name(name) # rubocop:disable Naming/AccessorMethodName
      # Join in case of MultiIndex tuple
      @name = name.is_a?(Array) ? name.join : name
    end

    # Raises IndexError when one of the positions is an invalid position
    def validate_positions(*positions)
      positions = [positions] if positions.is_a? Integer
      positions.each do |pos|
        raise IndexError, "#{pos} is not a valid position." if pos >= size
      end
    end

    # coerce ranges, integers and array in appropriate ways
    def coerce_positions(*positions)
      return positions unless positions.size == 1
      case positions.first
      when Integer
        positions.first
      when Range
        size.times.to_a[positions.first]
      else
        raise ArgumentError, 'Unkown position type.'
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
    def set(indexes, val)
      cast(dtype: :array) if val.nil? && dtype != :array
      guard_type_check(val)

      if @index.valid?(*indexes)
        modify_vector(indexes, val)
      else
        insert_vector(indexes, val)
      end
    end

    def cut_find_category(partitions, val, close_at)
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

    def cut_categories(partitions, close_at)
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

    def eq_with_nan?(left, right)
      left.respond_to?(:nan?) && left.nan? && right.respond_to?(:nan?) && right.nan? ||
        left == right
    end

    def include_with_nan?(array, value)
      # Returns true if value is included in array.
      # Similar to include? but also works if value is Float::NAN
      if value.respond_to?(:nan?) && value.nan?
        array.any? { |i| i.respond_to?(:nan?) && i.nan? }
      else
        array.include? value
      end
    end

    def reset!(index, data)
      index = Index.coerce(index || (data.size.zero? ? [] : 0...data.size))
      if index.size > data.size
        data.fill(nil, data.size...index.size)
      elsif index.size < data.size
        raise ArgumentError,
          "Expected index size >= vector size. Index size : #{index.size}, vector size : #{data.size}"
      end

      @index = index
      @data = data
    end
  end
end
