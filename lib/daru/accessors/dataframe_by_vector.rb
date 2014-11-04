module Daru
  class DataFrameByVector
    def initialize data_frame
      @data_frame = data_frame
    end

    def [](*names)
      @data_frame[*names, :vector]
    end

    def []=(name, vectors)
      @data_frame[name, :vector] = vectors
    end
  end
end