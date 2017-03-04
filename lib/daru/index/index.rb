module Daru
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
      alias :__new__ :new

      def inherited subclass
        class << subclass
          alias :new :__new__
        end
      end
    end

    # We over-ride the .new method so that any sort of Index can be generated
    # from Daru::Index based on the types of arguments supplied.
    def self.new *args, &block
      # FIXME: I'm not sure this clever trick really deserves our attention.
      # Most of common ruby libraries just avoid it in favor of usual
      # factor method, like `Index.create`. When `Index.new(...).class != Index`
      # it just leads to confusion and surprises. - zverok, 2016-05-18
      source = args.first

      MultiIndex.try_from_tuples(source) ||
        DateTimeIndex.try_create(source) ||
        allocate.tap { |i| i.send :initialize, *args, &block }
    end

    def self.coerce maybe_index
      maybe_index.is_a?(Index) ? maybe_index : Daru::Index.new(maybe_index)
    end

    def each(&block)
      return to_enum(:each) unless block_given?

      @relation_hash.each_key(&block)
      self
    end

    attr_reader :relation_hash, :size

    def initialize index
      index =
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

      @relation_hash = index.each_with_index.to_h.freeze
      @keys = @relation_hash.keys
      @size = @relation_hash.size
    end

    def ==(other)
      return false if self.class != other.class || other.size != @size

      @relation_hash.keys == other.to_a &&
        @relation_hash.values == other.relation_hash.values
    end

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

    # Returns true if all arguments are either a valid category or position
    # @param [Array<object>] *indexes categories or positions
    # @return [true, false]
    # @example
    #   idx.valid? :a, 2
    #   # => true
    #   idx.valid? 3
    #   # => false
    def valid? *indexes
      indexes.all? { |i| to_a.include?(i) || (i.is_a?(Numeric) && i < size) }
    end

    # Returns positions given indexes or positions
    # @note If the arugent is both a valid index and a valid position,
    #   it will treated as valid index
    # @param [Array<object>] *indexes indexes or positions
    # @example
    #   x = Daru::Index.new [:a, :b, :c]
    #   x.pos :a, 1
    #   # => [0, 1]
    def pos *indexes
      indexes = preprocess_range(indexes.first) if indexes.first.is_a? Range

      if indexes.size == 1
        self[indexes.first]
      else
        indexes.map { |index| by_single_key index }
      end
    end

    def subset *indexes
      if indexes.first.is_a? Range
        slice indexes.first.begin, indexes.first.end
      elsif include? indexes.first
        # Assume 'indexes' contain indexes not positions
        Daru::Index.new indexes
      else
        # Assume 'indexes' contain positions not indexes
        Daru::Index.new indexes.map { |k| key k }
      end
    end

    # Takes positional values and returns subset of the self
    #   capturing the indexes at mentioned positions
    # @param [Array<Integer>] positional values
    # @return [object] index object
    # @example
    #   idx = Daru::Index.new [:a, :b, :c]
    #   idx.at 0, 1
    #   # => #<Daru::Index(2): {a, b}>
    def at *positions
      positions = preprocess_positions(*positions)
      validate_positions(*positions)
      if positions.is_a? Integer
        key(positions)
      else
        self.class.new positions.map(&method(:key))
      end
    end

    def inspect threshold=20
      if size <= threshold
        "#<#{self.class}(#{size}): {#{to_a.join(', ')}}>"
      else
        "#<#{self.class}(#{size}): {#{to_a.first(threshold).join(', ')} ... #{to_a.last}}>"
      end
    end

    def slice *args
      start = args[0]
      en = args[1]

      if start.is_a?(Integer) && en.is_a?(Integer)
        Index.new @keys[start..en]
      else
        start_idx = @relation_hash[start]
        en_idx    = @relation_hash[en]

        Index.new @keys[start_idx..en_idx]
      end
    end

    # Produce new index from the set union of two indexes.
    def |(other)
      Index.new(to_a | other.to_a)
    end

    # Produce a new index from the set intersection of two indexes
    def & other
      Index.new(to_a & other.to_a)
    end

    def to_a
      @relation_hash.keys
    end

    def key(value)
      return nil unless value.is_a?(Numeric)
      @keys[value]
    end

    def include? index
      @relation_hash.key? index
    end

    # To check whether index value is any element of list `indexes`.
    #
    # @param indexes [Array] the list of indexes.
    # @return [Object] the Vector having true/false values. `true` at position `i`
    # if i'th index value is present in `indexes` . If i'th index value is not
    # present in `indexes` array then `false` at position `i` of the Vector.
    def isin indexes
      bool_array = @relation_hash.keys.map { |r| indexes.include?(r) }
      Daru::Vector.new(bool_array)
    end

    def empty?
      @relation_hash.empty?
    end

    def dup
      Daru::Index.new @relation_hash.keys
    end

    def add *indexes
      Daru::Index.new(to_a + indexes)
    end

    def _dump(*)
      Marshal.dump(relation_hash: @relation_hash)
    end

    def self._load data
      h = Marshal.load data

      Daru::Index.new(h[:relation_hash].keys)
    end

    # Provide an Index for sub vector produced
    #
    # @param input_indexes [Array] the input by user to index the vector
    # @return [Object] the Index object for sub vector produced
    def conform(*)
      self
    end

    def reorder(new_order)
      from = to_a
      self.class.new(new_order.map { |i| from[i] })
    end

    private

    def preprocess_range rng
      start   = rng.begin
      en      = rng.end

      if start.is_a?(Integer) && en.is_a?(Integer)
        @keys[start..en]
      else
        start_idx = @relation_hash[start]
        en_idx    = @relation_hash[en]

        @keys[start_idx..en_idx]
      end
    end

    def by_range rng
      slice rng.begin, rng.end
    end

    def by_multi_key *key
      if include? key[0]
        Daru::Index.new key.map { |k| k }
      else
        # Assume the user is specifing values for index not keys
        # Return index object having keys corresponding to values provided
        Daru::Index.new key.map { |k| key k }
      end
    end

    def by_single_key key
      if @relation_hash.key?(key)
        @relation_hash[key]
      elsif key.is_a?(Numeric) && key < size
        key
      else
        raise IndexError, "Specified index #{key.inspect} does not exist"
      end
    end

    # Raises IndexError when one of the positions is an invalid position
    def validate_positions *positions
      positions = [positions] if positions.is_a? Integer
      positions.each do |pos|
        raise IndexError, "#{pos} is not a valid position." if pos >= size
      end
    end

    # Preprocess ranges, integers and array in appropriate ways
    def preprocess_positions *positions
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
  end
end
