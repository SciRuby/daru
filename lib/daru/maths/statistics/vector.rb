module Daru
  module Maths
    # Encapsulates statistics methods for vectors. Most basic stuff like mean, etc.
    # is done inside the wrapper, so that native methods can be used for most of
    # the computationally intensive tasks.
    module Statistics
      module Vector # rubocop:disable Metrics/ModuleLength
        extend Gem::Deprecate

        def mean
          @data.mean
        end

        def sum
          @data.sum
        end

        def product
          @data.product
        end

        def range
          max - min
        end

        def median
          @data.respond_to?(:median) ? @data.median : percentile(50)
        end

        def mode
          mode = frequencies.to_h.select { |_,v| v == frequencies.max }.keys
          mode.size > 1 ? Daru::Vector.new(mode) : mode.first
        end

        # Create a summary of count, mean, standard deviation, min and max of
        # the vector in one shot.
        #
        # == Arguments
        #
        # +methods+ - An array with aggregation methods specified as symbols to
        # be applied to vectors. Default is [:count, :mean, :std, :max,
        # :min]. Methods will be applied in the specified order.
        def describe methods=nil
          methods ||= %i[count mean std min max]
          description = methods.map { |m| send(m) }
          Daru::Vector.new(description, index: methods, name: :statistics)
        end

        def median_absolute_deviation
          m = median
          recode { |val| (val - m).abs }.median
        end

        alias :mad :median_absolute_deviation

        def standard_error
          standard_deviation_sample/Math.sqrt(size - count_values(*Daru::MISSING_VALUES))
        end

        def sum_of_squared_deviation
          (@data.inject(0) { |a,x| x**2 + a } - (sum**2).quo(size - count_values(*Daru::MISSING_VALUES)).to_f).to_f
        end

        # Retrieve unique values of non-nil data
        def factors
          reject_values(*Daru::MISSING_VALUES).uniq.reset_index!
        end

        if RUBY_VERSION >= '2.2'
          # Returns the maximum value(s) present in the vector, with an optional comparator block.
          #
          # @param size [Integer] Number of maximum values to return. Defaults to nil.
          #
          # @example
          #
          #   dv = Daru::Vector.new (["Tyrion", "Daenerys", "Jon Starkgaryen"]), index: Daru::Index.new([:t, :d, :j])
          #   #=>
          #   #   #<Daru::Vector(3)>
          #   #       t   Tyrion
          #   #       d   Daenerys
          #   #       j   Jon Starkgaryen
          #
          #   dv.max
          #   #=> "Tyrion"
          #
          #   dv.max(2) { |a,b| a.size <=> b.size }
          #   #=> ["Jon Starkgaryen","Daenerys"]
          def max(size=nil, &block)
            reject_values(*Daru::MISSING_VALUES).to_a.max(size, &block)
          end

          # Returns the maximum value(s) present in the vector, with a compulsory object block.
          #
          # @param size [Integer] Number of maximum values to return. Defaults to nil.
          #
          # @example
          #
          #   dv = Daru::Vector.new (["Tyrion", "Daenerys", "Jon Starkgaryen"]), index: Daru::Index.new([:t, :d, :j])
          #   #=>
          #   #   #<Daru::Vector(3)>
          #   #       t   Tyrion
          #   #       d   Daenerys
          #   #       j   Jon Starkgaryen
          #
          #   dv.max_by(2) { |i| i.size }
          #   #=> ["Jon Starkgaryen","Daenerys"]
          def max_by(size=nil, &block)
            raise ArgumentError, 'Expected compulsory object block in max_by method' unless block_given?
            reject_values(*Daru::MISSING_VALUES).to_a.max_by(size, &block)
          end

          # Returns the minimum value(s) present in the vector, with an optional comparator block.
          #
          # @param size [Integer] Number of minimum values to return. Defaults to nil.
          #
          # @example
          #
          #   dv = Daru::Vector.new (["Tyrion", "Daenerys", "Jon Starkgaryen"]), index: Daru::Index.new([:t, :d, :j])
          #   #=>
          #   #   #<Daru::Vector(3)>
          #   #       t   Tyrion
          #   #       d   Daenerys
          #   #       j   Jon Starkgaryen
          #
          #   dv.min
          #   #=> "Daenerys"
          #
          #   dv.min(2) { |a,b| a.size <=> b.size }
          #   #=> ["Tyrion","Daenerys"]
          def min(size=nil, &block)
            reject_values(*Daru::MISSING_VALUES).to_a.min(size, &block)
          end

          # Returns the minimum value(s) present in the vector, with a compulsory object block.
          #
          # @param size [Integer] Number of minimum values to return. Defaults to nil.
          #
          # @example
          #
          #   dv = Daru::Vector.new (["Tyrion", "Daenerys", "Jon Starkgaryen"]), index: Daru::Index.new([:t, :d, :j])
          #   #=>
          #   #   #<Daru::Vector(3)>
          #   #       t   Tyrion
          #   #       d   Daenerys
          #   #       j   Jon Starkgaryen
          #
          #   dv.min_by(2) { |i| i.size }
          #   #=> ["Tyrion","Daenerys"]
          def min_by(size=nil, &block)
            raise ArgumentError, 'Expected compulsory object block in min_by method' unless block_given?
            reject_values(*Daru::MISSING_VALUES).to_a.min_by(size, &block)
          end
        else
          # Returns the maximum value(s) present in the vector, with an optional comparator block.
          #
          # @param size [Integer] Number of maximum values to return. Defaults to nil.
          #
          # @example
          #
          #   dv = Daru::Vector.new (["Tyrion", "Daenerys", "Jon Starkgaryen"]), index: Daru::Index.new([:t, :d, :j])
          #   #=>
          #   #   #<Daru::Vector(3)>
          #   #       t   Tyrion
          #   #       d   Daenerys
          #   #       j   Jon Starkgaryen
          #
          #   dv.max
          #   #=> "Tyrion"
          #
          #   dv.max(2) { |a,b| a.size <=> b.size }
          #   #=> ["Jon Starkgaryen","Daenerys"]
          def max(size=nil, &block)
            range = size.nil? ? 0 : (0..size-1)
            reject_values(*Daru::MISSING_VALUES).to_a.sort(&block).reverse[range]
          end

          # Returns the maximum value(s) present in the vector, with a compulsory object block.
          #
          # @param size [Integer] Number of maximum values to return. Defaults to nil.
          #
          # @example
          #
          #   dv = Daru::Vector.new (["Tyrion", "Daenerys", "Jon Starkgaryen"]), index: Daru::Index.new([:t, :d, :j])
          #   #=>
          #   #   #<Daru::Vector(3)>
          #   #       t   Tyrion
          #   #       d   Daenerys
          #   #       j   Jon Starkgaryen
          #
          #   dv.max_by(2) { |i| i.size }
          #   #=> ["Jon Starkgaryen","Daenerys"]
          def max_by(size=nil, &block)
            raise ArgumentError, 'Expected compulsory object block in max_by method' unless block_given?
            reject_values(*Daru::MISSING_VALUES).to_a.sort_by(&block).reverse[size.nil? ? 0 : (0..size-1)]
          end

          # Returns the minimum value(s) present in the vector, with an optional comparator block.
          #
          # @param size [Integer] Number of minimum values to return. Defaults to nil.
          #
          # @example
          #
          #   dv = Daru::Vector.new (["Tyrion", "Daenerys", "Jon Starkgaryen"]), index: Daru::Index.new([:t, :d, :j])
          #   #=>
          #   #   #<Daru::Vector(3)>
          #   #       t   Tyrion
          #   #       d   Daenerys
          #   #       j   Jon Starkgaryen
          #
          #   dv.min
          #   #=> "Daenerys"
          #
          #   dv.min(2) { |a,b| a.size <=> b.size }
          #   #=> ["Tyrion","Daenerys"]
          def min(size=nil, &block)
            range = size.nil? ? 0 : (0..size-1)
            reject_values(*Daru::MISSING_VALUES).to_a.sort(&block)[range]
          end

          # Returns the minimum value(s) present in the vector, with a compulsory object block.
          #
          # @param size [Integer] Number of minimum values to return. Defaults to nil.
          #
          # @example
          #
          #   dv = Daru::Vector.new (["Tyrion", "Daenerys", "Jon Starkgaryen"]), index: Daru::Index.new([:t, :d, :j])
          #   #=>
          #   #   #<Daru::Vector(3)>
          #   #       t   Tyrion
          #   #       d   Daenerys
          #   #       j   Jon Starkgaryen
          #
          #   dv.min_by
          #   #=> "Daenerys"
          #
          #   dv.min_by(2) { |i| i.size }
          #   #=> ["Tyrion","Daenerys"]
          def min_by(size=nil, &block)
            raise ArgumentError, 'Expected compulsory object block in min_by method' unless block_given?
            reject_values(*Daru::MISSING_VALUES).to_a.sort_by(&block)[size.nil? ? 0 : (0..size-1)]
          end
        end

        # Returns the index of the maximum value(s) present in the vector, with an optional
        # comparator block.
        #
        # @param size [Integer] Number of maximum indices to return. Defaults to nil.
        #
        # @example
        #
        #   dv = Daru::Vector.new (["Tyrion", "Daenerys", "Jon Starkgaryen"]), index: Daru::Index.new([:t, :d, :j])
        #   #=>
        #   #   #<Daru::Vector(3)>
        #   #       t   Tyrion
        #   #       d   Daenerys
        #   #       j   Jon Starkgaryen
        #
        #   dv.index_of_max
        #   #=> :t
        #
        #   dv.index_of_max(2) { |a,b| a.size <=> b.size }
        #   #=> [:j, :d]
        def index_of_max(size=nil,&block)
          vals = max(size, &block)
          dv   = reject_values(*Daru::MISSING_VALUES)
          vals.is_a?(Array) ? (vals.map { |x| dv.index_of(x) }) : dv.index_of(vals)
        end

        # Returns the index of the maximum value(s) present in the vector, with a compulsory
        # object block.
        #
        # @param size [Integer] Number of maximum indices to return. Defaults to nil.
        #
        # @example
        #
        #   dv = Daru::Vector.new (["Tyrion", "Daenerys", "Jon Starkgaryen"]), index: Daru::Index.new([:t, :d, :j])
        #   #=>
        #   #   #<Daru::Vector(3)>
        #   #       t   Tyrion
        #   #       d   Daenerys
        #   #       j   Jon Starkgaryen
        #
        #   dv.index_of_max_by(2) { |i| i.size }
        #   #=> [:j, :d]
        def index_of_max_by(size=nil,&block)
          vals = max_by(size, &block)
          dv   = reject_values(*Daru::MISSING_VALUES)
          vals.is_a?(Array) ? (vals.map { |x| dv.index_of(x) }) : dv.index_of(vals)
        end

        # Returns the index of the minimum value(s) present in the vector, with an optional
        # comparator block.
        #
        # @param size [Integer] Number of minimum indices to return. Defaults to nil.
        #
        # @example
        #
        #   dv = Daru::Vector.new (["Tyrion", "Daenerys", "Jon Starkgaryen"]), index: Daru::Index.new([:t, :d, :j])
        #   #=>
        #   #   #<Daru::Vector(3)>
        #   #       t   Tyrion
        #   #       d   Daenerys
        #   #       j   Jon Starkgaryen
        #
        #   dv.index_of_min
        #   #=> :d
        #
        #   dv.index_of_min(2) { |a,b| a.size <=> b.size }
        #   #=> [:t, :d]
        def index_of_min(size=nil,&block)
          vals = min(size, &block)
          dv   = reject_values(*Daru::MISSING_VALUES)
          vals.is_a?(Array) ? (vals.map { |x| dv.index_of(x) }) : dv.index_of(vals)
        end

        # Returns the index of the minimum value(s) present in the vector, with a compulsory
        # object block.
        #
        # @param size [Integer] Number of minimum indices to return. Defaults to nil.
        #
        # @example
        #
        #   dv = Daru::Vector.new (["Tyrion", "Daenerys", "Jon Starkgaryen"]), index: Daru::Index.new([:t, :d, :j])
        #   #=>
        #   #   #<Daru::Vector(3)>
        #   #       t   Tyrion
        #   #       d   Daenerys
        #   #       j   Jon Starkgaryen
        #
        #   dv.index_of_min(2) { |i| i.size }
        #   #=> [:t, :d]
        def index_of_min_by(size=nil,&block)
          vals = min_by(size, &block)
          dv   = reject_values(*Daru::MISSING_VALUES)
          vals.is_a?(Array) ? (vals.map { |x| dv.index_of(x) }) : dv.index_of(vals)
        end

        # Return the maximum element present in the Vector, as a Vector.
        # @return [Daru::Vector]
        def max_index
          max_value = @data.max
          Daru::Vector.new({index_of(max_value) => max_value}, name: @name, dtype: @dtype)
        end

        def frequencies
          Daru::Vector.new(
            @data.each_with_object(Hash.new(0)) do |element, hash|
              hash[element] += 1 unless element.nil?
            end
          )
        end

        alias_method :freqs, :frequencies
        deprecate :freqs, :frequencies, 2016, 10

        def proportions
          len = size - count_values(*Daru::MISSING_VALUES)
          frequencies.to_h.each_with_object({}) do |(el, count), hash|
            hash[el] = count / len.to_f
          end
        end

        def ranked
          sum = 0
          r = frequencies.to_h.sort.each_with_object({}) do |(el, count), memo|
            memo[el] = ((sum + 1) + (sum + count)).quo(2)
            sum += count
          end

          recode { |e| r[e] }
        end

        def coefficient_of_variation
          standard_deviation_sample / mean
        end

        # Retrieves number of cases which comply condition. If block given,
        # retrieves number of instances where block returns true. If other
        # values given, retrieves the frequency for this value. If no value
        # given, counts the number of non-nil elements in the Vector.
        def count value=false, &block
          if block_given?
            @data.select(&block).count
          elsif value
            count { |val| val == value }
          else
            size - indexes(*Daru::MISSING_VALUES).size
          end
        end

        # Count number of occurrences of each value in the Vector
        def value_counts
          values = @data.each_with_object(Hash.new(0)) do |d, memo|
            memo[d] += 1
          end

          Daru::Vector.new(values)
        end

        def proportion value=1
          frequencies[value].quo(size - count_values(*Daru::MISSING_VALUES)).to_f
        end

        # Sample variance with denominator (N-1)
        def variance_sample m=nil
          m ||= mean
          if @data.respond_to? :variance_sample
            @data.variance_sample m
          else
            sum_of_squares(m).quo(size - count_values(*Daru::MISSING_VALUES) - 1)
          end
        end

        # Population variance with denominator (N)
        def variance_population m=nil
          m ||= mean
          if @data.respond_to? :variance_population
            @data.variance_population m
          else
            sum_of_squares(m).quo(size - count_values(*Daru::MISSING_VALUES)).to_f
          end
        end

        # Sample covariance with denominator (N-1)
        def covariance_sample other
          size == other.size or raise ArgumentError, 'size of both the vectors must be equal'
          covariance_sum(other) / (size - count_values(*Daru::MISSING_VALUES) - 1)
        end

        # Population covariance with denominator (N)
        def covariance_population other
          size == other.size or raise ArgumentError, 'size of both the vectors must be equal'
          covariance_sum(other) / (size - count_values(*Daru::MISSING_VALUES))
        end

        def sum_of_squares(m=nil)
          m ||= mean
          reject_values(*Daru::MISSING_VALUES).data.inject(0) { |memo, val|
            memo + (val - m)**2
          }
        end

        def standard_deviation_population m=nil
          m ||= mean
          if @data.respond_to? :standard_deviation_population
            @data.standard_deviation_population(m)
          else
            Math.sqrt(variance_population(m))
          end
        end

        def standard_deviation_sample m=nil
          m ||= mean
          if @data.respond_to? :standard_deviation_sample
            @data.standard_deviation_sample m
          else
            Math.sqrt(variance_sample(m))
          end
        end

        # Calculate skewness using (sigma(xi - mean)^3)/((N)*std_dev_sample^3)
        def skew m=nil
          if @data.respond_to? :skew
            @data.skew
          else
            m ||= mean
            th  = @data.inject(0) { |memo, val| memo + ((val - m)**3) }
            th.quo((size - indexes(*Daru::MISSING_VALUES).size) * (standard_deviation_sample(m)**3))
          end
        end

        def kurtosis m=nil
          if @data.respond_to? :kurtosis
            @data.kurtosis
          else
            m ||= mean
            fo  = @data.inject(0) { |a, x| a + ((x - m) ** 4) }
            fo.quo((size - indexes(*Daru::MISSING_VALUES).size) * standard_deviation_sample(m) ** 4) - 3
          end
        end

        def average_deviation_population m=nil
          must_be_numeric!
          m ||= mean
          reject_values(*Daru::MISSING_VALUES).data.inject(0) { |memo, val|
            (val - m).abs + memo
          }.quo(size - count_values(*Daru::MISSING_VALUES))
        end

        # Returns the value of the percentile q
        #
        # Accepts an optional second argument specifying the strategy to interpolate
        # when the requested percentile lies between two data points a and b
        # Valid strategies are:
        # * :midpoint (Default): (a + b) / 2
        # * :linear : a + (b - a) * d where d is the decimal part of the index between a and b.
        # == References
        #
        # This is the NIST recommended method (http://en.wikipedia.org/wiki/Percentile#NIST_method)
        def percentile(q, strategy=:midpoint)
          case strategy
          when :midpoint
            midpoint_percentile(q)
          when :linear
            linear_percentile(q)
          else
            raise ArgumentError, "Unknown strategy #{strategy}"
          end
        end

        # Dichotomize the vector with 0 and 1, based on lowest value.
        # If parameter is defined, this value and lower will be 0
        # and higher, 1.
        def dichotomize(low=nil)
          low ||= factors.min

          recode do |x|
            if x.nil?
              nil
            elsif x > low
              1
            else
              0
            end
          end
        end

        # Center data by subtracting the mean from each non-nil value.
        def center
          self - mean
        end

        # Standardize data.
        #
        # == Arguments
        #
        # * use_population - Pass as *true* if you want to use population
        # standard deviation instead of sample standard deviation.
        def standardize use_population=false
          m ||= mean
          sd = use_population ? sdp : sds
          return Daru::Vector.new([nil]*size) if m.nil? || sd == 0.0

          vector_standardized_compute m, sd
        end

        # :nocov:
        def box_cox_transformation lambda # :nodoc:
          must_be_numeric!

          recode do |x|
            if !x.nil?
              if lambda.zero?
                Math.log(x)
              else
                (x ** lambda - 1).quo(lambda)
              end
            else
              nil
            end
          end
        end
        # :nocov:

        # Replace each non-nil value in the vector with its percentile.
        def vector_percentile
          c = size - indexes(*Daru::MISSING_VALUES).size
          ranked.recode! { |i| i.nil? ? nil : (i.quo(c)*100).to_f }
        end

        def vector_standardized_compute(m,sd)
          if @data.respond_to? :vector_standardized_compute
            @data.vector_standardized_compute(m,sd)
          else
            Daru::Vector.new @data.collect { |x| x.nil? ? nil : (x.to_f - m).quo(sd) },
              index: index, name: name, dtype: dtype
          end
        end

        def vector_centered_compute(m)
          if @data.respond_to? :vector_centered_compute
            @data.vector_centered_compute(m)
          else
            Daru::Vector.new @data.collect { |x| x.nil? ? nil : x.to_f-m },
              index: index, name: name, dtype: dtype
          end
        end

        # Returns an random sample of size n, with replacement,
        # only with non-nil data.
        #
        # In all the trails, every item have the same probability
        # of been selected.
        def sample_with_replacement(sample=1)
          if @data.respond_to? :sample_with_replacement
            @data.sample_with_replacement sample
          else
            valid = indexes(*Daru::MISSING_VALUES).empty? ? self : reject_values(*Daru::MISSING_VALUES)
            vds = valid.size
            (0...sample).collect { valid[rand(vds)] }
          end
        end

        # Returns an random sample of size n, without replacement,
        # only with valid data.
        #
        # Every element could only be selected once.
        #
        # A sample of the same size of the vector is the vector itself.
        def sample_without_replacement(sample=1)
          if @data.respond_to? :sample_without_replacement
            @data.sample_without_replacement sample
          else
            raw_sample_without_replacement(sample)
          end
        end

        # The percent_change method computes the percent change over
        # the given number of periods.
        #
        # @param [Integer] periods (1) number of nils to insert at the beginning.
        #
        # @example
        #
        #   vector = Daru::Vector.new([4,6,6,8,10],index: ['a','f','t','i','k'])
        #   vector.percent_change
        #   #=>
        #   #   <Daru::Vector:28713060 @name = nil size: 5 >
        #   #              nil
        #   #   a
        #   #   f	   0.5
        #   #   t	   0.0
        #   #   i	   0.3333333333333333
        #   #   k          0.25
        def percent_change periods=1
          must_be_numeric!

          prev = nil
          arr = @data.each_with_index.map do |cur, i|
            if i < periods ||
               include_with_nan?(Daru::MISSING_VALUES, cur) ||
               include_with_nan?(Daru::MISSING_VALUES, prev)
              nil
            else
              (cur - prev) / prev.to_f
            end.tap { prev = cur if cur }
          end

          Daru::Vector.new(arr, index: @index, name: @name)
        end

        # Performs the difference of the series.
        # Note: The first difference of series is X(t) - X(t-1)
        # But, second difference of series is NOT X(t) - X(t-2)
        # It is the first difference of the first difference
        # => (X(t) - X(t-1)) - (X(t-1) - X(t-2))
        #
        # == Arguments
        #
        # * *max_lags*: integer, (default: 1), number of differences reqd.
        #
        # @example Using #diff
        #
        #   ts = Daru::Vector.new((1..10).map { rand })
        #            # => [0.69, 0.23, 0.44, 0.71, ...]
        #
        #   ts.diff   # => [nil, -0.46, 0.21, 0.27, ...]
        #
        # @return [Daru::Vector]
        def diff(max_lags=1)
          ts = self
          difference = []
          max_lags.times do
            difference = ts - ts.lag
            ts = difference
          end
          difference
        end

        # Calculate the rolling function for a loopback value.
        #
        # @param [Symbol] function The rolling function to be applied. Can be
        #   any function applicatble to Daru::Vector (:mean, :median, :count,
        #   :min, :max, etc.)
        # @param [Integer] n (10) A non-negative value which serves as the loopback length.
        # @return [Daru::Vector] Vector containin rolling calculations.
        # @example Using #rolling
        #   ts = Daru::Vector.new((1..100).map { rand })
        #            # => [0.69, 0.23, 0.44, 0.71, ...]
        #   # first 9 observations are nil
        #   ts.rolling(:mean)    # => [ ... nil, 0.484... , 0.445... , 0.513 ... , ... ]
        def rolling function, n=10
          Daru::Vector.new(
            [nil] * (n - 1) +
            (0..(size - n)).map do |i|
              Daru::Vector.new(@data[i...(i + n)]).send(function)
            end, index: @index
          )
        end

        # @!method rolling_mean
        #   Calculate rolling average
        #   @yieldparam [Integer] n (10) Loopback length
        # @!method rolling_median
        #   Calculate rolling median
        #   @yieldparam [Integer] n (10) Loopback length
        # @!method rolling_count
        #   Calculate rolling non-missing count
        #   @yieldparam [Integer] n (10) Loopback length
        # @!method rolling_max
        #   Calculate rolling max value
        #   @yieldparam [Integer] n (10) Loopback length
        # @!method rolling_min
        #   Calculate rolling min value
        #   @yieldparam [Integer] n (10) Loopback length
        # @!method rolling_sum
        #   Calculate rolling sum
        #   @yieldparam [Integer] n (10) Loopback length
        # @!method rolling_std
        #   Calculate rolling standard deviation
        #   @yieldparam [Integer] n (10) Loopback length
        # @!method rolling_variance
        #   Calculate rolling variance
        #   @yieldparam [Integer] n (10) Loopback length
        %i[count mean median max min sum std variance].each do |meth|
          define_method("rolling_#{meth}".to_sym) do |n=10|
            rolling(meth, n)
          end
        end

        # Exponential Moving Average.
        # Calculates an exponential moving average of the series using a
        # specified parameter. If wilder is false (the default) then the EMA
        # uses a smoothing value of 2 / (n + 1), if it is true then it uses the
        # Welles Wilder smoother of 1 / n.
        #
        # Warning for EMA usage: EMAs are unstable for small series, as they
        # use a lot more than n observations to calculate. The series is stable
        # if the size of the series is >= 3.45 * (n + 1)
        #
        # @param [Integer] n (10) Loopback length.
        # @param [TrueClass, FalseClass] wilder (false) If true, 1/n value is
        #   used for smoothing; if false, uses 2/(n+1) value
        #
        # @example Using ema
        #
        #   ts = Daru::Vector.new((1..100).map { rand })
        #            # => [0.577..., 0.123..., 0.173..., 0.233..., ...]
        #
        #   # first 9 observations are nil
        #   ts.ema   # => [ ... nil, 0.455... , 0.395..., 0.323..., ... ]
        #
        # @return [Daru::Vector] Contains EMA
        def ema(n=10, wilder=false) # rubocop:disable Metrics/AbcSize
          smoother = wilder ? 1.0 / n : 2.0 / (n + 1)
          # need to start everything from the first non-nil observation
          start = @data.index { |i| !i.nil? }
          # first n - 1 observations are nil
          base = [nil] * (start + n - 1)
          # nth observation is just a moving average
          base << @data[start...(start + n)].inject(0.0) { |s, a| a.nil? ? s : s + a } / n
          (start + n).upto size - 1 do |i|
            base << self[i] * smoother + (1 - smoother) * base.last
          end

          Daru::Vector.new(base, index: @index, name: @name)
        end

        # Exponential Moving Variance.
        # Calculates an exponential moving variance of the series using a
        # specified parameter. If wilder is false (the default) then the EMV
        # uses a smoothing value of 2 / (n + 1), if it is true then it uses the
        # Welles Wilder smoother of 1 / n.
        #
        # @param [Integer] n (10) Loopback length.
        # @param [TrueClass, FalseClass] wilder (false) If true, 1/n value is
        #   used for smoothing; if false, uses 2/(n+1) value
        #
        # @example Using emv
        #
        #   ts = Daru::Vector.new((1..100).map { rand })
        #            # => [0.047..., 0.23..., 0.836..., 0.845..., ...]
        #
        #   # first 9 observations are nil
        #   ts.emv   # => [ ... nil, 0.073... , 0.082..., 0.080..., ...]
        #
        # @return [Daru::Vector] contains EMV
        def emv(n=10, wilder=false) # rubocop:disable Metrics/AbcSize
          smoother = wilder ? 1.0 / n : 2.0 / (n + 1)
          # need to start everything from the first non-nil observation
          start = @data.index { |i| !i.nil? }
          # first n - 1 observations are nil
          var_base = [nil] * (start + n - 1)
          mean_base = [nil] * (start + n - 1)
          mean_base << @data[start...(start + n)].inject(0.0) { |s, a| a.nil? ? s : s + a } / n
          # nth observation is just a moving variance_population
          var_base << @data[start...(start + n)].inject(0.0) { |s,x| x.nil? ? s : s + (x - mean_base.last)**2 } / n
          (start + n).upto size - 1 do |i|
            last = mean_base.last
            mean_base << self[i] * smoother + (1 - smoother) * last
            var_base << (1 - smoother) * var_base.last + smoother * (self[i] - last) * (self[i] - mean_base.last)
          end
          Daru::Vector.new(var_base, index: @index, name: @name)
        end

        # Exponential Moving Standard Deviation.
        # Calculates an exponential moving standard deviation of the series using a
        # specified parameter. If wilder is false (the default) then the EMSD
        # uses a smoothing value of 2 / (n + 1), if it is true then it uses the
        # Welles Wilder smoother of 1 / n.
        #
        # @param [Integer] n (10) Loopback length.
        # @param [TrueClass, FalseClass] wilder (false) If true, 1/n value is
        #   used for smoothing; if false, uses 2/(n+1) value
        #
        # @example Using emsd
        #
        #   ts = Daru::Vector.new((1..100).map { rand })
        #            # => [0.400..., 0.727..., 0.862..., 0.013..., ...]
        #
        #   # first 9 observations are nil
        #   ts.emsd   # => [ ... nil, 0.285... , 0.258..., 0.243..., ...]
        #
        # @return [Daru::Vector] contains EMSD
        def emsd(n=10, wilder=false)
          result = []
          emv_return = emv(n, wilder)
          emv_return.each do |d|
            result << (d.nil? ? nil : Math.sqrt(d))
          end
          Daru::Vector.new(result, index: @index, name: @name)
        end

        # Moving Average Convergence-Divergence.
        # Calculates the MACD (moving average convergence-divergence) of the time
        # series.
        # @see https://en.wikipedia.org/wiki/MACD
        #
        # @param fast [Integer] fast period of MACD (default 12)
        # @param slow [Integer] slow period of MACD (default 26)
        # @param signal [Integer] signal period of MACD (default 9)
        #
        # @example Create a series and calculate MACD values
        #   ts = Daru::Vector.new((1..100).map { rand })
        #            # => [0.69, 0.23, 0.44, 0.71, ...]
        #   macdseries, macdsignal, macdhist = ts.macd
        #   macdseries, macdsignal, macdhist = ts.macd(13)
        #   macdseries, macdsignal, macdhist = ts.macd(signal=5)
        #
        # @return [Array<Daru::Vector>] macdseries, macdsignal and macdhist are
        #   returned as an array of three Daru::Vectors
        #
        def macd(fast=12, slow=26, signal=9)
          macdseries = ema(fast) - ema(slow)
          macdsignal = macdseries.ema(signal)
          macdhist = macdseries - macdsignal
          [macdseries, macdsignal, macdhist]
        end

        # Calculates the autocorrelation coefficients of the series.
        #
        # The first element is always 1, since that is the correlation
        # of the series with itself.
        #
        # @example
        #   ts = Daru::Vector.new((1..100).map { rand })
        #
        #   ts.acf   # => array with first 21 autocorrelations
        #   ts.acf 3 # => array with first 3 autocorrelations
        def acf(max_lags=nil)
          max_lags ||= (10 * Math.log10(size)).to_i

          (0..max_lags).map do |i|
            if i.zero?
              1.0
            else
              m = mean
              # can't use Pearson coefficient since the mean for the lagged series should
              # be the same as the regular series
              ((self - m) * (lag(i) - m)).sum / variance_sample / (size - 1)
            end
          end
        end

        # Provides autocovariance.
        #
        # == Options
        #
        # * *:demean* = true; optional. Supply false if series is not to be demeaned
        # * *:unbiased* = true; optional. true/false for unbiased/biased form of autocovariance
        #
        # == Returns
        #
        # Autocovariance value
        def acvf(demean=true, unbiased=true) # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
          opts = {
            demean: true,
            unbaised: true
          }.merge(opts)

          demean   = opts[:demean]
          unbiased = opts[:unbiased]
          demeaned_series = demean ? self - mean : self

          n = (10 * Math.log10(size)).to_i + 1
          m = mean
          d = if unbiased
                Array.new(size, size)
              else
                (1..size).to_a.reverse[0..n]
              end

          0.upto(n - 1).map do |i|
            (demeaned_series * (lag(i) - m)).sum / d[i]
          end
        end

        # Calculate cumulative sum of Vector
        def cumsum
          result = []
          acc = 0
          @data.each do |d|
            if include_with_nan? Daru::MISSING_VALUES, d
              result << nil
            else
              acc += d
              result << acc
            end
          end

          Daru::Vector.new(result, index: @index)
        end

        alias :sdp :standard_deviation_population
        alias :sds :standard_deviation_sample
        alias :std :sds
        alias :adp :average_deviation_population
        alias :cov :coefficient_of_variation
        alias :variance :variance_sample
        alias :covariance :covariance_sample
        alias :sd :standard_deviation_sample
        alias :ss :sum_of_squares
        alias :percentil :percentile
        alias :se :standard_error

        private

        def must_be_numeric!
          numeric? or raise TypeError, 'Vector must be numeric'
        end

        def covariance_sum other
          self_mean = mean
          other_mean = other.mean
          @data
            .zip(other.data).inject(0) do |res, (d, o)|
              res + if !d || !o
                      0
                    else
                      (d - self_mean) * (o - other_mean)
                    end
            end
        end

        def midpoint_percentile(q) # rubocop:disable Metrics/AbcSize
          sorted = reject_values(*Daru::MISSING_VALUES).to_a.sort

          v = ((size - count_values(*Daru::MISSING_VALUES)) * q).quo(100)
          if v.to_i!=v
            sorted[v.to_i]
          else
            (sorted[(v-0.5).to_i].to_f + sorted[(v+0.5).to_i]).quo(2)
          end
        end

        def linear_percentile(q) # rubocop:disable Metrics/AbcSize
          sorted = reject_values(*Daru::MISSING_VALUES).to_a.sort
          index = (q / 100.0) * ((size - count_values(*Daru::MISSING_VALUES)) + 1)

          k = index.truncate
          d = index % 1

          if k.zero?
            sorted[0]
          elsif k >= sorted.size
            sorted[-1]
          else
            sorted[k - 1] + d * (sorted[k] - sorted[k - 1])
          end
        end

        def raw_sample_without_replacement sample
          valid = indexes(*Daru::MISSING_VALUES).empty? ? self : reject_values(*Daru::MISSING_VALUES)
          raise ArgumentError, "Sample size couldn't be greater than n" if
            sample > valid.size
          out  = []
          size = valid.size
          while out.size < sample
            value = rand(size)
            out.push(value) unless out.include?(value)
          end

          out.collect { |i| valid[i] }
        end
      end
    end
  end
end
