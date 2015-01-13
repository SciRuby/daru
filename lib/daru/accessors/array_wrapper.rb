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
        @data.inject(0) do |memo ,e|
          memo += e unless e.nil? #TODO: Remove this conditional somehow!
          memo
        end
      end

     private

      def set_size
        @size = @data.size
      end
    end
  end
end