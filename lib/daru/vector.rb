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
        elsif index.is_a?(Numeric)
          @vector[index]
        else
          raise IndexError, "Specified index #{index} does not exist."
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
      self.delete_at index_of(element)      
    end

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

    def index_of element
      @index.key @vector.index(element) #calling Array#index
    end

    def to_hash
      @index.inject({}) do |hsh, index|
        hsh[index] = self[index]
        hsh
      end
    end

    def to_json *args 
      self.to_hash.to_json
    end

    def to_html threshold=15
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

    def inspect spacing=10, threshold=15
      longest = [@index.to_a.map(&:to_s).map(&:size).max, 
                 @vector    .map(&:to_s).map(&:size).max].max

      content   = ""
      longest   = spacing if longest > spacing
      name      = @name || 'nil'
      formatter = "\n%#{longest}.#{longest}s %#{longest}.#{longest}s"

      content += "\n#<" + self.class.to_s + ":" + self.object_id.to_s + " @name = " + name.to_s + " @size = " + size.to_s + " >"

      content += sprintf formatter, "", name
      @index.each_with_index do |index, num|
        content += sprintf formatter, index.to_s, self[index]

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