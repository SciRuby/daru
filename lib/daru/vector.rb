module Daru
  class Vector
    include Enumerable

    def each(&block)
      @vector.each(&block)
    end

    attr_reader :name
    attr_reader :index
    attr_reader :size

    # Pass it name, source and index
    def initialize *args
      name   = args.shift
      source = args.shift || []
      index  = args.shift

      set_name name

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

      set_size
    end

    def [](index, *indexes)
      if indexes.empty?
        if @index.include? index
          @vector[@index[index]]
        else
          @vector[index]
        end
      else
        indexes.unshift index

        Daru::Vector.new @name, indexes.map { |index| @vector[@index[index]] }, indexes
      end
    end

    def []=(index, value)
      if @index.include? index
        @vector[@index[index]] = value
      else
        @vector[index] = value
      end

      set_size
    end

    # Two vectors are equal if the have the exact same index values corresponding
    # with the exact same elements. Name is ignored.
    def == other
      @index == other.index and @size == other.size and
      @index.all? do |index|
        self[index] == other[index]
      end
    end

    def << element
      concat element
    end

    def concat element, index=nil
      raise IndexError, "Expected new unique index" if @index.include? index

      if index.nil? and @index.index_class == Integer
        @index = Daru::Index.new @size+1
        index  = @size
      else
        begin
          @index = @index.re_index(@index + index)
        rescue Exception => e
          raise e, "Expected valid index."
        end
      end

      @size += 1

      @vector[@index[index]] = element
    end

    def delete element
      
    end

    def delete_at index
      
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

   private

    def set_size
      @size = @vector.size
    end

    def set_name name
      if name.is_a?(Numeric)
        @name = name 
      elsif name
        @name = name.to_sym
      end
    end
  end
end