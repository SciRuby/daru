require 'forwardable'

module Daru
  # Index is ordered, uniq set of labels, that is used througout Daru as an axis for other data types
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
    # It so happens that over riding the .new method in a super class also
    # tampers with the default .new method for class that inherit from the
    # super class (Index in this case). Thus we first alias the original
    # new method (from Object) to __new__ when the Index class is evaluated,
    # and then we use an inherited hook such that the old new method (from
    # Object) is once again the default .new for the subclass.
    # Refer http://blog.sidu.in/2007/12/rubys-new-as-factory.html
    class << self
      # @private
      alias :__new__ :new

      # @private
      def inherited(subclass)
        class << subclass
          alias :new :__new__
        end
      end
    end

    # @private
    # We over-ride the .new method so that any sort of Index can be generated
    # from Daru::Index based on the types of arguments supplied.
    def self.new(*args, &block)
      # FIXME: I'm not sure this clever trick really deserves our attention.
      # Most of common ruby libraries just avoid it in favor of usual
      # factor method, like `Index.create`. When `Index.new(...).class != Index`
      # it just leads to confusion and surprises. - zverok, 2016-05-18
      source = args.first

      MultiIndex.try_from_tuples(source) ||
        DateTimeIndex.try_create(source) ||
        allocate.tap { |i| i.send :initialize, *args, &block }
    end

    def self.coerce(maybe_index)
      maybe_index.is_a?(Index) ? maybe_index : Daru::Index.new(maybe_index)
    end

    extend Forwardable

    # Optional name of the index.
    # @return [String]
    attr_reader :name
    attr_writer :name # TODO: deprecate

    # @param index [#to_a, Integer, nil] Values of index labels, or size of index, or nothing, to
    #   construct an empty index.
    # @param name [String] Optional index name
    #
    # @example
    #
    #   idx = Daru::Index.new [2014, 2016, 2017]
    #   # => #<Daru::Index(3): {2014, 2016, 2017}>
    #
    #   idx = Daru::Index.new 2015..2017, name: 'year'
    #   # => #<Daru::Index(3): year {2015, 2016, 2017}>
    def initialize(index, name: nil)
      index = guess_index index
      @relation_hash = index.each_with_index.to_h.freeze
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

    # Get a single value, or subset of index values, by key, position, range and several.
    #
    #
    def [](key, *rest)
      case
      when key.is_a?(Range)
        by_range key
      when !rest.empty?
        by_multi_key key, *rest
      else
        by_single_key key
      end
    end

    # Returns true if all arguments are either a valid category or position.
    #
    # FIXME: Why do we need this? "Category or position" feels smelly.
    #
    # @param indexes [Array<object>] categories or positions
    # @return [true, false]
    # @example
    #   idx.valid? :a, 2
    #   # => true
    #   idx.valid? 3
    #   # => false
    def valid?(*indexes)
      indexes.all? { |i| include?(i) || (i.is_a?(Integer) && i < size) }
    end

    # Returns positions given indexes or positions.
    #
    # @note If the argument is both a valid index and a valid position,
    #   it will treated as valid index
    # @param indexes [Array<object>] indexes or positions
    # @example
    #   x = Daru::Index.new [:a, :b, :c]
    #   x.pos :a, 1
    #   # => [0, 1]
    def pos(*indexes)
      indexes = preprocess_range(indexes.first) if indexes.first.is_a? Range

      if indexes.size == 1
        numeric_pos indexes.first
      else
        indexes.map { |index| numeric_pos index }
      end
    end

    def subset(*indexes)
      if indexes.first.is_a? Range
        start = indexes.first.begin
        en = indexes.first.end

        subset_slice start, en
      elsif include? indexes.first
        # Assume 'indexes' contain indexes not positions
        Daru::Index.new indexes
      else
        # Assume 'indexes' contain positions not indexes
        Daru::Index.new(indexes.map { |k| key k })
      end
    end

    # FIXME: why do we need it? What it means? Why it has no docs?
    def key(value)
      return nil unless value.is_a?(Numeric)
      relation_hash.keys[value]
    end

    # @note Do not use it to check for Float::NAN as
    #   Float::NAN == Float::NAN is false
    # Return vector of booleans with value at ith position is either
    # true or false depending upon whether index value at position i is equal to
    # any of the values passed in the argument or not
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
      bool_array = @relation_hash.keys.map { |r| indexes.include?(r) }
      Daru::Vector.new(bool_array)
    end

    # @return [Index]
    def dup
      # FIXME: name
      Daru::Index.new keys
    end

    def add(*indexes)
      Daru::Index.new(to_a + indexes)
    end

    # @private
    # Used by MultiIndex#conform
    def conform(*)
      self
    end

    def values_at(*positions)
      keys.values_at(*positions)
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

    def guess_index(index)
      case index
      when nil
        []
      when Integer
        index.times.to_a
      when Enumerable
        index.to_a
      else
        raise ArgumentError,
          "Cannot create index from #{index.class} #{index.inspect}"
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

    def by_range(rng)
      slice rng.begin, rng.end
    end

    def by_multi_key(*key)
      key.map { |k| by_single_key k }
    end

    def by_single_key(key)
      if @relation_hash.key?(key)
        @relation_hash[key]
      else
        nil
      end
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
