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
        @data_frame.row_at(*positions)
      end

      def set_at positions, vector
        @data_frame.set_row_at(positions, vector)
      end
    end
  end
end
