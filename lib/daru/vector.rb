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
      @name = name.to_sym unless name.nil?

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

    def [](index, *indexes)
      if indexes.empty?
        if @index.index_class != Integer and index.is_a?(Integer)
          @vector[index]
        else
          @vector[@index[index]]
        end
      else
        indexes.unshift index

        Daru::Vector.new @name, indexes.map { |index| @vector[@index[index]] }, indexes
      end
    end

    # Two vectors are equal if the have the exact same index values corresponding
    # with the exact same elements.
    def == other
      @index == other.index and @size == other.size and
      @index.all? do |index|
        self[index] == other[index]
      end
    end

    def rename new_name
      @name = new_name.to_sym
    end

    def dup 
      Daru::Vector.new @name, @vector.dup, @index.dup
    end

    def daru_vector *name
      self
    end

    alias_method :dv, :daru_vector
  end
end