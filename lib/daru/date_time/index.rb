module Daru
  class DateTimeIndex < Index

    def initialize data, opts={}
      try_convert_to_ruby_date_time data

      if periodic? data
        set_frequency
        set_start_and_end
      else
        opts[:clone] ||= true
        @frequency = nil
        @data      = opts[:clone] ? data.dup : data
      end
    end

    def try_convert_to_ruby_date_time data
      data.map! do |e|
        e.is_a?(String) ? DateTime.parse(e) : e
      end
    end

    def periodic? data
      return false unless data[1]

      possible_freq = data[1] - data[0]
      data.each_cons(2) do |d|
        return false if (d[1].to_i - d[0].to_i) != possible_freq 
      end

      return true
    end

    def set_frequency
      @frequency = data[1] ? (data[1] - data[0]) : nil
    end

    def set_start_and_end
      
    end

    private :try_convert_to_ruby_date_time, :periodic?, :set_frequency, 
      :set_start_and_end

    def self.date_range opts={}

    end

    def [] key
      if key.is_a?(Range)
        first = key.first
        last = key.last

        # parse out the time information from first and last variables.
        if @frequency
          # calculate slice based on start, end, period and frequency
        else
          # go through each element to determine the slice
        end
      else

      end  
    end

  end
end