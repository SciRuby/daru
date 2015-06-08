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

        # Calculate sample variance-covariance between the numeric vectors.
        def covariance
          cache={}
          vectors = self.numeric_vectors

          mat_rows = vectors.collect do |row|
            vectors.collect do |col|
              if row == col
                self[row].variance
              else
                if cache[[col,row]].nil?
                  cov = vector_cov(self[row],self[col])
                  cache[[row,col]] = cov
                  cov
                else
                  cache[[col,row]]
                end
              end
            end
          end

          Daru::DataFrame.rows(mat_rows, index: numeric_vectors, order: numeric_vectors)
        end

        alias :cov :covariance
          
        # Calculate the correlation between the numeric vectors.
        def correlation
          standard_deviation = std.to_matrix
          corr_arry = (cov
            .to_matrix
            .elementwise_division(standard_deviation.transpose * 
            standard_deviation)).to_a

          Daru::DataFrame.rows(corr_arry, index: numeric_vectors, order: numeric_vectors)
        end

        alias :corr :correlation

       private

        def vector_cov v1a, v2a
          sum_of_squares(v1a,v2a) / (v1a.size - 1)
        end

        def sum_of_squares v1, v2
          v1a,v2a = v1.only_valid ,v2.only_valid
          v1a.reset_index!
          v2a.reset_index!        
          m1 = v1a.mean
          m2 = v2a.mean
          (v1a.size).times.inject(0) {|ac,i| ac+(v1a[i]-m1)*(v2a[i]-m2)}
        end

        def compute_stats method
          Daru::Vector.new(
            numeric_vectors.inject({}) do |hash, vec|
              hash[vec] = self[vec].send(method)
              hash
            end, name: method
          )
        end
      end
    end
  end
end