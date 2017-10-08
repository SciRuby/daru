module Daru
  class CategoricalIndex < Index
    # Create a categorical index object.
    # @param indexes [Array<object>] array of indexes
    # @return [Daru::CategoricalIndex] categorical index
    # @example
    #   Daru::CategoricalIndex.new [:a, 1, :a, 1, :c]
    #   # => #<Daru::CategoricalIndex(5): {a, 1, a, 1, c}>
    def initialize indexes
      # Create a hash to map each category to positional indexes
      categories = indexes.each_with_index.group_by(&:first)
      @cat_hash = categories.map { |cat, group| [cat, group.map(&:last)] }.to_h

      # Map each category to a unique integer for effective storage in @array
      map_cat_int = categories.keys.each_with_index.to_h

      # To link every instance to its category,
      # it stores integer for every instance representing its category
      @array = map_cat_int.values_at(*indexes)
    end

    # Duplicates the index object and return it
    # @return [Daru::CategoricalIndex] duplicated index object
    def dup
      # Improve it by intializing index by hash
      Daru::CategoricalIndex.new to_a
    end

    # Returns true index or category is valid
    # @param index [object] the index value to look for
    # @return [true, false] true if index is included, false otherwise
    def include? index
      @cat_hash.include? index
    end

    # Returns array of categories
    # @example
    #   x = Daru::CategoricalIndex.new [:a, 1, :a, 1, :c]
    #   x.categories
    #   # => [:a, 1, :c]
    def categories
      @cat_hash.keys
    end

    # Returns positions given categories or positions
    # @note If the argument does not a valid category it treats it as position
    #   value and return it as it is.
    # @param indexes [Array<object>] categories or positions
    # @example
    #   x = Daru::CategoricalIndex.new [:a, 1, :a, 1, :c]
    #   x.pos :a, 1
    #   # => [0, 1, 2, 3]
    def pos *indexes
      positions = indexes.map do |index|
        if include? index
          @cat_hash[index]
        elsif index.is_a?(Numeric) && index < @array.size
          index
        else
          raise IndexError, "#{index.inspect} is neither a valid category"\
            ' nor a valid position'
        end
      end

      positions.flatten!
      positions.size == 1 ? positions.first : positions.sort
    end

    # Returns index value from position
    # @param pos [Integer] the position to look for
    # @return [object] category corresponding to position
    # @example
    #   idx = Daru::CategoricalIndex.new [:a, :b, :a, :b, :c]
    #   idx.index_from_pos 1
    #   # => :b
    def index_from_pos pos
      cat_from_int @array[pos]
    end

    # Returns enumerator enumerating all index values in the order they occur
    # @return [Enumerator] all index values
    # @example
    #   idx = Daru::CategoricalIndex.new [:a, :a, :b]
    #   idx.each.to_a
    #   # => [:a, :a, :b]
    def each
      return enum_for(:each) unless block_given?
      @array.each { |pos| yield cat_from_int pos }
      self
    end

    # Compares two index object. Returns true if every instance of category
    # occur at the same position
    # @param [Daru::CateogricalIndex] other index object to be checked against
    # @return [true, false] true if other is similar to self
    # @example
    #   a = Daru::CategoricalIndex.new [:a, :a, :b]
    #   b = Daru::CategoricalIndex.new [:b, :a, :a]
    #   a == b
    #   # => false
    def == other
      self.class == other.class &&
        size == other.size &&
        to_h == other.to_h
    end

    # Returns all the index values
    # @return [Array] all index values
    # @example
    #   idx = Daru::CategoricalIndex.new [:a, :b, :a]
    #   idx.to_a
    def to_a
      each.to_a
    end

    # Returns hash table mapping category to positions at which they occur
    # @return [Hash] hash table mapping category to array of positions
    # @example
    #   idx = Daru::CategoricalIndex.new [:a, :b, :a]
    #   idx.to_h
    #   # => {:a=>[0, 2], :b=>[1]}
    def to_h
      @cat_hash
    end

    # Returns size of the index object
    # @return [Integer] total number of instances of all categories
    # @example
    #   idx = Daru::CategoricalIndex.new [:a, :b, :a]
    #   idx.size
    #   # => 3
    def size
      @array.size
    end

    # Returns true if index object is storing no category
    # @return [true, false] true if index object is empty
    # @example
    #   i = Daru::CategoricalIndex.new []
    #   # => #<Daru::CategoricalIndex(0): {}>
    #   i.empty?
    #   # => true
    def empty?
      @array.empty?
    end

    # Return subset given categories or positions
    # @param indexes [Array<object>] categories or positions
    # @return [Daru::CategoricalIndex] subset of the self containing the
    #   mentioned categories or positions
    # @example
    #   idx = Daru::CategoricalIndex.new [:a, :b, :a, :b, :c]
    #   idx.subset :a, :b
    #   # => #<Daru::CategoricalIndex(4): {a, b, a, b}>
    def subset *indexes
      positions = pos(*indexes)
      new_index = positions.map { |pos| index_from_pos pos }

      Daru::CategoricalIndex.new new_index.flatten
    end

    # Takes positional values and returns subset of the self
    #   capturing the categories at mentioned positions
    # @param positions [Array<Integer>] positional values
    # @return [object] index object
    # @example
    #   idx = Daru::CategoricalIndex.new [:a, :b, :a, :b, :c]
    #   idx.at 0, 1
    #   # => #<Daru::CategoricalIndex(2): {a, b}>
    def at *positions
      positions = preprocess_positions(*positions)
      validate_positions(*positions)
      if positions.is_a? Integer
        index_from_pos(positions)
      else
        Daru::CategoricalIndex.new positions.map(&method(:index_from_pos))
      end
    end

    # Add specified index values to the index object
    # @param indexes [Array<object>] index values to add
    # @return [Daru::CategoricalIndex] index object with added values
    # @example
    #   idx = Daru::CategoricalIndex.new [:a, :b, :a, :b, :c]
    #   idx.add :d
    #   # => #<Daru::CategoricalIndex(6): {a, b, a, b, c, d}>
    def add *indexes
      Daru::CategoricalIndex.new(to_a + indexes)
    end

    private

    def int_from_cat cat
      @cat_hash.keys.index cat
    end

    def cat_from_int cat
      @cat_hash.keys[cat]
    end
  end
end
