module Daru
  # Generic class for generating date offsets.
  class DateOffset
    # A Daru::DateOffset object is created by a passing certain options
    # to the constructor, which determine the kind of offset the object
    # will support.
    #
    # You can pass one of the following options followed by their number
    # to the DateOffset constructor:
    #
    # * :secs - Create a seconds offset
    # * :mins - Create a minutes offset
    # * :hours - Create an hours offset
    # * :days  - Create a days offset
    # * :weeks - Create a weeks offset
    # * :months - Create a months offset
    # * :years - Create a years offset
    # 
    # Additionaly, passing the `:n` option will apply the offset that many times.
    #
    # @example Usage of DateOffset
    #   # Create an offset of 3 weeks.
    #   offset = Daru::DateOffset.new(weeks: 3)
    #   offset + DateTime.new(2012,5,3)
    #   #=> #<DateTime: 2012-05-24T00:00:00+00:00 ((2456072j,0s,0n),+0s,2299161j)>
    #  
    #   # Create an offset of 5 hours
    #   offset = Daru::DateOffset.new(hours: 5)
    #   offset + DateTime.new(2015,3,3,23,5,1)
    #   #=> #<DateTime: 2015-03-04T04:05:01+00:00 ((2457086j,14701s,0n),+0s,2299161j)>
    #
    #   # Create an offset of 2 minutes, applied 5 times
    #   offset = Daru::DateOffset.new(mins: 2, n: 5)
    #   offset + DateTime.new(2011,5,3,3,5)
    #   #=> #<DateTime: 2011-05-03T03:15:00+00:00 ((2455685j,11700s,0n),+0s,2299161j)>
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
      when opts[:years]
        Offsets::Year.new(n*opts[:years])
      end
    end

    # Offset a DateTime forward.
    #
    # @param date_time [DateTime] A DateTime object which is to offset.
    def + date_time
      @offset + date_time
    end

    # Offset a DateTime backward.
    #
    # @param date_time [DateTime] A DateTime object which is to offset.
    def - date_time
      @offset - date_time
    end
  end

  module Offsets
    # Private superclass for Offsets with equal inter-frequencies.
    # @abstract
    # @private
    class Tick < DateOffset
      # Initialize one of the subclasses of Tick with the number of the times
      # the offset should be applied, which is the supplied as the argument.
      #
      # @param n [Integer] The number of times an offset should be applied.
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

    # Create a seconds offset
    # 
    # @param n [Integer] The number of times an offset should be applied.
    # @example Create a Seconds offset
    #   offset = Daru::Offsets::Second.new(5)
    #   offset + DateTime.new(2012,5,1,4,3)
    #   #=> #<DateTime: 2012-05-01T04:03:05+00:00 ((2456049j,14585s,0n),+0s,2299161j)>
    class Second < Tick
      def multiplier
        1.1574074074074073e-05
      end

      def freq_string
        'S'
      end
    end

    # Create a minutes offset
    # 
    # @param n [Integer] The number of times an offset should be applied.
    # @example Create a Minutes offset
    #   offset = Daru::Offsets::Minute.new(8)
    #   offset + DateTime.new(2012,5,1,4,3)
    #   #=> #<DateTime: 2012-05-01T04:11:00+00:00 ((2456049j,15060s,0n),+0s,2299161j)>
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

    class Year < Tick
      def freq_string
        'YEAR'
      end

      def + date_time
        date_time >> @n*12
      end

      def - date_time
        date_time << @n*12
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
        @n.times do
          days_in_month = Daru::MONTH_DAYS[date_time.month]
          days_in_month += 1 if date_time.leap? and date_time.month == 2
          date_time = date_time + (days_in_month - date_time.day + 1)
        end

        date_time
      end

      def - date_time
        @n.times do
          date_time = date_time << 1 if on_offset?(date_time)
          date_time = DateTime.new(date_time.year, date_time.month, 1, 
            date_time.hour, date_time.min, date_time.sec)
        end

        date_time
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
        @n.times do 
          date_time     = date_time >> 1 if on_offset?(date_time)
          days_in_month = Daru::MONTH_DAYS[date_time.month]
          days_in_month += 1 if date_time.leap? and date_time.month == 2

          date_time = date_time + (days_in_month - date_time.day)
        end

        date_time
      end

      def - date_time
        @n.times do 
          date_time = date_time << 1
          days_in_month = Daru::MONTH_DAYS[date_time.month]
          days_in_month += 1 if date_time.leap? and date_time.month == 2

          date_time = date_time + (days_in_month - date_time.day)
        end

        date_time
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
        DateTime.new(date_time.year + @n, 1, 1,
          date_time.hour,date_time.min, date_time.sec)
      end

      def - date_time
        if on_offset?(date_time)
          DateTime.new(date_time.year - @n, 1, 1, 
            date_time.hour,date_time.min, date_time.sec)
        else
          DateTime.new(date_time.year - (@n-1), 1, 1)
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
          DateTime.new(date_time.year + @n, 12, 31,
            date_time.hour, date_time.min, date_time.sec)
        else
          DateTime.new(date_time.year + (@n-1), 12, 31,
            date_time.hour, date_time.min, date_time.sec)
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