require 'forwardable'
require_relative 'shared'

module Daru
  def Daru.Index(values, name: nil)
    MultiIndex.try_create(values, name: name) ||
      DateTimeIndex.try_create(values, name: name) ||
      Index.new(values, name: name)
  end

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
  # * {CategoricalIndex}: special type of index, allowing repeating values (categories as an axis).
  #
  class Index
    include Enumerable
    extend Forwardable
    include IndexSharedBehavior

    # @private
    def self.coerce(maybe_index)
      maybe_index.is_a?(Index) ? maybe_index : Daru::Index.new(maybe_index)
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
    # @!method include?(value)
    #   If index includes the value specified.
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

    # Index value by position.
    #
    # @param position [Integer] Position in index 0...index.size
    # @return Lable at position, or nil if position is not numeric or outside the index size
    def key(position)
      return nil unless position.is_a?(Integer)
      keys[position]
    end

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
        positions_by_range(args.first)
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

    # Returns positions given indexes or positions.
    #
    # @note If any of arguments is a valid label, ALL arguments considered labels, this prohibits
    #   any ambiguity.
    # @param labels [Array<object>] indexes or positions
    # @example
    #   x = Daru::Index.new [:a, :b, :c]
    #   x.pos :a, 1
    #   # => [0, 1]
    # def pos(*indexes)
    #   indexes = preprocess_range(indexes.first) if indexes.first.is_a? Range
    #
    #   if indexes.size == 1
    #     numeric_pos indexes.first
    #   else
    #     indexes.map { |index| numeric_pos index }
    #   end
    # end
    def pos(*labels)
      if fetch_from_labels?(labels)
        self[*labels].tap { |result|
          result.is_a?(Array) && (idx = result.index(nil)) and fail(IndexError, "Undefined index label: #{labels[idx].inspect}")
        }
      elsif TypeCheck[Array, of: Integer].match?(labels) || TypeCheck[Range, of: Integer].match?(labels.first)
        preprocess_positions(labels).tap(&method(:validate_positions))
      else
        fail IndexError, "Undefined index label: #{labels.first.inspect}"
      end
    end

    def fetch_from_labels?(labels)
      if labels.first.is_a?(Range)
        keys.include?(labels.first.begin) || keys.include?(labels.first.end)
      else
        (keys & labels).any?
      end
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
      # FIXME: name
      Daru::Index.new keys
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

    def positions_by_range(rng)
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
