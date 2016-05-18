module Daru
  # Private module for storing helper functions for DateTimeIndex.
  # @private
  module DateTimeIndexHelper
    class << self
      OFFSETS_HASH = {
        'S'  => Daru::Offsets::Second,
        'M'  => Daru::Offsets::Minute,
        'H'  => Daru::Offsets::Hour,
        'D'  => Daru::Offsets::Day,
        'W'  => Daru::Offsets::Week,
        'MONTH' => Daru::Offsets::Month,
        'MB' => Daru::Offsets::MonthBegin,
        'ME' => Daru::Offsets::MonthEnd,
        'YEAR' => Daru::Offsets::Year,
        'YB' => Daru::Offsets::YearBegin,
        'YE' => Daru::Offsets::YearEnd
      }.freeze

      TIME_INTERVALS = {
        Rational(1,1)     => Daru::Offsets::Day,
        Rational(1,24)    => Daru::Offsets::Hour,
        Rational(1,1440)  => Daru::Offsets::Minute,
        Rational(1,86_400) => Daru::Offsets::Second
      }.freeze

      # Generates a Daru::DateOffset object for generic offsets or one of the
      # specialized classed within Daru::Offsets depending on the 'frequency'
      # string.
      def offset_from_frequency frequency
        frequency = 'D' if frequency.nil?
        return frequency if frequency.is_a?(Daru::DateOffset)

        matched = /([0-9]*)(MONTH|YEAR|S|H|MB|ME|M|D|W|YB|YE)/.match(frequency)
        raise ArgumentError,
          "Invalid frequency string #{frequency}" if matched.nil?

        n             = matched[1] == '' ? 1 : matched[1].to_i
        offset_string = matched[2]
        offset_klass  = OFFSETS_HASH[offset_string]

        raise ArgumentError,
          "Cannont interpret offset #{offset_string}" if offset_klass.nil?

        if offset_string =~ /W/
          day = Regexp.new(Daru::DAYS_OF_WEEK.keys.join('|')).match(frequency).to_s
          return offset_klass.new(n, weekday: Daru::DAYS_OF_WEEK[day])
        end

        offset_klass.new(n)
      end

      def start_date start
        if start.is_a?(String)
          date_time_from(start, determine_date_precision_of(start))
        else
          start
        end
      end

      def end_date en
        if en.is_a?(String)
          date_time_from(en, determine_date_precision_of(en))
        else
          en
        end
      end

      def begin_from_offset? offset, start
        if offset.is_a?(Daru::Offsets::Tick) ||
           (offset.respond_to?(:on_offset?) && offset.on_offset?(start))
          true
        else
          false
        end
      end

      def generate_data start, en, offset, periods
        data = []
        new_date = begin_from_offset?(offset, start) ? start : offset + start

        if periods.nil? # use end
          loop do
            break if new_date > en
            data << new_date
            new_date = offset + new_date
          end
        else
          periods.times do
            data << new_date
            new_date = offset + new_date
          end
        end

        data
      end

      def verify_start_and_end start, en
        raise ArgumentError, 'Start and end cannot be the same' if start == en
        raise ArgumentError, 'Start must be lesser than end'    if start > en
        raise ArgumentError,
          'Only same time zones are allowed' if start.zone != en.zone
      end

      def infer_offset data
        possible_freq = data[1] - data[0]
        inferred = true
        data.each_cons(2) do |d|
          if d[1] - d[0] != possible_freq
            inferred = false
            break
          end
        end

        if inferred
          TIME_INTERVALS[possible_freq].new
        else
          nil
        end
      end

      def find_index_of_date data, date_time
        searched = data.bsearch { |d| d[0] >= date_time }
        raise(ArgumentError, "Cannot find #{date_time}") if searched.nil? || searched[0] != date_time

        searched[1]
      end

      def find_date_string_bounds date_string
        date_precision = determine_date_precision_of date_string
        date_time = date_time_from date_string, date_precision
        generate_bounds date_time, date_precision
      end

      def date_time_from date_string, date_precision
        case date_precision
        when :year
          DateTime.new(date_string.gsub(/[^0-9]/, '').to_i)
        when :month
          DateTime.new(
            date_string.match(/\d\d\d\d/).to_s.to_i,
            date_string.match(/\-\d?\d/).to_s.delete('-').to_i
          )
        else
          DateTime.parse date_string
        end
      end

      def determine_date_precision_of date_string
        case date_string
        when /^\d\d\d\d\-\d?\d\-\d?\d \d?\d:\d?\d:\d?\d$/
          :sec
        when /^\d\d\d\d\-\d?\d\-\d?\d \d?\d:\d?\d$/
          :min
        when /^\d\d\d\d\-\d?\d\-\d?\d \d?\d$/
          :hour
        when /^\d\d\d\d\-\d?\d\-\d?\d$/
          :day
        when /^\d\d\d\d\-\d?\d$/
          :month
        when /^\d\d\d\d$/
          :year
        else
          raise ArgumentError, "Unacceptable date string #{date_string}"
        end
      end

      def generate_bounds date_time, date_precision
        case date_precision
        when :year
          [
            date_time,
            DateTime.new(date_time.year,12,31,23,59,59)
          ]
        when :month
          [
            date_time,
            DateTime.new(date_time.year, date_time.month, ((date_time >> 1) - 1).day,
              23,59,59)
          ]
        when :day
          [
            date_time,
            DateTime.new(date_time.year, date_time.month, date_time.day,23,59,59)
          ]
        when :hour
          [
            date_time,
            DateTime.new(date_time.year, date_time.month, date_time.day,
              date_time.hour,59,59)
          ]
        when :min
          [
            date_time,
            DateTime.new(date_time.year, date_time.month, date_time.day,
              date_time.hour, date_time.min, 59)
          ]
        else # second or when precision is same as offset
          [date_time, date_time]
        end
      end

      def possibly_convert_to_date_time data
        data[0].is_a?(String) ? data.map! { |e| DateTime.parse(e) } : data
      end

      def last_date data
        data.sort_by { |d| d[1] }.last
      end

      def key_out_of_bounds? key, data
        precision = determine_date_precision_of key
        date_time = date_time_from key, precision
        case precision
        when :year
          date_time.year < data[0][0].year || date_time.year > data[-1][0].year
        when :month
          (date_time.year < data[0][0].year && date_time.month < data[0][0].month) ||
            (date_time.year > data[-1][0].year and date_time.month > data[-1][0].month)
        end
      end
    end
  end

  class DateTimeIndex < Index
    include Enumerable

    def each(&block)
      to_a.each(&block)
    end

    attr_reader :frequency, :offset, :periods

    # Create a DateTimeIndex with or without a frequency in data. The constructor
    # should be used for creating DateTimeIndex by directly passing in DateTime
    # objects or date-like strings, typically in cases where values with frequency
    # are not needed.
    #
    # @param [Array<String>, Array<DateTime>] data Array of date-like Strings or
    #   actual DateTime objects for creating the DateTimeIndex.
    # @param [Hash] opts Hash of options for configuring index.
    # @option opts [Symbol, NilClass, String, Daru::DateOffset, Daru::Offsets::*] freq
    #   Option for specifying the frequency of data, if applicable. If `:infer` is
    #   passed to this option, daru will try to infer the frequency of the data
    #   by itself.
    #
    # @example Usage of DateTimeIndex constructor
    #   index = Daru::DateTimeIndex.new(
    #     [DateTime.new(2012,4,5), DateTime.new(2012,4,6),
    #      DateTime.new(2012,4,7), DateTime.new(2012,4,8)])
    #   #=>#<DateTimeIndex:84232240 offset=nil periods=4 data=[2012-04-05T00:00:00+00:00...2012-04-08T00:00:00+00:00]>
    #
    #   index = Daru::DateTimeIndex.new([
    #     DateTime.new(2012,4,5), DateTime.new(2012,4,6), DateTime.new(2012,4,7),
    #     DateTime.new(2012,4,8), DateTime.new(2012,4,9), DateTime.new(2012,4,10),
    #     DateTime.new(2012,4,11), DateTime.new(2012,4,12)], freq: :infer)
    #   #=>#<DateTimeIndex:84198340 offset=D periods=8 data=[2012-04-05T00:00:00+00:00...2012-04-12T00:00:00+00:00]>
    def initialize *args
      helper = DateTimeIndexHelper

      data = args[0]
      opts = args[1] || {freq: nil}

      helper.possibly_convert_to_date_time data

      @offset =
        case opts[:freq]
        when :infer then helper.infer_offset(data)
        when  nil   then nil
        else  helper.offset_from_frequency(opts[:freq])
        end

      @frequency = @offset ? @offset.freq_string : nil
      @data      = data.zip(Array.new(data.size) { |i| i })
      @data.sort_by! { |d| d[0] } if @offset.nil?

      @periods = data.size
    end

    # Custom dup method for DateTimeIndex
    def dup
      Daru::DateTimeIndex.new(@data.transpose[0], freq: @offset)
    end

    # Create a date range by specifying the start, end, periods and frequency
    # of the data.
    #
    # @param [Hash] opts Options hash to create the date range with
    # @option opts [String, DateTime] :start A DateTime object or date-like
    #   string that defines the start of the date range.
    # @option opts [String, DateTime] :end A DateTime object or date-like string
    #   that defines the end of the date range.
    # @option opts [String, Daru::DateOffset, Daru::Offsets::*] :freq ('D') The interval
    #   between each date in the index. This can either be a string specifying
    #   the frequency (i.e. one of the frequency aliases) or an offset object.
    # @option opts [Fixnum] :periods The number of periods that should go into
    #   this index. Takes precedence over `:end`.
    # @return [DateTimeIndex] DateTimeIndex object of the specified parameters.
    #
    # == Notes
    #
    # If you specify :start and :end options as strings, they can be complete or
    # partial dates and daru will intelligently infer the date from the string
    # directly. However, note that the date-like string must be in the format
    # `YYYY-MM-DD HH:MM:SS`.
    #
    # The string aliases supported by the :freq option are as follows:
    #
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
    # * 'MONTH' - Month
    # * 'YEAR'  - One year
    # * 'MB'    - month begin
    # * 'ME'    - month end
    # * 'YB'    - year begin
    # * 'YE'    - year end
    #
    # Multiples of these can also be specified. For example '2S' for 2 seconds
    # or '2ME' for two month end offsets.
    #
    # Currently the precision of DateTimeIndex is upto seconds only, though this
    # will improve in the future.
    #
    # @example Creating date ranges
    #   Daru::DateTimeIndex.date_range(
    #     :start => DateTime.new(2014,5,1),
    #     :end   => DateTime.new(2014,5,2), :freq => '6H')
    #   #=>#<DateTimeIndex:83600130 offset=H periods=5 data=[2014-05-01T00:00:00+00:00...2014-05-02T00:00:00+00:00]>
    #
    #   Daru::DateTimeIndex.date_range(
    #     :start => '2012-5-2', :periods => 50, :freq => 'ME')
    #   #=> #<DateTimeIndex:83549940 offset=ME periods=50 data=[2012-05-31T00:00:00+00:00...2016-06-30T00:00:00+00:00]>
    def self.date_range opts={}
      helper = DateTimeIndexHelper

      start  = helper.start_date opts[:start]
      en     = helper.end_date opts[:end]
      helper.verify_start_and_end(start, en) unless en.nil?
      offset = helper.offset_from_frequency opts[:freq]
      data   = helper.generate_data start, en, offset, opts[:periods]

      DateTimeIndex.new(data, freq: offset)
    end

    # Retreive a slice or a an individual index number from the index.
    #
    # @param [String, DateTime] Specify a date partially (as a String) or
    #   completely to retrieve.
    def [] *key
      helper = DateTimeIndexHelper

      return slice(*key) if key.size != 1
      key = key[0]
      return key if key.is_a?(Numeric)

      if key.is_a?(Range)
        first = key.first
        last = key.last
        return slice(first, last) if
          first.is_a?(Fixnum) && last.is_a?(Fixnum)

        raise ArgumentError, "Keys #{first} and #{last} are out of bounds" if
          helper.key_out_of_bounds?(first, @data) && helper.key_out_of_bounds?(last, @data)

        slice_begin = helper.find_date_string_bounds(first)[0]
        slice_end   = helper.find_date_string_bounds(last)[1]
      elsif key.is_a?(DateTime)
        return helper.find_index_of_date(@data, key)
      else
        raise ArgumentError, "Key #{key} is out of bounds" if
          helper.key_out_of_bounds?(key, @data)

        slice_begin, slice_end = helper.find_date_string_bounds key
      end

      slice slice_begin, slice_end
    end

    # Retrive a slice of the index by specifying first and last members of the slice.
    #
    # @param [String, DateTime] first Start of the slice as a string or DateTime.
    # @param [String, DateTime] last End of the slice as a string or DateTime.
    def slice first, last
      helper = DateTimeIndexHelper

      if first.is_a?(String) && last.is_a?(String)
        self[first..last]
      elsif first.is_a?(Fixnum) && last.is_a?(Fixnum)
        DateTimeIndex.new(to_a[first..last], freq: @offset)
      else
        first_dt =
          if first.is_a?(String)
            helper.find_date_string_bounds(first)[0]
          else
            first
          end

        last_dt =
          if last.is_a?(String)
            helper.find_date_string_bounds(last)[1]
          else
            last
          end

        start    = @data.bsearch { |d| d[0] >= first_dt }
        after_en = @data.bsearch { |d| d[0] > last_dt }

        result =
          if @offset
            en = after_en ? @data[after_en[1] - 1] : @data.last
            return start[1] if start == en
            DateTimeIndex.date_range start: start[0], end: en[0], freq: @offset
          else
            st = @data.index(start)
            en = after_en ? @data.index(after_en) - 1 : helper.last_date(@data)[1]
            return start[1] if st == en
            DateTimeIndex.new(@data[st..en].transpose[0])
          end

        result
      end
    end

    # Return the DateTimeIndex as an Array of DateTime objects.
    # @return [Array<DateTime>] Array of containing DateTimes.
    def to_a
      return @data.sort_by { |d| d[1] }.transpose[0] unless @offset
      @data.transpose[0]
    end

    # Size of index.
    def size
      @periods
    end

    def == other
      to_a == other.to_a
    end

    def inspect
      string = '#<DateTimeIndex:' + object_id.to_s + ' offset=' +
               (@offset ? @offset.freq_string : 'nil') + ' periods=' + @periods.to_s +
               ' data=[' + @data.first[0].to_s + '...' + @data.last[0].to_s + ']'+ '>'

      string
    end

    # Shift all dates in the index by a positive number in the future. The dates
    # are shifted by the same amount as that specified in the offset.
    #
    # @param [Fixnum, Daru::DateOffset, Daru::Offsets::*] distance Distance by
    #   which each date should be shifted. Passing an offset object to #shift
    #   will offset each data point by the offset value. Passing a positive
    #   integer will offset each data point by the same offset that it was
    #   created with.
    # @return [DateTimeIndex] Returns a new, shifted DateTimeIndex object.
    # @example Using the shift method
    #   index = Daru::DateTimeIndex.date_range(
    #     :start => '2012', :periods => 10, :freq => 'YEAR')
    #
    #   # Passing a offset to shift
    #   index.shift(Daru::Offsets::Hour.new(3))
    #   #=>#<DateTimeIndex:84038960 offset=nil periods=10 data=[2012-01-01T03:00:00+00:00...2021-01-01T03:00:00+00:00]>
    #
    #   # Pass an integer to shift
    #   index.shift(4)
    #   #=>#<DateTimeIndex:83979630 offset=YEAR periods=10 data=[2016-01-01T00:00:00+00:00...2025-01-01T00:00:00+00:00]>
    def shift distance
      if distance.is_a?(Fixnum)
        raise IndexError, "Distance #{distance} cannot be negative" if distance < 0
        raise IndexError, 'To shift non-freq date time index pass an offset.' unless @offset

        start = @data[0][0]
        distance.times { start = @offset + start }
        DateTimeIndex.date_range(start: start, periods: @periods, freq: @offset)
      else # its a Daru::Offset/DateOffset
        DateTimeIndex.new(to_a.map { |e| distance + e }, freq: :infer)
      end
    end

    # Shift all dates in the index to the past. The dates are shifted by the same
    # amount as that specified in the offset.
    #
    # @param [Fixnum, Daru::DateOffset, Daru::Offsets::*] distance Fixnum or
    #   Daru::DateOffset. Distance by which each date should be shifted. Passing
    #   an offset object to #lag will offset each data point by the offset value.
    #   Passing a positive integer will offset each data point by the same offset
    #   that it was created with.
    # @return [DateTimeIndex] A new lagged DateTimeIndex object.
    def lag distance
      if distance.is_a?(Fixnum)
        raise IndexError, "Distance #{distance} cannot be negative" if distance < 0
        raise IndexError, 'To lag non-freq date time index pass an offset.' unless @offset

        start = @data[0][0]
        distance.times { start = @offset - start }
        DateTimeIndex.date_range(start: start, periods: @periods, freq: @offset)
      else
        DateTimeIndex.new(to_a.map { |e| distance - e }, freq: :infer)
      end
    end

    # :nocov:
    def _dump(_depth)
      Marshal.dump(data: to_a, freq: @offset)
    end

    def self._load data
      h = Marshal.load data

      Daru::DateTimeIndex.new(h[:data], freq: h[:freq])
    end
    # :nocov:

    # @!method year
    #   @return [Array<Fixnum>] Array containing year of each index.
    # @!method month
    #   @return [Array<Fixnum>] Array containing month of each index.
    # @!method day
    #   @return [Array<Fixnum>] Array containing day of each index.
    # @!method hour
    #   @return [Array<Fixnum>] Array containing hour of each index.
    # @!method min
    #   @return [Array<Fixnum>] Array containing minutes of each index.
    # @!method sec
    #   @return [Array<Fixnum>] Array containing seconds of each index.
    [:year, :month, :day, :hour, :min, :sec].each do |meth|
      define_method(meth) do
        each_with_object([]) do |d, arr|
          arr << d.send(meth)
        end
      end
    end

    # Check if a date exists in the index. Will be inferred from string in case
    # you pass a string. Recommened specifying the full date as a DateTime object.
    def include? date_time
      return false unless date_time.is_a?(String) || date_time.is_a?(DateTime)
      helper = DateTimeIndexHelper
      if date_time.is_a?(String)
        date_precision = helper.determine_date_precision_of date_time
        date_time = helper.date_time_from date_time, date_precision
      end

      result = @data.bsearch { |d| d[0] >= date_time }
      return false if result.nil?
      result[0] == date_time
    end

    # Return true if the DateTimeIndex is empty.
    def empty?
      @data.empty?
    end
  end
end
