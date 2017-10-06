module Daru
  module Maths
    module Statistics
      module DataFrame
        # @!method mean
        #   Calculate mean of numeric vectors
        # @!method variance_sample
        #   Calculate sample variance of numeric vectors
        # @!method range
        #   Calculate range of numeric vectors
        # @!method median
        #   Calculate median of numeric vectors
        # @!method mode
        #   Calculate mode of numeric vectors
        # @!method std
        #   Calculate sample standard deviation of numeric vectors
        # @!method sum
        #   Calculate sum of numeric vectors
        # @!method count
        #   Count the number of non-nil values in each vector
        # @!method min
        #   Calculate the minimum value of each numeric vector
        # @!method product
        #   Compute the product of each numeric vector
        %i[mean variance_sample range median mode std sum count min product].each do |meth|
          define_method(meth) do
            compute_stats meth
          end
        end

        # Calculate the maximum value of each numeric vector.
        def max opts={}
          if opts[:vector]
            row[*self[opts[:vector]].max_index.index.to_a]
          else
            compute_stats :max
          end
        end

        # @!method cumsum
        #   Calculate cumulative sum of each numeric Vector
        # @!method standardize
        #   Standardize each Vector
        # @!method acf(max_lags)
        #   Calculate Autocorrelation coefficient
        #   @param max_lags [Integer] (nil) Number of initial lags
        # @!method ema(n,wilder)
        #   Calculate exponential moving average.
        #   @param n [Integer] (10) Loopback length.
        #   @param wilder [TrueClass, FalseClass, NilClass] (false) If true,
        #     1/n value is  used for smoothing; if false, uses 2/(n+1) value.
        # @!method rolling_mean(n)
        #   Calculate moving averages
        #   @param n [Integer] (10) Loopback length. Default to 10.
        # @!method rolling_median(n)
        #   Calculate moving median
        #   @param n [Integer] (10) Loopback length. Default to 10.
        # @!method rolling_max(n)
        #   Calculate moving max
        #   @param n [Integer] (10) Loopback length. Default to 10.
        # @!method rolling_min(n)
        #   Calculate moving min
        #   @param n [Integer] (10) Loopback length. Default to 10.
        # @!method rolling_count(n)
        #   Calculate moving non-missing count
        #   @param n [Integer] (10) Loopback length. Default to 10.
        # @!method rolling_std(n)
        #   Calculate moving standard deviation
        #   @param n [Integer] (10) Loopback length. Default to 10.
        # @!method rolling_variance(n)
        #   Calculate moving variance
        #   @param n [Integer] (10) Loopback length. Default to 10.
        %i[
          cumsum standardize acf ema rolling_mean rolling_median rolling_max
          rolling_min rolling_count rolling_std rolling_variance rolling_sum
        ].each do |meth|
          define_method(meth) do |*args|
            apply_method_to_numerics meth, *args
          end
        end

        # Create a summary of mean, standard deviation, count, max and min of
        # each numeric vector in the dataframe in one shot.
        #
        # == Arguments
        #
        # +methods+ - An array with aggregation methods specified as symbols to
        # be applied to numeric vectors. Default is [:count, :mean, :std, :max,
        # :min]. Methods will be applied in the specified order.
        def describe methods=nil
          methods ||= %i[count mean std min max]

          description_hash = {}
          numeric_vectors.each do |vec|
            description_hash[vec] = methods.map { |m| self[vec].send(m) }
          end
          Daru::DataFrame.new(description_hash, index: methods)
        end

        # The percent_change method computes the percent change over
        # the given number of periods for numeric vectors.
        #
        # @param [Integer] periods (1) number of nils to insert at the beginning.
        #
        # @example
        #
        #   df = Daru::DataFrame.new({
        #        'col0' => [1,2,3,4,5,6],
        #        'col2' => ['a','b','c','d','e','f'],
        #        'col1' => [11,22,33,44,55,66]
        #        },
        #        index: ['one', 'two', 'three', 'four', 'five', 'six'],
        #        order: ['col0', 'col1', 'col2'])
        #   df.percent_change
        #   #=>
        #   #   <Daru::DataFrame:23513280 @rows: 6 @cols: 2>
        #   #              col0                col1
        #   #   one
        #   #   two	   1.0	               1.0
        #   #   three	   0.5                 0.5
        #   #   four	   0.3333333333333333  0.3333333333333333
        #   #   five       0.25                0.25
        #   #   six        0.2                 0.2
        def percent_change periods=1
          df_numeric = only_numerics.vectors.to_a
          df = Daru::DataFrame.new({}, order: @order, index: @index, name: @name)
          df_numeric.each do |vec|
            df[vec] = self[vec].percent_change periods
          end
          df
        end

        # Calculate sample variance-covariance between the numeric vectors.
        def covariance
          cache = Hash.new do |h, (col, row)|
            value = vector_cov(self[row],self[col])
            h[[col, row]] = value
            h[[row, col]] = value
          end
          vectors = numeric_vectors

          mat_rows = vectors.collect do |row|
            vectors.collect do |col|
              row == col ? self[row].variance : cache[[col,row]]
            end
          end

          Daru::DataFrame.rows(mat_rows, index: numeric_vectors, order: numeric_vectors)
        end

        alias :cov :covariance

        # Calculate the correlation between the numeric vectors.
        def correlation
          standard_deviation = std.to_matrix
          corr_arry = cov
                      .to_matrix
                      .elementwise_division(standard_deviation.transpose *
            standard_deviation).to_a

          Daru::DataFrame.rows(corr_arry, index: numeric_vectors, order: numeric_vectors)
        end

        alias :corr :correlation

        private

        def apply_method_to_numerics method, *args
          numerics = @vectors.to_a.map { |n| [n, @data[@vectors[n]]] }
                             .select { |_n, v| v.numeric? }
          computed = numerics.map { |_n, v| v.send(method, *args) }

          Daru::DataFrame.new(computed, index: @index, order: numerics.map(&:first), clone: false)
        end

        def vector_cov v1a, v2a
          sum_of_squares(v1a,v2a) / (v1a.size - 1)
        end

        def sum_of_squares v1, v2
          v1a,v2a = v1.reject_values(*Daru::MISSING_VALUES),v2.reject_values(*Daru::MISSING_VALUES)
          v1a.reset_index!
          v2a.reset_index!
          m1 = v1a.mean
          m2 = v2a.mean
          v1a.size.times.inject(0) { |ac,i| ac+(v1a[i]-m1)*(v2a[i]-m2) }
        end

        def compute_stats method
          Daru::Vector.new(
            numeric_vectors.each_with_object({}) do |vec, hash|
              hash[vec] = self[vec].send(method)
            end, name: method
          )
        end
        alias :sds :std
        alias :variance :variance_sample
      end
    end
  end
end
