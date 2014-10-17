module Daru
  class Vector
    include Enumerable

    def each(&block)
      @vector.each(&block)
    end

    attr_reader :name
    attr_reader :index
    attr_reader :size

    def initialize name=SecureRandom.uuid, source=[], index=nil
      @name = name.to_sym

      @vector = 
      case source
      when Array
        source.dup
      when Range, Matrix
        source.to_a.dup
      else # NMatrix or MDArray
        source.dup
      end

      if index.nil?
        @index = Daru::Index.new @vector.size  
      else
        @index = index.to_index
      end

      # TODO: Will need work for NMatrix/MDArray
      if @index.size >= @vector.size
        (@index.size - @vector.size).times { @vector << nil }
      else
        raise IndexError, "Expected index size >= vector size"
      end

      @size = @vector.size
    end

    def [](index)
      if index.is_a?(Numeric)
        
      else
        @vector[@index[index]]
      end
    end

    # Two vectors are equal if the have the exact same index values corresponding
    # with the exact same elements.
    def == other
      # @index == other.index and @size == other.size and
      # self.all? do
      #   self[el]
      # end
      # iterate over each element in this vector and the other vector and compare.
    end
  end
end