module Daru
  # Generic class for generating data offsets.
  class DateOffset
    def initialize opts={}
      
    end

    def + other
      
    end
  end

  module Offsets
    class Tick < DateOffset
      def initialize n
        @n = n
      end

      def + date_time
        date_time + @n*@multiplier
      end
    end

    # Class for creating a seconds offset
    class Second < Tick
      def initialize n=1
        @multiplier = 1.0/(24*60*60)
        super(n)
      end

      def freq_string
        'S'
      end
    end

    class Minute < Tick
      def initialize n=1
        @multiplier = 1.0/(24*60)
        super(n)  
      end

      def freq_string
        'M'
      end
    end

    class Hour < Tick
      def initialize n=1
        @multiplier = 1.0/(24)
        super(n)  
      end
      
      def freq_string
        'H'
      end
    end

    class Day < Tick
      def initialize n=1
        @multiplier = 1.0
        super(n)        
      end

      def freq_string
        'D'
      end
    end

    class Week < DateOffset
      def freq_string
        'W' + @weekday
      end
    end

    class MonthBegin < DateOffset
      def freq_string
        'MB'
      end
    end

    class MonthEnd < DateOffset
      def freq_string
        'ME'
      end
    end

    class YearBegin < DateOffset
      def freq_string
        'YB'
      end
    end

    class YearEnd < DateOffset
      def freq_string
        'YE'
      end
    end
  end
end