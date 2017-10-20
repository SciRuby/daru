module Daru
  module IndexSharedBehavior
    # TODO: optimize
    def keys_at(*positions)
      positions.map(&method(:key))
    end

    # Produce new index from the set union of two indexes.
    #
    # @param other [Daru::Index]
    # @return [Daru::Index]
    def |(other)
      recreate(to_a | other.to_a)
    end

    # Produce a new index from the set intersection of two indexes
    #
    # @param other [Daru::Index]
    # @return [Daru::Index]
    def &(other)
      recreate(to_a & other.to_a)
    end

    # Returns subset of self by numeric positions, or single value
    #
    # @param positions [Array<Integer>] positional values
    # @return [Index, Object] If single position passed, returns index value at that position,
    #   subset Index otherwise
    #
    # @example
    #   idx = Daru::Index.new %i[a b c d]
    #   idx.at 0
    #   # => :a
    #   idx.at 0, 1
    #   # => #<Daru::Index(2): {a, b}>
    #   idx.at 1..-1
    #   # => #<Daru::Index(3): {b, c, d}>
    #
    def at(*positions)
      positions = preprocess_positions(positions).tap(&method(:validate_positions))
      positions.is_a?(Integer) ? key(positions) : recreate(keys_at(*positions))
    end

    # Changes order of index labels according to new positions provided
    #
    # @example
    #   i = Daru::Index.new 2014..2017
    #   # => #<Daru::Index(4): {2014, 2015, 2016, 2017}>
    #   i.reorder([2, 3, 0, 1]) # value with index 2 becomes first, value with index 3 -- second, and so on
    #   # => #<Daru::Index(4): {2016, 2017, 2014, 2015}>
    #
    # @param positions [Array<Integer>]
    # @return [Index]
    def reorder(positions)
      recreate(keys_at(*positions), name: name)
    end

    private

    # Preprocess ranges, integers and array in appropriate ways
    def preprocess_positions(positions)
      return positions unless positions.size == 1

      case (position = positions.first)
      when Integer
        position
      when TypeCheck[Range, of: Integer]
        size.times.to_a[position] # Converts ranges, including 1..-1-alike ones, to list of valid positions
      else
        fail IndexError, "Undefined position: #{position}"
      end
    end

    # Raises IndexError when one of the positions is an invalid position
    def validate_positions(positions)
      min_invalid = Array(positions).detect { |pos| pos >= size || pos < 0 }

      raise IndexError, "Invalid index position: #{min_invalid}" if min_invalid
    end

    def recreate(*args)
      self.class.new(*args)
    end
  end
end
