module Daru
  # Generic class for generating data offsets.
  class DateOffset
    def initialize opts={}
      n = opts[:n] || 1

      @offset =
      case 
      when opts[:secs]
        Offsets::Second.new(n*opts[:secs])
      when opts[:mins]
        Offsets::Minute.new(n*opts[:mins])
      when opts[:hours]
        Offsets::Hour.new(n*opts[:hours])
      when opts[:days]
        Offsets::Day.new(n*opts[:days])
      when opts[:weeks]
        Offsets::Day.new(7*n*opts[:weeks])
      when opts[:months]
        Offsets::Month.new(n*opts[:months])
      end
    end

    def + date_time
      @offset + date_time
    end

    def - date_time
      @offset - date_time
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

      def - date_time
        date_time - @n*multiplier
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

    class Month < Tick
      def freq_string
        'MONTH'
      end

      def + date_time
        date_time >> @n
      end

      def - date_time
        date_time << @n
      end
    end

    class Week < DateOffset
      def initialize *args
        @n = !args[0].is_a?(Hash)? args[0] : 1
        opts = args[-1]
        @weekday = opts[:weekday] || 0
      end

      def + date_time
        wday = date_time.wday
        distance = (@weekday - wday).abs
        if @weekday > wday
          date_time + distance + 7*(@n-1)
        else
          date_time + (7-distance) + 7*(@n -1)
        end
      end

      def - date_time
        wday = date_time.wday
        distance = (@weekday - wday).abs
        if @weekday >= wday
          date_time - ((7 - distance) + 7*(@n -1))
        else
          date_time - (distance + 7*(@n-1))
        end
      end

      def on_offset? date_time
        date_time.wday == @weekday
      end

      def freq_string
        'W' + '-' + Daru::DAYS_OF_WEEK.key(@weekday)
      end
    end

    class MonthBegin < DateOffset
      def initialize n=1
        @n = n
      end

      def freq_string
        'MB'
      end

      def + date_time
        days_in_month = Daru::MONTH_DAYS[date_time.month]
        days_in_month += 1 if date_time.leap? and date_time.month == 2
        date_time + (days_in_month - date_time.day + 1)
      end

      def - date_time
        date_time      = date_time << 1 if on_offset?(date_time)
        DateTime.new(date_time.year, date_time.month, 1)
      end

      def on_offset? date_time
        date_time.day == 1
      end
    end

    class MonthEnd < DateOffset
      def initialize n=1
        @n = n
      end

      def freq_string
        'ME'
      end

      def + date_time
        date_time     = date_time >> 1 if on_offset?(date_time)
        days_in_month = Daru::MONTH_DAYS[date_time.month]
        days_in_month += 1 if date_time.leap? and date_time.month == 2

        date_time + (days_in_month - date_time.day)
      end

      def - date_time
        date_time = date_time << 1
        days_in_month = Daru::MONTH_DAYS[date_time.month]
        days_in_month += 1 if date_time.leap? and date_time.month == 2

        date_time + (days_in_month - date_time.day)
      end

      def on_offset? date_time
        (date_time + 1).day == 1
      end
    end

    class YearBegin < DateOffset
      def initialize n=1
        @n = n
      end

      def freq_string
        'YB'
      end

      def + date_time
        DateTime.new(date_time.year + 1)
      end

      def - date_time
        if on_offset?(date_time)
          DateTime.new(date_time.year - 1, 1, 1)
        else
          DateTime.new(date_time.year, 1, 1)
        end
      end

      def on_offset? date_time
        date_time.month == 1 and date_time.day == 1
      end
    end

    class YearEnd < DateOffset
      def initialize n=1
        @n = n
      end

      def freq_string
        'YE'
      end

      def + date_time
        if on_offset?(date_time)
          DateTime.new(date_time.year + 1, 12, 31)
        else
          DateTime.new(date_time.year, 12, 31)
        end
      end

      def - date_time
        DateTime.new(date_time.year - 1, 12, 31)
      end

      def on_offset? date_time
        date_time.month == 12 and date_time.day == 31
      end
    end
  end
end