if Daru.has_nmatrix?
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

        # :nocov:
        # FIXME: not sure, why this kind of wrapper have such a pure coverage
        def inject(*args, &block)
          @data[0...@size].inject(*args, &block)
        end
        # :nocov:

        attr_reader :size, :data, :nm_dtype

        def initialize vector, context, nm_dtype=:int32
          # To avoid arrays with nils throwing TypeError for nil nm_dtype
          nm_dtype = :object if nm_dtype.nil? && vector.any?(&:nil?)
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

        # :nocov:
        def == other
          @data[0...@size] == other[0...@size] and @size == other.size
        end
        # :nocov:

        def delete_at index
          arry = @data.to_a
          arry.delete_at index
          @data = NMatrix.new [(2*@size-1)], arry, dtype: @nm_dtype
          @size -= 1
        end

        def index key
          @data.to_a.index key
        end

        # :nocov:
        def << element
          resize if @size >= @data.size
          self[@size] = element
        end
        # :nocov:

        def to_a
          @data[0...@size].to_a
        end

        def dup
          NMatrixWrapper.new @data[0...@size].to_a, @context, @nm_dtype
        end

        def resize size=@size*2
          raise ArgumentError, 'Size must be greater than current size' if size < @size

          @data = NMatrix.new [size], @data.to_a, dtype: @nm_dtype
        end

        # :nocov:
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
        # :nocov:
      end
    end
  end
end
