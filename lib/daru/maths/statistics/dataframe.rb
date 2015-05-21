module Daru
  module Maths
    module Statistics
      module DataFrame
        # Calculate mean of numeric vectors.
        def mean
          compute_stats :mean
        end

        # Calculate sample standard deviation of numeric vectors.
        def std
          compute_stats :std
        end

        # Calculate sum of numeric vectors
        def sum
          compute_stats :sum
        end

        # Count the number of non-nil values in each vector.
        def count
          compute_stats :count
        end

        # Calculate the maximum value of each numeric vector.
        def max
          compute_stats :max
        end

        # Calculate the minimmum value of each numeric vector.
        def min
          compute_stats :min
        end

        # Compute the product of each numeric vector.
        def product
          compute_stats :product
        end

        def standardize
          df = self.only_numerics clone: true
          df.map! do |v|
            v.standardize
          end

          df
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

        # Calculate variance-covariance between the numeric vectors.
        # 
        # == Arguments
        # 
        # +for_sample_data+ - If set to false, will calculate the population 
        # covariance (denominator N), otherwise calculates the sample covariance
        # matrix. Default to true.
        def covariance for_sample_data=true
          cov_arry = 
          if defined? NMatrix and NMatrix.respond_to?(:cov)
            to_nmatrix.cov(for_sample_data).to_a
          else
            df_as_matrix = to_matrix
            denominator  = for_sample_data ? nrows - 1 : nrows
            ones         = ::Matrix.column_vector [1]*nrows
            deviation_scores = df_as_matrix - (ones * ones.transpose * df_as_matrix) / nrows
            ((deviation_scores.transpose * deviation_scores) / denominator).to_a
          end

          Daru::DataFrame.rows(cov_arry, index: numeric_vectors, order: numeric_vectors)
        end

        alias :cov :covariance
          
        # Calculate the correlation between the numeric vectors.
        def correlation
          corr_arry = 
          if defined? NMatrix and NMatrix.respond_to?(:corr)
            to_nmatrix.corr.to_a
          else
            standard_deviation = std.to_matrix
            (cov.to_matrix.elementwise_division(standard_deviation.transpose * 
              standard_deviation)).to_a
          end

          Daru::DataFrame.rows(corr_arry, index: numeric_vectors, order: numeric_vectors)
        end

        alias :corr :correlation

       private

        def compute_stats method
          Daru::Vector.new(
            numeric_vectors.inject({}) do |hash, vec|
              hash[vec] = self[vec].send(method)
              hash
            end
          )
        end
      end
    end
  end
end