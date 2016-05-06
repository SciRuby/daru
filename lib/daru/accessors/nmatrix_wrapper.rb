module Daru
  module Accessors
    # Internal class for wrapping NMatrix
    class NMatrixWrapper
      include Enumerable

      def each(&block)
        @data[0...@size].each(&block)
        self
      end

      def map!(&block)
        @data = NMatrix.new [@size*2], map(&block).to_a, dtype: nm_dtype
        self
      end

      def inject(*args, &block)
        @data[0...@size].inject(*args, &block)
      end

      attr_reader :size, :data, :nm_dtype

      def initialize vector, context, nm_dtype=:int32
        @size = vector.size
        @data = NMatrix.new [@size*2], vector.to_a, dtype: nm_dtype
        @context = context
        @nm_dtype = @data.dtype
        # init with twice the storage for reducing the need to resize
      end

      def [] *index
        return @data[*index] if index[0] < @size
        nil
      end

      def []= index, value
        raise ArgumentError, "Index #{index} does not exist" if
          index > @size && index < @data.size
        resize     if index >= @data.size
        @size += 1 if index == @size

        @data = @data.cast(dtype: :object) if value.nil?
        @data[index] = value
      end

      def == other
        @data[0...@size] == other[0...@size] and @size == other.size
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
      end

      def to_a
        @data[0...@size].to_a
      end

      def dup
        NMatrixWrapper.new @data[0...@size].to_a, @context, @nm_dtype
      end

      def resize size = @size*2
        raise ArgumentError, 'Size must be greater than current size' if size < @size

        @data = NMatrix.new [size], @data.to_a, dtype: @nm_dtype
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
        @data[0...@size].max
      end

      def min
        @data[0...@size].min
      end
    end
  end
end if Daru.has_nmatrix?
