module Daru
  module Accessors

    # Internal class for wrapping NMatrix
    class NMatrixWrapper
      module Statistics
        # TODO
      end # module Statistics

      attr_reader :size, :vector

      def initialize vector
        
      end

      def [] index

      end
 
      def []= index, value

      end
 
      def == other

      end
 
      def delete_at index

      end
 
      def index key

      end
 
      def << element

      end
 
      def to_a
        @vector.to_a
      end
 
      def dup
        NMatrixWrapper.new @vector.dup
      end
 
     private
 
      def set_size
        @size = @vector.size
      end 
    end
  end
end