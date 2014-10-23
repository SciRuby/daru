module Daru
  class DataFrameByRow
    def initialize data_frame
      @data_frame = data_frame
    end

    def [](*names)
      @data_frame[names, :row]
    end

    def []=(name, vector)
      @data_frame[name, :row] = vector
    end
  end
end