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
        #Not sure why you can't just use map! on a NMatrix slice?
        @data = NMatrix.new [@size*2], map(&block).to_a, dtype: nm_dtype
        self
      end

      def inject(*args, &block)
        @data[0...@size].inject(*args, &block)
      end

      attr_reader :size, :data, :nm_dtype
      
      def initialize vector, context, nm_dtype=:int32
        #Check that vector is correct shape and type.
        #
        #It would be really nice if this worked with nx1 matrices, since
        #that's what NVector produces. I think this would just require a call
        #to reshape. Right now it only works with 1xn
        #matrices and flat 1D NMatrix's.
        @size = vector.size
        #It's too bad NMatrix doesn't have resize method.
        @data = NMatrix.new [@size*2], vector.to_a, dtype: nm_dtype
        @context = context
        @nm_dtype = @data.dtype
        # init with twice the storage for reducing the need to resize
      end

      #Shouldn't this take just a single integer argument?
      def [] *index
        return @data[*index] if index[0] < @size
        nil
      end
 
      def []= index, value
        #Do you want to allow the case where index > @size? It doesn't seem like
        #this is handled properly?

        #what if index > @size*2?
        resize     if index >= @data.size
        @size += 1 if index == @size
        
        @data = @data.cast(dtype: :object) if value.nil?
        @data[index] = value
      end 
 
      def == other
        #depending on the purpose of this method, maybe you only need to check
        #if the first @size elements are the same.
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

        #@size is already incremented in #[]=
        @size += 1
      end
 
      def to_a
        @data[0...@size].to_a
      end
 
      def dup
        NMatrixWrapper.new @data[0...@size].to_a, @context, @nm_dtype
      end

      def resize size = @size*2
        raise ArgumentError, "Size must be greater than current size" if size < @size

        #include dtype argument?
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
        #Not using a slice here will get you in trouble if you use #delete_at.
        #Also, I think it might be faster to use a slice.
        @data.max
      end

      def min
        @data.min
      end
    end
  end
end if Daru.has_nmatrix?
