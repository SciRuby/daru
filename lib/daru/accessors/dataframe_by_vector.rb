module Daru
  module Accessors
    class DataFrameByVector
      def initialize data_frame
        @data_frame = data_frame
      end

      def [](*names)
        @data_frame[*names, :vector]
      end

      def []=(*names, vector)
        @data_frame[*names, :vector] = vector
      end

      def at *positions
        @data_frame.vector_at(*positions)
      end
    end
  end
end
