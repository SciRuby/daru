module Daru
  module Math
    module Statistics
      module Vector
        def average_deviation_population m=nil
          @vector.average_deviation_population m
        end

        def coefficient_of_variation
          @vector.coefficient_of_variation
        end

        def count x=false
          @vector.count x
        end

        def factors
          @vector.factors
        end

        def frequencies
          @vector.frequencies
        end

        def has_missing_data?
          @vector.has_missing_data?
        end

        def is_valid?
          @vector.is_valid?
        end

        def kurtosis(m=nil)
          @vector.kurtosis m
        end

        def mean
          @vector.mean
        end

        def median
          @vector.median
        end

        def median_absolute_deviation
          @vector.median_absolute_deviation
        end

        def mode
          @vector.mode
        end

        def == other
          @vector == other
        end

        def n_valid
          @vector.n_valid
        end

        def percentile percent
          @vector.percentil percent
        end

        def product
          @vector.product
        end

        def proportion val=1
          @vector.proportion val
        end

        def proportions
          @vector.proportions
        end

        def range
          @vector.range
        end

        def ranked
          @vector.ranked
        end

        def recode &block
          @vector.recode &block
        end

        def recode! &block
          @vector.recode! &block
        end

        def skew m=nil
          @vector.skew m
        end

        def standard_deviation_population m=nil
          @vector.standard_deviation_population m
        end

        def standard_deviation_sample m=nil
          @vector.standard_deviation_sample m
        end

        def standard_error
          @vector.standard_error
        end

        def sum_of_squared_deviation
          @vector.sum_of_squared_deviation
        end

        def sum_of_squares m=nil
          @vector.sum_of_squares m
        end

        def sum
          @vector.sum
        end

        def variance_sample m=nil
          @vector.variance_sample m
        end
      end
    end
  end
end