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
      @relation_hash.each_key(&block)
      self
    end

    def map(&block)
      to_a.map(&block)
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
    
    def respond? *indexes
      indexes.all? { |i| to_a.include?(i) || (i.is_a?(Numeric) && i < size) }
    end
    
    def pos *args
      # Causes Segmentation fault
      if args.first.is_a? Range
        args = preprocess_range(args.first)
      end
      return self[args.first] if args.size == 1
      args.map { |index| by_single_key index }
    end
    
    def subset *args
      if args.first.is_a? Range
        slice args.first.begin, args.first.end
      elsif include? args[0]
        Daru::Index.new args
      else
        # Assume the user is specifing values for index not keys
        # Return index object having keys corresponding to values provided
        Daru::Index.new args.map { |k| key k }
      end
    end
    
    def at *args
      return key(args.first) if args.size == 1
      Daru::Index.new args.map { |p| key p }
    end

    def inspect threshold=20
      if size <= threshold
        "#<#{self.class}(#{size}): {#{to_a.join(', ')}}>"
      else
        "#<#{self.class}(#{size}): {#{to_a.first(threshold).join(', ')} ... #{to_a.last}}>"
      end
    end

    def slice *args
      start   = args[0]
      en      = args[1]

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
      @relation_hash.keys[value]
    end

    def include? index
      @relation_hash.key? index
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
      Daru::Index.new(new_order.map { |i| from[i] })
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
  end # class Index

  class MultiIndex < Index
    include Enumerable

    def each(&block)
      to_a.each(&block)
    end

    def map(&block)
      to_a.map(&block)
    end

    attr_reader :labels

    def levels
      @levels.map(&:keys)
    end

    def initialize opts={}
      labels = opts[:labels]
      levels = opts[:levels]
      raise ArgumentError,
        'Must specify both labels and levels' unless labels && levels
      raise ArgumentError,
        'Labels and levels should be same size' if labels.size != levels.size
      raise ArgumentError,
        'Incorrect labels and levels' if incorrect_fields?(labels, levels)

      @labels = labels
      @levels = levels.map { |e| e.map.with_index.to_h }
    end

    def incorrect_fields?(_labels, levels)
      levels[0].size # FIXME: without this exact call some specs are failing

      levels.any? { |e| e.uniq.size != e.size }
    end

    private :incorrect_fields?

    def self.from_arrays arrays
      levels = arrays.map { |e| e.uniq.sort_by(&:to_s) }

      labels = arrays.each_with_index.map do |arry, level_index|
        level = levels[level_index]
        arry.map { |lvl| level.index(lvl) }
      end

      MultiIndex.new labels: labels, levels: levels
    end

    def self.from_tuples tuples
      from_arrays tuples.transpose
    end

    def self.try_from_tuples tuples
      if tuples.respond_to?(:first) && tuples.first.is_a?(Array)
        from_tuples(tuples)
      else
        nil
      end
    end

    def [] *key
      key.flatten!
      case
      when key[0].is_a?(Range)
        retrieve_from_range(key[0])
      when key[0].is_a?(Integer) && key.size == 1
        try_retrieve_from_integer(key[0])
      else
        begin
          retrieve_from_tuples key
        rescue NoMethodError
          raise IndexError, "Specified index #{key.inspect} do not exist"
        end
      end
    end
    
    def respond? *indexes
      pos(*indexes)
      return true
      rescue IndexError
        return false
    end
    
    def pos *args
      if args.first.is_a? Integer
        return args.first if args.size == 1
        return args
      end
      res = self[args]
      return res if res.is_a? Integer
      res.map { |i| self[i] }
    end
    
    def subset *args
      if args.first.is_a? Integer
        MultiIndex.from_tuples(args.map { |index| key(index) })
      else
        self[args].conform args
      end
    end
    
    def at *args
      return key(args.first) if args.size == 1
      Daru::MultiIndex.from_tuples args.map { |p| key p }
    end
    
    def add *indexes
      Daru::MultiIndex.from_tuples to_a << indexes
    end    

    def try_retrieve_from_integer int
      @levels[0].key?(int) ? retrieve_from_tuples([int]) : int
    end

    def retrieve_from_range range
      MultiIndex.from_tuples(range.map { |index| key(index) })
    end

    def retrieve_from_tuples key
      chosen = []

      key.each_with_index do |k, depth|
        level_index = @levels[depth][k]
        raise IndexError, "Specified index #{key.inspect} do not exist" if level_index.nil?
        label = @labels[depth]
        chosen = find_all_indexes label, level_index, chosen
      end

      return chosen[0] if chosen.size == 1 && key.size == @levels.size
      multi_index_from_multiple_selections(chosen)
    end

    def multi_index_from_multiple_selections chosen
      MultiIndex.from_tuples(chosen.map { |e| key(e) })
    end

    def find_all_indexes label, level_index, chosen
      if chosen.empty?
        label.each_with_index
             .select { |lbl, _| lbl == level_index }.map(&:last)
      else
        chosen.keep_if { |c| label[c] == level_index }
      end
    end

    private :find_all_indexes, :multi_index_from_multiple_selections,
      :retrieve_from_range, :retrieve_from_tuples

    def key index
      raise ArgumentError,
        "Key #{index} is too large" if index >= @labels[0].size

      @labels
        .each_with_index
        .map { |label, i| @levels[i].keys[label[index]] }
    end

    def dup
      MultiIndex.new levels: levels.dup, labels: labels
    end

    def drop_left_level by=1
      MultiIndex.from_arrays to_a.transpose[by..-1]
    end

    def | other
      MultiIndex.from_tuples(to_a | other.to_a)
    end

    def & other
      MultiIndex.from_tuples(to_a & other.to_a)
    end

    def empty?
      @labels.flatten.empty? && @levels.all?(&:empty?)
    end

    def include? tuple
      tuple.flatten.each_with_index
           .all? { |tup, i| @levels[i][tup] }
    end

    def size
      @labels[0].size
    end

    def width
      @levels.size
    end

    def == other
      self.class == other.class  &&
        labels   == other.labels &&
        levels   == other.levels
    end

    def to_a
      (0...size).map { |e| key(e) }
    end

    def values
      Array.new(size) { |i| i }
    end

    def inspect threshold=20
      "#<Daru::MultiIndex(#{size}x#{width})>\n" +
        Formatters::Table.format([], row_headers: sparse_tuples, threshold: threshold)
    end

    def to_html
      path = File.expand_path('../iruby/templates/multi_index.html.erb', __FILE__)
      ERB.new(File.read(path).strip).result(binding)
    end

    # Provide a MultiIndex for sub vector produced
    #
    # @param input_indexes [Array] the input by user to index the vector
    # @return [Object] the MultiIndex object for sub vector produced
    def conform input_indexes
      return self if input_indexes[0].is_a? Range
      drop_left_level input_indexes.size
    end

    # Return tuples with nils in place of repeating values, like this:
    #
    # [:a , :bar, :one]
    # [nil, nil , :two]
    # [nil, :foo, :one]
    #
    def sparse_tuples
      tuples = to_a
      [tuples.first] + each_cons(2).map { |prev, cur|
        left = cur.zip(prev).drop_while { |c, p| c == p }
        [nil] * (cur.size - left.size) + left.map(&:first)
      }
    end
  end

  class CategoricalIndex < Index
    
    include Enumerable
    
    attr_reader :cat_hash, :array, :map_cat_int, :map_int_cat
    
    def initialize indexes
      # Create a hash to map each category to positional indexes
      @cat_hash = Hash.new []
      # To link every instance to its category,
      # it stores integer for every instance representing its category
      @array = []
      # Map each category to a unique integer for effective storage in @array
      map_cat_int = {}
      # Inverse mapping of @map
      @map_int_cat = {}
      
      cat_count = 0
      indexes.each_with_index do |index, pos|
        unless map_cat_int.include? index
          map_cat_int[index] = cat_count
          @map_int_cat[cat_count] = index
          cat_count += 1
        end
        @cat_hash[index] += [pos]
        @array << map_cat_int[index]
      end
    end
    
    def dup
      Daru::CategoricalIndex.new to_a
    end
    
    def include? index
      @cat_hash.include? index
    end
    
    def pos *args
      positions = args.map do |index|
        if include? index
          @cat_hash[index]
        elsif index.is_a?(Numeric) && index < @array.size
          index
        else
          raise IndexError, "#{index.inspect} is neither a valid category"\
            " nor a valid position"
        end
      end
      
      positions.flatten!
      positions.sort! # to preserve the order
      
      return positions.first if positions.size == 1
      return positions
    end
    
    def index_from_pos pos
      @map_int_cat[@array[pos]]
    end
    
    def each
      return enum_for(:each) unless block_given?      
      @array.each { |pos| yield @map_int_cat[pos] }
      self
    end
    
    def == other
      self.class == other.class &&
        self.size == other.size &&
        self.to_h == other.to_h
    end

    def to_a
      each.to_a
    end
    
    def to_h
      @cat_hash
    end
    
    def size
      @array.size
    end
    
    def subset *args
      positions = pos(*args)
      new_index = positions.map do |index|
        index_from_pos index
      end
      
      new_index.flatten!

      Daru::CategoricalIndex.new new_index
    end

    def at *args
      return index_from_pos(args.first) if args.size == 1
      Daru::CategoricalIndex.new args.map { |p| index_from_pos p }
    end
    
    def add *indexes
      Daru::CategoricalIndex.new(to_a + indexes)
    end
  end
end