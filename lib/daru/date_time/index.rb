module Daru
  class DateTimeIndex < Index
    # Have a hash that contains the time difference for frequencies.
    # Supported frequencies: Second, Minute, Hour, Day, Month, Year
    # 
    # To create a hash I need to calculate the difference between 
    # two secs, mins, etc. This number will be the value for the
    # corresponding key denoting the frequency in verbose.
    FREQUENCY = {
      :Y => 31536000,
      :M => ,
      :D => ,
      :H => ,
      :Min => ,
      :S  =>
    }

    def initialize data, opts={}
      try_convert_to_ruby_time data

      if periodic? data
        set_frequency
        set_start_and_end
      else
        opts[:clone] ||= true
        @frequency = nil
        @data      = opts[:clone] ? data.dup : data
      end
    end

    def try_convert_to_ruby_time data
      data.map! do |e|
        e.is_a?(String) ? Time.parse(e) : e
      end
    end

    def periodic? data
      return false unless data[1]

      possible_freq = data[1].to_i - data[0].to_i
      data.each_cons(2) do |d|
        return false if (d[1].to_i - d[0].to_i) != possible_freq 
      end

      return true
    end

    def set_frequency
      
    end

    def set_start_and_end
      
    end

    private :try_convert_to_ruby_time, :periodic?, :set_frequency, 
      :set_start_and_end

    def self.date_range opts={}

    end
  end
end