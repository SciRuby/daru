module Daru
  module Accessors
    class DataFrameByRow
      def initialize data_frame
        @data_frame = data_frame
      end

      def [](*names)
        @data_frame[*names, :row]
      end

      def []=(*names, vector)
        @data_frame[*names, :row] = vector
      end

      def at *positions
        @data_frame.at(*positions)
      end

      def at_set *positions
        @data_frame.row_at_set(*positions)
      end
    end
  end
end
