module Daru
  # Private module for storing helper functions for DateTimeIndex.
  module DateTimeIndexHelper
    class << self
      OFFSETS_HASH = {
        'S' => Offsets::Second,
        'M' => Offsets::Minute,
        'H' => Offsets::Hour,
        'D' => Offsets::Day,
        'W' => Offsets::Week,
        'MS' => Offsets::MonthStart,
        'ME' => Offsets::MonthEnd,
        'YS' => Offsets::YearStart,
        'YE' => Offsets::YearEnd
      }

      DAYS_OF_WEEK = {
        'SUN' => 0,
        'MON' => 1,
        'TUE' => 2,
        'WED' => 3,
        'THU' => 4,
        'FRI' => 5,
        'SAT' => 6
      }

      # Generates a Daru::DateOffset object for generic offsets or one of the
      # specialized classed within Daru::Offsets depending on the 'frequency'
      # string.
      #
      # The 'frequency' argument can denote one of the following:
      # * 'S'     - seconds
      # * 'M'     - minutes
      # * 'H'     - hours
      # * 'D'     - days
      # * 'W'     - Week (default) anchored on sunday
      # * 'W-SUN' - Same as 'W'
      # * 'W-MON' - Week anchored on monday
      # * 'W-TUE' - Week anchored on tuesday
      # * 'W-WED' - Week anchored on wednesday
      # * 'W-THU' - Week anchored on thursday
      # * 'W-FRI' - Week anchored on friday
      # * 'W-SAT' - Week anchored on saturday
      # * 'MS'    - month start
      # * 'ME'    - month end
      # * 'YS'    - year start
      # * 'YE'    - year end
      # 
      # Multiples of these can also be specified. For example '2S' for 2 seconds
      # or '2MS' for two month end offsets.
      def offset_from_frequency frequency
        raise ArgumentError, "Must specify :freq." if frequency.nil?
        return frequency if frequency.kind_of?(Daru::DateOffset)

        matched = /([0-9]*)(S|H|ME|MS|M|D|W|YS|YE)/.match(frequency)
        raise ArgumentError, 
          "Invalid frequency string #{frequency}" if matched.nil?

        n             = matched[1] == '0' ? 1 : matched[1].to_i
        offset_string = matched[2]
        offset_klass  = OFFSETS_HASH[offset_string]

        if offset_string == 'W'
          day = Regexp.new(DAYS_OF_WEEK.keys.join('|')).match frequency
        end

        offset_klass.new(n, weekday: DAYS_OF_WEEK[day])
      end

      def start_date start
        start.is_a?(String) ? DateTime.parse(start) : start
      end

      def end_date en
        en.is_a?(String) ? DateTime.parse(en) : en
      end

      def generate_data start, en, offset, periods
        
      end

      def derive_or_get_periods_directly start, en, periods
        
      end
    end
  end

  class DateTimeIndex < Index
    def initialize *args
      # So the initial plan of generating the date from start/end is canned and
      # is now replaced with one where we store the whole index (ie all the 
      # DateTime objs) in one array along with their indices and run a bsearch
      # on it to find the appropriate Date.
      #
      # The offset will only serve for generation of these DateTimes from the
      # start and end dates and periods.
    end

    def self.date_range opts={}
      helper = DateTimeIndexHelper

      start   = helper.start_date opts[:start]
      en      = helper.end_date opts[:end]
      periods = helper.derive_or_get_periods_directly start, en, opts[:periods]
      offset  = helper.offset_from_frequency opts[:freq]
      data    = helper.generate_data start, en, offset, periods

      DateTimeIndex.new(data, :freq => offset, :periods => periods, 
        :from_date_range => true)
    end

    def [] key
      if key.is_a?(Range)
        first = key.first
        last = key.last
        # For a Range key, just take the first and last and do a bsearch of both,
        # yielding the elements that will give us a demarcation and thereby serve
        # for slicing the index.
      else
        # single key entry

        # Single entry is bit more complicated. We need to support partial and 
        # complete date keys.
        #
        # For this reason, we will first take the string date, and resolve it
        # into what it is trying to say. This will be done by a function that 
        # will take in a date-like string as an input argument and output two
        # DateTime objects: the first one will denote the start of the range 
        # that the partial date-string represents and the second the end of the
        # range that the date-string represents.
        # 
        # For example, say the date-string is '2012'. This means that we're 
        # supposed to serve all the dates in the year 2012. So the string 2012
        # yields two objects, one which denotes 2012-1-1 00:00:00 and the other
        # one which denotes 2012-12-31 24:59:59. A binary search on the index
        # array can then be applied using these two objects and that will yield
        # the slice.
      end 
    end

    def size
      
    end

    def == other
      
    end
  end
end