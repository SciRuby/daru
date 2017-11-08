require 'forwardable'
require_relative 'index/shared'

module Daru
  # Index is ordered, uniq set of labels, that is used throughout Daru as an axis for other data types
  # ({Vector} and {DataFrame}).
  #
  # It provides fast and convenient mapping from labels to row indexes and slicing/selecting of
  # subsets of data by labels and positions.
  #
  # `Index` class represents the most simple kind of an index: simple value labels (most usually
  # numbers, strings or symbols). `Daru` also includes more complicated and specialized indexes:
  #
  # * {MultiIndex}: each label is a **tuple** of values (for example
  #   `[division, subdivision, department]`), provides level-based slicing (e.g. "all from this
  #    subdivision").
  # * {DateTimeIndex}: each label is a timestamp, provides additional functionality for slicing by
  #   year or month, checking idex regularity and so on.
  # * {CategoricalIndex}: list of possible labels limited to a closed set of categories.
  #
  # @note
  #   Any custom Index-like object should conform to this API:
  #
  #   * `#initialize(labels, name:)`
  #   * `#pos(label, or *labels, or range, or position, or *positions, or range)`,
  #     raises `IndexError` is something not found
  #   * `#each { |label| ...`
  #   * `#include?(label)`
  #   * `#label(position)` (aliased as `#key` by historical reasons)
  #   * TBD! This list is WIP!
  #
  #   It is also nice (yet not strictly required) to provide:
  #
  #   * custom pretty `#inspect`;
  #   * reasonable `#==`.
  #
  #   Also, any data structures that use indexes, _should_ rely only on this interface, at least for
  #   base functionality (not guarded by `if index.is_a?(ParticularIndexClass)`... which is a code
  #   smell, BTW).
  class Index
    include Enumerable
    extend Forwardable
    include IndexSharedBehavior

    # Homogenously create index, guessing type from data passed.
    #
    # * if each label is an array of values, it would be {MultiIndex};
    # * if each label is `Time`, `Date`, or `DateTime`, it would be {DateTimeIndex};
    # * otherwise, just {Index}.
    #
    # @param labels [Array]
    # @param name Optional index name
    # @return [Index, MultiIndex, DateTimeIndex]
    def self.[](labels, name: nil)
      MultiIndex.try_create(labels, name: name) ||
        DateTimeIndex.try_create(labels, name: name) ||
        Index.new(labels, name: name)
    end

    # @private
    def self.coerce(maybe_index)
      maybe_index.is_a?(Daru::IndexSharedBehavior) ? maybe_index : Daru::Index[maybe_index]
    end

    # Optional name of the index.
    # @return [String]
    attr_reader :name

    # @param values [Enumerable] List of index labels.
    # @param name [String] Optional index name
    #
    # @example
    #
    #   idx = Daru::Index.new [2014, 2016, 2017]
    #   # => #<Daru::Index(3): {2014, 2016, 2017}>
    #
    #   idx = Daru::Index.new 2015..2017, name: 'year'
    #   # => #<Daru::Index(3): year {2015, 2016, 2017}>
    def initialize(values, name: nil)
      raise ArgumentError, "Index keys expected to be enumerable, #{values} got" unless values.respond_to?(:each)
      @relation_hash = values.each.with_index.to_h.freeze
      @name = name
    end

    def_delegators :@relation_hash, :keys, :size, :empty?, :include?
    alias to_a keys

    # @!method keys
    #   Raw list of index labels.
    #   @return [Array]
    # @!method size
    #   @return [Integer]
    # @!method include?(label)
    #   If index includes the label specified.
    #   @return [Boolean]

    # @param threshold [Integer] Maximum number of values to inspect.
    # @return [String]
    def inspect(threshold=20)
      name_part = @name ? "#{@name} " : ''
      if size <= threshold
        "#<#{self.class}(#{size}): #{name_part}{#{to_a.join(', ')}}>"
      else
        "#<#{self.class}(#{size}): #{name_part}{#{to_a.first(threshold).join(', ')} ... #{to_a.last}}>"
      end
    end

    # Two indexes are equal only if their data, order, and names are equal.
    #
    # @return [Boolean]
    def ==(other)
      self.class == other.class && relation_hash == other.relation_hash && name == other.name
    end

    # @return [self]
    def each(&block)
      return to_enum(:each) unless block_given?

      relation_hash.each_key(&block)
      self
    end

    # Index label by position.
    #
    # @param position [Integer] Position in index 0...index.size
    # @return Label at position, or nil if position is not numeric or outside the index size
    def label(position)
      return nil unless position.is_a?(Integer)
      keys[position]
    end

    alias key label

    # @overload [](value)
    #   @param value One value from index.
    #   @return [Integer, nil] Position corresponding to value provided, or `nil` if it is not in index.
    #
    # @overload [](range)
    #   @param range [Range] Range of values from index.
    #   @return [Array<Integer>, nil] Positions from first to last value of range. If last value is
    #     not in index, positions from first value to the end of index is returned. If first value is
    #     not in index, `nil` is returned.
    #
    # @overload [](*values)
    #   @param values [Array] List of values from index.
    #   @return [Array<Integer, nil>] For each value, either it corresponding position returned, or
    #     `nil` if it was not found in index.
    #
    # @return [Integer, Array<Integer>, nil]
    def [](*args)
      case
      when args.first.is_a?(Range)
        range2positions(args.first)
      when args.count > 1
        relation_hash.values_at(*args)
      else
        relation_hash[args.first]
      end
    end

    # Returns true if all arguments are either a valid category or position.
    #
    # @param indexes [Array<object>] categories or positions
    # @return [true, false]
    # @example
    #   idx.valid? :a, 2
    #   # => true
    #   idx.valid? 3
    #   # => false
    # def valid?(*indexes)
    #   indexes.all? { |i| include?(i) || (0...size).include?(i) }
    # end

    # Returns positions by labels or positions. Used by {Vector} and {DataFrame} to provide powerful
    # `#[]` implementation, working both in `Hash`-like and `Array`-like ways (e.g. `vector[0]` and
    # `vector['France']`).
    #
    # @example
    #   x = Daru::Index.new [:a, :b, :c]
    #   x.pos(:b)     # => [1] -- it always returns array of positions for simplified automatic processing
    #   x.pos(:a, :b) # => [0, 1]
    #   x.pos(1..2)   # => [1, 2]
    #   x.pos(:a, 1)  # => IndexError, you can't provide labels and positions at same time.
    #
    # @param labels [Range, Array, Object] Labels or positions. If any of arguments is a valid label,
    #   ALL arguments considered labels, this prohibits any ambiguity.
    # @return [Array<Integer>]
    # @raise IndexError if any of values passed is not in index/is not valid position.
    def pos(*labels)
      if fetch_from_labels?(labels)
        self[*labels].tap { |result|
          result.is_a?(Array) && (idx = result.index(nil)) and
            raise IndexError, "Undefined index label: #{labels[idx].inspect}"
        }
      elsif TypeCheck[Array, of: Integer].match?(labels) || TypeCheck[Range, of: Integer].match?(labels.first)
        preprocess_positions(labels).tap(&method(:validate_positions))
      else
        raise IndexError, "Undefined index label: #{labels.first.inspect}"
      end
    end

    def except(*labels)
      Index.new(keys - labels)
    end

    # def subset(*indexes)
    #   if indexes.first.is_a? Range
    #     start = indexes.first.begin
    #     en = indexes.first.end
    #
    #     subset_slice start, en
    #   elsif include? indexes.first
    #     # Assume 'indexes' contain indexes not positions
    #     Daru::Index.new indexes
    #   else
    #     # Assume 'indexes' contain positions not indexes
    #     Daru::Index.new(indexes.map { |k| key k })
    #   end
    # end

    # @note Do not use it to check for Float::NAN as
    #   Float::NAN == Float::NAN is false
    #
    # Return array of booleans with value at ith position is either
    # true or false depending upon whether index value at position i is equal to
    # any of the values passed in the argument or not.
    #
    # @param indexes [Array] values to equate with
    # @return [Daru::Vector] vector of boolean values
    # @example
    #   dv = Daru::Index.new [1, 2, 3, :one, 'one']
    #   dv.is_values 1, 'one'
    #   # => #<Daru::Vector(5)>
    #   #     0  true
    #   #     1  false
    #   #     2  false
    #   #     3  false
    #   #     4  true
    def is_values(*indexes) # rubocop:disable Naming/PredicateName
      keys.map { |r| indexes.include?(r) }
    end

    # @return [Index]
    def dup
      Daru::Index.new keys, name: name
    end

    # def add(*indexes)
    #   Daru::Index.new(to_a + indexes)
    # end

    # @private
    # Used by MultiIndex#conform
    def conform(*)
      self
    end

    # Sorts a `Index`, according to its values. Defaults to ascending order
    # sorting.
    #
    # @param [Boolean] ascending Pass `false` to get descending order.
    #
    # @return [Index] sorted `Index` according to its values.
    #
    # @example
    #   di = Daru::Index.new [100, 99, 101, 1, 2]
    #   di.sort #=> Daru::Index.new [1, 2, 99, 100, 101]
    #   di.sort(ascending: false) #=> Daru::Index.new [101, 100, 99, 2, 1]
    def sort(ascending: true)
      new_index, = ascending ? relation_hash.sort.transpose : relation_hash.sort.reverse.transpose

      self.class.new(new_index)
    end

    protected

    # Used in ==
    attr_reader :relation_hash

    private

    def fetch_from_labels?(labels)
      if labels.first.is_a?(Range)
        keys.include?(labels.first.begin) || keys.include?(labels.first.end)
      else
        (keys & labels).any?
      end
    end

    def preprocess_range(rng)
      start   = rng.begin
      en      = rng.end

      if start.is_a?(Integer) && en.is_a?(Integer)
        relation_hash.keys[start..en]
      else
        start_idx = @relation_hash[start]
        en_idx    = @relation_hash[en]

        keys[start_idx..en_idx]
      end
    end

    def range2positions(rng)
      begin_idx = relation_hash[rng.begin] or return nil
      end_idx   = relation_hash[rng.end] or return (begin_idx...size).to_a
      (rng.exclude_end? ? begin_idx...end_idx : begin_idx..end_idx).to_a
    end

    def numeric_pos(key)
      if @relation_hash.key?(key)
        @relation_hash[key]
      elsif key.is_a?(Numeric) && (key < size && key >= -size)
        key
      else
        raise IndexError, "Specified index #{key.inspect} does not exist"
      end
    end

    def slice(*args)
      start = args[0]
      en = args[1]

      start_idx = @relation_hash[start]
      en_idx    = @relation_hash[en]

      if start_idx.nil?
        nil
      elsif en_idx.nil?
        Array(start_idx..size-1)
      else
        Array(start_idx..en_idx)
      end
    end

    def subset_slice(*args)
      start = args[0]
      en = args[1]

      if start.is_a?(Integer) && en.is_a?(Integer)
        Index.new relation_hash.keys[start..en]
      else
        start_idx = @relation_hash[start]
        en_idx    = @relation_hash[en]
        Index.new relation_hash.keys[start_idx..en_idx]
      end
    end
  end
end
