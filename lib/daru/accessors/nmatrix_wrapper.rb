begin
  require 'nmatrix' unless jruby?
rescue LoadError => e
  puts "Please install the nmatrix gem for fast and efficient data storage."
end

module Daru
  module Accessors
    # Internal class for wrapping NMatrix
    class NMatrixWrapper
      include Enumerable

      def each(&block)
        @data[0...@size].each(&block)
      end

      def map(&block)
        @data[0...@size].map(&block)
      end

      def map!(&block)
        @data = NMatrix.new [@size*2], map(&block).to_a, dtype: nm_dtype
      end

      def inject(*args, &block)
        @data[0...@size].inject(*args, &block)
      end

      alias_method :recode, :map
      alias_method :recode!, :map!

      attr_reader :size, :data, :nm_dtype
      
      def initialize vector, context, nm_dtype=:int32
        @size = vector.size
        @data = NMatrix.new [@size*2], vector.to_a, dtype: nm_dtype
        @context = context
        @nm_dtype = @data.dtype
        # init with twice the storage for reducing the need to resize
      end

      def [] index
        return @data[index] if index < @size
        nil
      end
 
      def []= index, value
        resize     if index >= @data.size
        @size += 1 if index == @size
        
        @data = @data.cast(dtype: :object) if value.nil?
        @data[index] = value
      end 
 
      def == other
        @data == other and @size == other.size
      end
 
      def delete_at index
        arry = @data.to_a
        arry.delete_at index
        @data = NMatrix.new [(2*@size-1)], arry, dtype: @nm_dtype
        @size -= 1
      end
 
      def index key
        @data.to_a.index key
      end
 
      def << element
        resize if @size >= @data.size
        self[@size] = element

        @size += 1
      end
 
      def to_a
        @data[0...@size].to_a
      end
 
      def dup
        NMatrixWrapper.new @data.to_a, @context, @nm_dtype
      end

      def resize size = @size*2
        raise ArgumentError, "Size must be greater than current size" if size < @size

        @data = NMatrix.new [size], @data.to_a
      end

      def mean
        @data[0...@size].mean.first
      end

      def product
        @data[0...@size].inject(1) { |m,e| m*e }
      end

      def sum
        @data[0...@size].inject(:+)
      end

      def max
        @data.max
      end

      def min
        @data.min
      end
    end
  end
end