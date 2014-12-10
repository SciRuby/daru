module Daru
  module Maths
    module Statistics
      module Vector

        def mean
          @vector.mean
        end

        def median
          @vector.median
        end

        def mode
          @vector.mode
        end

        def sum
          @vector.sum
        end

        def product
          @vector.product
        end

        def median_absolute_deviation
          @vector.median_absolute_deviation  
        end

        def standard_error
          @vector.standard_error
        end

        def sum_of_squared_deviation
          @vector.sum_of_squared_deviation
        end

        # Maximum element of the vector.
        # 
        # @param return_type [Symbol] Data type of the returned value. Defaults
        #   to returning only the maximum number but passing *:vector* will return
        #   a Daru::Vector with the index of the corresponding maximum value.
        def max return_type=:stored_type
          max_value = @vector.max
          if return_type == :vector
            Daru::Vector.new({index_of(max_value) => max_value}, name: @name, dtype: @dtype)
          else
            max_value
          end
        end

        # Return a Vector with the max element and its index.
        # @return [Daru::Vector]
        def max_index
          max :vector
        end

        def min
          @vector.min
        end

        def has_missing_data?
          @vector.has_missing_data?
        end

        def range
          @vector.range
        end

        def frequencies
          @vector.frequencies
        end

        def proportions
          @vector.proportions
        end

        def ranked
          @vector.ranked
        end

        def coefficient_of_variation
          @vector.coefficient_of_variation
        end

        # Retrieves number of cases which comply condition.
        # If block given, retrieves number of instances where
        # block returns true.
        # If other values given, retrieves the frequency for
        # this value.
        def count value=false
          @vector.count value
        end

        def proportion value=1
          @vector.proportion value
        end

        # Population variance with denominator (N)
        def variance_population m=nil
          @vector.variance_population m
        end

        # Sample variance with denominator (N-1)
        def variance_sample m=nil
          @vector.variance_sample m
        end

        def sum_of_squares m=nil
          @vector.sum_of_squares m
        end

        def standard_deviation_sample m=nil
          @vector.standard_deviation_sample m
        end

        def standard_deviation_population m=nil
          @vector.standard_deviation_population m
        end

        # Calculate skewness using (sigma(xi - mean)^3)/((N)*std_dev_sample^3)
        def skew m=nil
          @vector.skew m
        end

        def kurtosis m=nil
          @vector.kurtosis m
        end

        def average_deviation_population m=nil
          @vector.average_deviation_population m
        end

        def recode!(&block)
          @vector.recode!(&block)
        end

        def percentile percent
          @vector.percentile percent
        end

        alias_method :sdp, :standard_deviation_population
        alias_method :sds, :standard_deviation_sample
        alias_method :adp, :average_deviation_population
        # alias_method :cov, :coefficient_of_variation
        # alias_method :variance, :variance_sample    
        alias_method :sd, :standard_deviation_sample
        alias_method :ss, :sum_of_squares
        alias_method :percentil, :percentile
      end
    end
  end
end