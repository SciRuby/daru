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
        'MONTH' => Daru::Offsets::Month,
        'MB' => Daru::Offsets::MonthBegin,
        'ME' => Daru::Offsets::MonthEnd,
        'YB' => Daru::Offsets::YearBegin,
        'YE' => Daru::Offsets::YearEnd
      }

      TIME_INTERVALS = {
        Rational(1,1)     => Daru::Offsets::Day,
        Rational(1,24)    => Daru::Offsets::Hour,
        Rational(1,1440)  => Daru::Offsets::Minute,
        Rational(1,86400) => Daru::Offsets::Second
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
      # * 'MONTH' - Month
      # * 'MB'    - month begin
      # * 'ME'    - month end
      # * 'YB'    - year begin
      # * 'YE'    - year end
      # 
      # Multiples of these can also be specified. For example '2S' for 2 seconds
      # or '2MS' for two month end offsets.
      def offset_from_frequency frequency
        frequency = 'D' if frequency.nil?
        return frequency if frequency.kind_of?(Daru::DateOffset)

        matched = /([0-9]*)(MONTH|S|H|MB|ME|M|D|W|YB|YE)/.match(frequency)
        raise ArgumentError, 
          "Invalid frequency string #{frequency}" if matched.nil?

        n             = matched[1] == "" ? 1 : matched[1].to_i
        offset_string = matched[2]
        offset_klass  = OFFSETS_HASH[offset_string]

        raise ArgumentError,
          "Cannont interpret offset #{offset_string}" if offset_klass.nil?

        if offset_string.match(/W/)
          day = Regexp.new(Daru::DAYS_OF_WEEK.keys.join('|')).match(frequency).to_s
          return offset_klass.new(n, weekday: Daru::DAYS_OF_WEEK[day])
        end

        offset_klass.new(n)
      end

      def start_date start
        start.is_a?(String) ? date_time_from(
          start, determine_date_precision_of(start)) : start
      end

      def end_date en
        en.is_a?(String) ? date_time_from(
          en, determine_date_precision_of(en)) : en
      end

      def begin_from_zeroth offset, start
        if offset.kind_of?(Tick) or 
          (offset.respond_to?(:on_offset?) and offset.on_offset?(start))
          true
        else
          false
        end
      end

      def generate_data start, en, offset, periods
        data = []
        new_date = begin_from_zeroth(offset, start) ? start : offset + start

        if periods.nil? # use end
          loop do
            break if new_date > en
            data << new_date
            new_date = offset + new_date
          end
        else
          periods.times do |i|
            data << new_date
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
        searched[0] == date_time ? searched[1] : nil
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
            date_string.match(/\-\d?\d/).to_s.gsub("-",'').to_i)
        else
          DateTime.parse date_string
        end
      end

      def determine_date_precision_of date_string
        case date_string
        when /\d\d\d\d\-\d?\d\-\d?\d \d?\d:\d?\d:\d?\d/
          :second
        when /\d\d\d\d\-\d?\d\-\d?\d \d?\d:\d?\d/
          :minute
        when /\d\d\d\d\-\d?\d\-\d?\d \d?\d/
          :hour
        when /\d\d\d\d\-\d?\d\-\d?\d/
          :date
        when /\d\d\d\d\-\d?\d/
          :month
        when /\d\d\d\d/
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
        when :date
        # when (:date and !frequency.match(/D/))
          [
            date_time,
            DateTime.new(date_time.year, date_time.month, date_time.day,23,59,59)
          ]
        when :hour
        # when (:hour and !frequency.match(/H/))
          [
            date_time,
            DateTime.new(date_time.year, date_time.month, date_time.day, 
            date_time.hour,59,59)
          ]
        when :minute
        # when (:minute and !frequency.match(/M/))
          [
            date_time,
            DateTime.new(date_time.year, date_time.month, date_time.day, 
              date_time.hour, date_time.min, 59)
           ]
        else # second or when precision is same as offset
          [ date_time, date_time ]
        end
      end

      def possibly_convert_to_date_time data
        data[0].is_a?(String) ? data.map! { |e| DateTime.parse(e) } : data
      end
    end
  end

  class DateTimeIndex < Index
    include Enumerable

    def each(&block)
      to_a.each(&block)
    end

    attr_reader :frequency, :offset, :periods

    def initialize *args
      helper = DateTimeIndexHelper

      data = args[0]
      opts = args[1] || {freq: nil}

      helper.possibly_convert_to_date_time data

      @offset = 
      case opts[:freq]
      when :infer then helper.infer_offset(data)
      when  nil    then nil
      else  helper.offset_from_frequency(opts[:freq])
      end

      @frequency = @offset ? @offset.freq_string : nil
      @data      = data.zip(Array.new(data.size) { |i| i })
      @data.sort_by! { |d| d[0] } if @offset.nil?
      @periods   = data.size
    end

    # Create a date range by specifying the start, end, periods and frequency
    # of the data.
    def self.date_range opts={}
      helper = DateTimeIndexHelper

      start  = helper.start_date opts[:start]
      en     = helper.end_date opts[:end]
      helper.verify_start_and_end(start, en) unless en.nil?
      offset = helper.offset_from_frequency opts[:freq]
      data   = helper.generate_data start, en, offset, opts[:periods]

      DateTimeIndex.new(data, :freq => offset)
    end

    def [] *key
      helper = DateTimeIndexHelper
      if key.size == 1
        key = key[0] 
      else
        return slice(*key)
      end

      if key.is_a?(Range)
        slice_begin = helper.find_date_string_bounds(key.first)[0]
        slice_end   = helper.find_date_string_bounds(key.last)[1]
      else
        if key.is_a?(DateTime)
          return helper.find_index_of_date(@data, key)
        else
          slice_begin, slice_end = helper.find_date_string_bounds key
        end
      end

      slice slice_begin, slice_end
    end

    def slice first, last
      helper = DateTimeIndexHelper

      if first.is_a?(String) and last.is_a?(String)
        self[first..last]
      else
        first_dt = first.is_a?(String) ? 
          helper.find_date_string_bounds(first)[0] : first
        last_dt = last.is_a?(String) ?
          helper.find_date_string_bounds(last)[1]  : last

        start    = @data.bsearch { |d| d[0] >= first_dt }
        after_en = @data.bsearch { |d| d[0] > last_dt }

        result =
        if @offset
          en = after_en ? @data[after_en[1] - 1] : @data.last
          return start[1] if start == en
          DateTimeIndex.date_range :start => start[0], :end => en[0], freq: @offset
        else
          st = @data.index(start)
          en = after_en ? @data.index(after_en) - 1 : @data.last[1]
          return start[1] if st == en
          DateTimeIndex.new(@data[st..en].transpose[0])
        end

        result
      end   
    end

    def to_a
      return @data.sort_by { |d| d[1] }.transpose[0] unless @offset
      @data.transpose[0]
    end

    def size
      @periods
    end

    def == other
      self.to_a == other.to_a
    end

    def inspect
      
    end

    def shift distance
      
    end

    def lag distance
      
    end

    [:year, :month, :day, :hour, :min, :sec].each do |meth|
      define_method(meth) do
        self.inject([]) do |arr, d|
          arr << d.send(meth)
          arr
        end
      end
    end
  end
end