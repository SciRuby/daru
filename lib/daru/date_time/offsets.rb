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
      def initialize n=1
        @n = n
      end

      def + date_time
        date_time + @n*multiplier
      end
    end

    # Class for creating a seconds offset
    class Second < Tick
      def multiplier
        1.1574074074074073e-05
      end

      def freq_string
        'S'
      end
    end

    class Minute < Tick
      def multiplier
        0.0006944444444444445
      end

      def freq_string
        'M'
      end
    end

    class Hour < Tick
      def multiplier
        0.041666666666666664
      end
      
      def freq_string
        'H'
      end
    end

    class Day < Tick
      def multiplier
        1.0
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