module Daru
  module Accessors
    # Internal class for wrapping ruby array
    class ArrayWrapper
      module Statistics

      end

      include Statistics
      include Enumerable

      def each(&block)
        @vector.each(&block)
      end

      attr_accessor :size
      attr_reader   :vector

      def initialize vector
        @vector = vector

        set_size
      end

      def [] index
        @vector[index]
      end

      def []= index, value
        @vector[index] = value
        set_size
      end

      def == other
        @vector == other
      end

      def delete_at index
        @vector.delete_at index
        set_size
      end

      def index key
        @vector.index key
      end

      def << element
        @vector << element
        set_size
      end

      def to_a
        @vector
      end

      def dup
        ArrayWrapper.new @vector.dup
      end

     private

      def set_size
        @size = @vector.size
      end
    end
  end
end