module Daru
  module Math
    module Statistics
      module Vector

        extend Forwardable

        def_delegators :@vector, :mean, :sum ,:product ,:standard_error,
          :sum_of_squared_deviation,:max,:min,:has_missing_data?, :range

        %w{ variance_population 
            variance_sample 
            sum_of_squares 
            standard_deviation_sample
            standard_deviation_population
            skew
            kurtosis
          }.each do |meth|
          define_method(meth) { |mean = nil| @vector.send(meth, mean)}
        end

        def recode!(&block)
          @vector.recode!(&block)
        end

        alias_method :sdp, :standard_deviation_population
        alias_method :sds, :standard_deviation_sample
        # alias_method :adp, :average_deviation_population
        # alias_method :cov, :coefficient_of_variation
        # alias_method :variance, :variance_sample    
        alias_method :sd, :standard_deviation_sample
        alias_method :ss, :sum_of_squares
      end
    end
  end
end