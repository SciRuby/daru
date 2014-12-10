$:.unshift File.dirname(__FILE__)

require 'maths/arithmetic/vector.rb'
require 'maths/statistics/vector.rb'
require 'plotting/vector.rb'
require 'accessors/array_wrapper.rb'
require 'accessors/nmatrix_wrapper.rb'

module Daru
  class Vector
    include Enumerable
    include Daru::Maths::Arithmetic::Vector
    include Daru::Maths::Statistics::Vector
    include Daru::Plotting::Vector

    def each(&block)
      @vector.each(&block)
    end

    def map!(&block)
      @vector.map!(&block)

      self
    end

    def map(&block)
      Daru::Vector.new @vector.map(&block), name: @name, index: @index, dtype: @dtype
    end

    alias_method :recode, :map

    attr_reader :name
    attr_reader :index
    attr_reader :size
    attr_reader :dtype

    # Create a Vector object.
    # == Arguments
    # 
    # @param source[Array,Hash] - Supply elements in the form of an Array or a Hash. If Array, a
    #   numeric index will be created if not supplied in the options. Specifying more
    #   index elements than actual values in *source* will insert *nil* into the 
    #   surplus index elements. When a Hash is specified, the keys of the Hash are 
    #   taken as the index elements and the corresponding values as the values that
    #   populate the vector.
    # 
    # == Options
    # 
    # * +:name+  - Name of the vector
    # 
    # * +:index+ - Index of the vector
    # 
    # * +:dtype+ - The underlying data type. Can be :array or :nmatrix. Default :array.
    # 
    # * +:ntype+ - For NMatrix, the data type of the numbers. See the NMatrix docs for
    #   further information on supported data type.
    # 
    # == Usage
    # 
    #   vecarr = Daru::Vector.new [1,2,3,4], index: [:a, :e, :i, :o]
    #   vechsh = Daru::Vector.new({a: 1, e: 2, i: 3, o: 4})
    def initialize source, opts={}
      index = nil
      if source.is_a?(Hash)
        index  = source.keys
        source = source.values
      else
        index  = opts[:index]
        source = source || []
      end
      name   = opts[:name]
      set_name name

      @vector = cast_vector_to(opts[:dtype], source, opts[:ntype])

      if index.nil?
        @index = Daru::Index.new @vector.size  
      else
        @index = Daru::Index.new index
      end
      # TODO: Will need work for NMatrix/MDArray
      if @index.size > @vector.size
        cast(dtype: :array) # NM with nils seg faults
        (@index.size - @vector.size).times { @vector << nil }
      elsif @index.size < @vector.size
        puts "i : #{@index.to_a} v : #{@vector.class}"
        raise IndexError, "Expected index size >= vector size. Index size : #{@index.size}, vector size : #{@vector.size}"
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
        case index
        when Range
          # range into vector
          # 
        else
          if @index.include? index
            @vector[@index[index]]
          elsif index.is_a?(Numeric)
            @vector[index]
          else
            return nil
          end
        end
      else
        indexes.unshift index

        Daru::Vector.new indexes.map { |index| @vector[@index[index]] },name: @name, 
          index: indexes
      end
    end

    def []=(index, value)
      cast(dtype: :array) if value.nil?

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
      case other
      when Daru::Vector
        @index == other.index and @size == other.size and
        @index.all? do |index|
          self[index] == other[index]
        end
      else
        # TODO: Compare against some other obj (string, number, etc.)
      end
    end

    def << element
      concat element
    end

    def push element
      concat element  
    end

    def re_index new_index
      
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

    def cast opts={}
      dtype = opts[:dtype]
      raise ArgumentError, "Unsupported dtype #{opts[:dtype]}" unless 
        dtype == :array or dtype == :nmatrix

      @vector = cast_vector_to dtype
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

    # Keep only unique elements of the vector alongwith their indexes.
    def uniq
      uniq_vector = @vector.uniq
      new_index   = uniq_vector.inject([]) do |acc, element|  
        acc << index_of(element) 
        acc
      end

      Daru::Vector.new uniq_vector, name: @name, index: new_index, dtype: @dtype
    end

    # Sorts a vector according to its values.
    # 
    # == Options
    # 
    # * ascending - if false, will sort in descending order. Defaults to true.
    def sort opts={}, &block
      opts = {
        ascending: true,
        type: :quick_sort
      }.merge(opts)

      if opts[:ascending]
        send opts[:type], :ascending
      else
        send opts[:type], :descending
      end
    end

    # Returns *true* if the value passed actually exists in the vector.
    def exists? value
      !self[index_of(value)].nil?
    end

    # Returns *true* if an index exists
    def has_index? index
      @index.include? index
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
                 @vector    .map(&:to_s).map(&:size).max,
                 'nil'.size].max

      content   = ""
      longest   = spacing if longest > spacing
      name      = @name || 'nil'
      formatter = "\n%#{longest}.#{longest}s %#{longest}.#{longest}s"
      content  += "\n#<" + self.class.to_s + ":" + self.object_id.to_s + " @name = " + name.to_s + " @size = " + size.to_s + " >"

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

    # def compact!
      # TODO: Compact and also take care of indexes
      # @vector.compact!
      # set_size
    # end

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

    def method_missing(name, *args, &block)
      if name.match(/(.+)\=/)
        self[name] = args[0]
      elsif has_index?(name)
        self[name]
      else
        super(name, *args, &block)
      end
    end

   private

    # Note: To maintain sanity, this _MUST_ be the _ONLY_ place in daru where the
    #   @dtype variable is set and the underlying data type of vector changed.
    def cast_vector_to dtype, source=nil, ntype=nil
      source = @vector if source.nil?

      new_vector = 
      case dtype
      when :array   then Daru::Accessors::ArrayWrapper.new(source.to_a.dup, self)
      when :nmatrix then Daru::Accessors::NMatrixWrapper.new(source.dup, 
        self, ntype)
      when :mdarray then raise NotImplementedError, "MDArray not yet supported."
      else Daru::Accessors::ArrayWrapper.new(source.to_a.dup, self)
      end

      @dtype = dtype || :array
      new_vector
    end

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