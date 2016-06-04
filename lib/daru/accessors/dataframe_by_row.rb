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
    end
  end
end
