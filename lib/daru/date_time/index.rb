module Daru
  # Private module for storing helper functions for DateTimeIndex.
  module DateTimeIndexHelper
    class << self
      OFFSETS_HASH = {
        'S'  => Daru::Offsets::Second,
        'M'  => Daru::Offsets::Minute,
        'H'  => Daru::Offsets::Hour,
        'D'  => Daru::Offsets::Day,
        'W'  => Daru::Offsets::Week,
        'MB' => Daru::Offsets::MonthBegin,
        'ME' => Daru::Offsets::MonthEnd,
        'YS' => Daru::Offsets::YearBegin,
        'YE' => Daru::Offsets::YearEnd
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

        n             = matched[1] == "" ? 1 : matched[1].to_i
        offset_string = matched[2]
        offset_klass  = OFFSETS_HASH[offset_string]

        if offset_string == 'W'
          day = Regexp.new(DAYS_OF_WEEK.keys.join('|')).match frequency
          return offset_klass.new(n, weekday: DAYS_OF_WEEK[day])
        end

        offset_klass.new(n)
      end

      def start_date start
        start.is_a?(String) ? DateTime.parse(start) : start
      end

      def end_date en
        en.is_a?(String) ? DateTime.parse(en) : en
      end

      def generate_data start, en, offset, periods
        data = []
        new_date = start

        if periods.nil? # use end
          i = 0
          loop do
            break if new_date > en
            data << [new_date, i]
            new_date = offset + new_date
            i += 1
          end
        else
          periods.times do |i|
            data << [new_date, i]
            new_date = offset + new_date
          end
        end

        data
      end

      def verify_start_and_end start, en
        raise ArgumentError, "Start and end cannot be the same" if start == en
        raise ArgumentError, "Start must be lesser than end"    if start > en
        raise ArgumentError, 
          "Only same time zones are allowed" if start.zone != en.zone
      end

      def infer_offset data
        raise NotImplementedError
      end

      def find_index_of_date date_time
        searched = @data.bsearch { |d| d[0] >= date_time }
        searched[0] == date_time ? searched[1] : nil
      end

      def find_date_string_bounds date_string
        date_precision = determine_date_precision_of date_string
        generate_date_slice DateTime.parse(date_string), date_precision
        # first I need to find what the date string resolves to, i.e. I need to
        #   figure what is the precision of the date string. Is it yearly, i.e.
        #   is it something like '2012', or is it monthly, i.e. something like
        #   '2012-3'?
        #
        # Based on this precision/resolution I need to figure out the bounds 
        # by outputting the next date in the same precision. So for example,
        # a year resolution should give the next year, a month resolution should
        # give the next month etc.
      end

      def determine_date_precision_of date_string
        
      end

      def generate_date_slice date_time, date_precision
        
      end
    end
  end

  class DateTimeIndex < Index
    include Enumerable

    def each(&block)
      @data.each do |d|
        yield d[0]
      end
    end

    attr_reader :frequency, :offset, :periods

    def initialize *args
      helper = DateTimeIndexHelper

      data = args[0]
      opts = args[1] || {freq: nil}

      @offset = 
      case opts[:freq]
      when 'infer' then helper.infer_offset(data)
      when  nil    then nil
      else  helper.offset_from_frequency(opts[:freq])
      end

      @frequency = @offset ? @offset.freq_string : nil
      @data      = data
      @periods   = data.size
    end

    # Create a date range by specifying the start, end, periods and frequency
    # of the data.
    def self.date_range opts={}
      helper = DateTimeIndexHelper

      start  = helper.start_date opts[:start]
      en     = helper.end_date opts[:end]
      helper.verify_start_and_end start, en
      offset = helper.offset_from_frequency opts[:freq]
      data   = helper.generate_data start, en, offset, opts[:periods]

      DateTimeIndex.new(data, :freq => offset)
    end

    def [] key
      if key.is_a?(Range)
        first = key.first
        last = key.last
        # For a Range key, just take the first and last and do a bsearch of both,
        # yielding the elements that will give us a demarcation and thereby serve
        # for slicing the index.
      else
        helper = DateTimeIndexHelper

        if key.is_a?(DateTime)
          return helper.find_index_of_date(key)
        else
          slice_begin, slice_end = helper.find_date_string_bounds key
        end

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

    def to_a
      @data.transpose[0]
    end

    def size
      @periods
    end

    def == other
      self.to_a == other.to_a
    end
  end
end