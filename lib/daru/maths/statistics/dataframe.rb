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
        [:mean, :variance_sample, :range, :median, :mode, :std, :sum, :count, :min, :product].each do |meth|
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
        # @!method acf
        #   Calculate Autocorrelation coefficient
        #   @param [Integer] max_lags (nil) Number of initial lags
        # @!method ema
        #   Calculate exponential moving average.
        #   @param [Integer] n (10) Loopback length.
        #   @param [TrueClass, FalseClass, NilClass] wilder (false) If true,
        #     1/n value is  used for smoothing; if false, uses 2/(n+1) value.
        # @!method rolling_mean
        #   Calculate moving averages
        #   @param [Integer] n (10) Loopback length. Default to 10.
        # @!method rolling_median
        #   Calculate moving median
        #   @param [Integer] n (10) Loopback length. Default to 10.
        # @!method rolling_max
        #   Calculate moving max
        #   @param [Integer] n (10) Loopback length. Default to 10.
        # @!method rolling_min
        #   Calculate moving min
        #   @param [Integer] n (10) Loopback length. Default to 10.
        # @!method rolling_count
        #   Calculate moving non-missing count
        #   @param [Integer] n (10) Loopback length. Default to 10.
        # @!method rolling_std
        #   Calculate moving standard deviation
        #   @param [Integer] n (10) Loopback length. Default to 10.
        # @!method rolling_variance
        #   Calculate moving variance
        #   @param [Integer] n (10) Loopback length. Default to 10.
        [
          :cumsum,:standardize,:acf,:ema,:rolling_mean,:rolling_median,:rolling_max,
          :rolling_min,:rolling_count,:rolling_std,:rolling_variance, :rolling_sum
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
          methods ||= [:count, :mean, :std, :min, :max]

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
          cache={}
          vectors = numeric_vectors

          mat_rows = vectors.collect do |row|
            vectors.collect do |col|
              if row == col
                self[row].variance
              elsif cache[[col,row]].nil?
                cov = vector_cov(self[row],self[col])
                cache[[row,col]] = cov
                cov
              else
                cache[[col,row]]
              end
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
          order = []
          computed = @vectors.to_a.each_with_object([]) do |n, memo|
            v = @data[@vectors[n]]
            if v.type == :numeric
              memo << v.send(method, *args)
              order << n
            end
          end

          Daru::DataFrame.new(computed, index: @index, order: order,clone: false)
        end

        def vector_cov v1a, v2a
          sum_of_squares(v1a,v2a) / (v1a.size - 1)
        end

        def sum_of_squares v1, v2
          v1a,v2a = v1.only_valid,v2.only_valid
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
