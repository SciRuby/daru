module Daru
  module Accessors
    # Internal class for wrapping ruby array
    class ArrayWrapper
      include Enumerable

      def each(&block)
        @data.each(&block)
      end

      def map!(&block)
        @data.map!(&block)
      end

      attr_accessor :size
      attr_reader   :data
      attr_reader   :has_missing_data

      def initialize vector, context
        @data = vector.to_a
        @context = context

        set_size
      end

      def [] index
        @data[index]
      end

      def []= index, value
        has_missing_data = true if value.nil?
        @data[index] = value
        set_size
      end

      def == other
        @data == other
      end

      def delete_at index
        @data.delete_at index
        set_size
      end

      def index key
        @data.index key
      end

      def << element
        @data << element
        set_size
      end

      def uniq
        @data.uniq
      end

      def to_a
        @data
      end

      def dup
        ArrayWrapper.new @data.dup, @context
      end

      def has_missing_data?
        has_missing_data
      end

      def mean
        sum.quo(@size).to_f
      end

      def product
        @data.inject(:*)
      end

      def max
        @data.max
      end

      def min
        @data.min
      end

      def sum
        @data.inject(:+)
      end

     private

      def set_size
        @size = @data.size
      end
    end
  end
end