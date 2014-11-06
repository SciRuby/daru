require_relative 'math/arithmetic/vector.rb'
require_relative 'math/statistics/vector.rb'
require_relative 'accessors/array_wrapper.rb'
require_relative 'accessors/nmatrix_wrapper.rb'

module Daru
  class Vector
    include Daru::Math::Arithmetic::Vector
    include Daru::Math::Statistics::Vector
    include Enumerable

    def each(&block)
      @vector.each(&block)
    end

    attr_reader :name
    attr_reader :index
    attr_reader :size
    attr_reader :stype

    # Pass it name, source and index
    def initialize source, opts={}
      source = source || []
      name   = opts[:name]
      index  = opts[:index]
      @stype = opts[:stype] || Array

      set_name name

      @vector = 
      case
      when @stype == Array
        Daru::Accessors::ArrayWrapper.new source.dup
      when @stype == NMatrix
        Daru::Accessors::NMatrixWrapper.new source.dup
      when @stype == MDArray
        Daru::Accessors::MDArrayWrapper.new source.dup
      when @stype == Range, Matrix
        Daru::Accessors::ArrayWrapper.new source.to_a.dup
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

    # Get one or more elements with specified index.
    # 
    # == Usage
    #   v[:one, :two] # => Daru::Vector with indexes :one and :two
    #   v[:one]       # => Single element
    def [](index, *indexes)
      if indexes.empty?
        if @index.include? index
          @vector[@index[index]]
        elsif index.is_a?(Numeric)
          @vector[index]
        else
          return nil
        end
      else
        indexes.unshift index

        Daru::Vector.new indexes.map { |index| @vector[@index[index]] },name: @name, 
          index: indexes
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

    def push element
      concat element  
    end

    # Append an element to the vector by specifying the element and index
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

      @vector[@index[index]] = element

      set_size
    end

    def stype= stype
      @stype  = stype
      @vector = @vector.coerce stype
    end

    # Delete an element by value
    def delete element
      self.delete_at index_of(element)      
    end

    # Delete element by index
    def delete_at index
      idx = named_index_for index

      @vector.delete_at @index[idx]

      if @index.index_class == Integer
        @index = Daru::Index.new @size-1
      else
        @index = (@index.to_a - [idx]).to_index
      end

      set_size
    end

    # Get index of element
    def index_of element
      @index.key @vector.index(element)
    end

    # Convert to hash. Hash keys are indexes and values are the correspoding elements
    def to_hash
      @index.inject({}) do |hsh, index|
        hsh[index] = self[index]
        hsh
      end
    end

    # Return an array
    def to_a
      @vector.to_a
    end

    # Convert the hash from to_hash to json
    def to_json *args 
      self.to_hash.to_json
    end

    # Convert to html for iruby
    def to_html threshold=30
      name = @name || 'nil'

      html = '<table>' + '<tr><th> </th><th>' + name.to_s + '</th></tr>'

      @index.each_with_index do |index, num|
        html += '<tr><td>' + index.to_s + '</td>' + '<td>' + self[index].to_s + '</td></tr>'
    
        if num > threshold
          html += '<tr><td>...</td><td>...</td></tr>'
          break
        end
      end

      html += '</table>'

      html
    end

    def to_s
      to_html
    end

    # Over rides original inspect for pretty printing in irb
    def inspect spacing=10, threshold=15
      longest = [@name.to_s.size,
                 @index.to_a.map(&:to_s).map(&:size).max, 
                 @vector    .map(&:to_s).map(&:size).max].max

      content   = ""
      longest   = spacing if longest > spacing
      name      = @name || 'nil'
      formatter = "\n%#{longest}.#{longest}s %#{longest}.#{longest}s"

      content += "\n#<" + self.class.to_s + ":" + self.object_id.to_s + " @name = " + name.to_s + " @size = " + size.to_s + " >"

      content += sprintf formatter, "", name
      @index.each_with_index do |index, num|
        content += sprintf formatter, index.to_s, (self[index] || 'nil').to_s

        if num > threshold
          content += sprintf formatter, '...', '...'
          break
        end
      end

      content += "\n"

      content
    end

    def compact!
      # TODO: Compact and also take care of indexes
      # @vector.compact!
      # set_size
    end

    # Give the vector a new name
    def rename new_name
      @name = new_name.to_sym
    end

    # Duplicate elements and indexes
    def dup 
      Daru::Vector.new @vector.dup, name: @name, index: @index.dup
    end

    def daru_vector *name
      self
    end

    alias_method :dv, :daru_vector

   private

    def named_index_for index
      if @index.include? index
        index
      elsif @index.key index
        @index.key index
      else
        raise IndexError, "Specified index #{index} does not exist."
      end
    end

    def set_size
      @size = @vector.size
    end

    def set_name name
      if name.is_a?(Numeric)
        @name = name 
      elsif name # anything but Numeric or nil
        @name = name.to_sym
      else
        @name = nil
      end
    end
  end
end