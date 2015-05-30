module Daru
  module Maths
    # Encapsulates statistics methods for vectors. Most basic stuff like mean, etc.
    # is done inside the wrapper, so that native methods can be used for most of 
    # the computationally intensive tasks.
    module Statistics
      module Vector
        def mean
          @data.mean
        end

        def sum
          @data.sum
        end

        def product
          @data.product
        end

        def min
          @data.min
        end

        def range
          max - min
        end

        def median
          @data.respond_to?(:median) ? @data.median : percentile(50)
        end

        def mode
          freqs = frequencies.values
          @data[freqs.index(freqs.max)]
        end

        def median_absolute_deviation
          m = median
          recode {|val| (val - m).abs }.median
        end
        alias :mad :median_absolute_deviation

        def standard_error
          standard_deviation_sample/(Math::sqrt((n_valid)))
        end

        def sum_of_squared_deviation
          (@data.inject(0) { |a,x| x.square + a } - (sum.square.quo(n_valid)).to_f).to_f
        end

        # Retrieve unique values of non-nil data
        def factors
          only_valid.uniq
        end

        # Maximum element of the vector.
        # 
        # @param return_type [Symbol] Data type of the returned value. Defaults
        #   to returning only the maximum number but passing *:vector* will return
        #   a Daru::Vector with the index of the corresponding maximum value.
        def max return_type=:stored_type
          max_value = @data.max
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

        def frequencies
          @data.inject({}) do |hash, element|
            unless element.nil?
              hash[element] ||= 0
              hash[element] += 1
            end
            hash
          end
        end

        def proportions
          len = n_valid
          frequencies.inject({}) { |hash, arr| hash[arr[0]] = arr[1] / len; hash }
        end

        def ranked
          sum = 0
          r = frequencies.sort.inject( {} ) do |memo, val|
            memo[val[0]] = ((sum + 1) + (sum + val[1])).quo(2)
            sum += val[1]
            memo
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
        def count value=false
          if block_given?
            @data.inject(0){ |memo, val| memo += 1 if yield val; memo}
          elsif value
            val = frequencies[value]
            val.nil? ? 0 : val
          else
            size - @missing_positions.size
          end
        end

        def proportion value=1
          frequencies[value].quo(n_valid).to_f
        end

        # Sample variance with denominator (N-1)
        def variance_sample m=nil
          m ||= self.mean
          if @data.respond_to? :variance_sample
            @data.variance_sample m
          else
            sum_of_squares(m).quo((n_valid) - 1)
          end
        end

        # Population variance with denominator (N)
        def variance_population m=nil
          m ||= mean
          if @data.respond_to? :variance_population
            @data.variance_population m
          else
            sum_of_squares(m).quo((@size - @missing_positions.size)).to_f            
          end
        end

        def sum_of_squares(m=nil)
          m ||= mean
          @data.inject(0) { |memo, val| 
            @missing_values.has_key?(val) ? memo : (memo + (val - m)**2) 
          }
        end

        def standard_deviation_population m=nil
          m ||= mean
          if @data.respond_to? :standard_deviation_population
            @data.standard_deviation_population(m)
          else
            Math::sqrt(variance_population(m))
          end
        end

        def standard_deviation_sample m=nil
          m ||= mean
          if @data.respond_to? :standard_deviation_sample
            @data.standard_deviation_sample m
          else
            Math::sqrt(variance_sample(m))
          end
        end

        # Calculate skewness using (sigma(xi - mean)^3)/((N)*std_dev_sample^3)
        def skew m=nil
          if @data.respond_to? :skew
            @data.skew
          else
            m ||= mean
            th  = @data.inject(0) { |memo, val| memo + ((val - m)**3) }
            th.quo ((@size - @missing_positions.size) * (standard_deviation_sample(m)**3))
          end
        end

        def kurtosis m=nil
          if @data.respond_to? :kurtosis
            @data.kurtosis
          else
            m ||= mean
            fo  = @data.inject(0){ |a, x| a + ((x - m) ** 4) }
            fo.quo((@size - @missing_positions.size) * standard_deviation_sample(m) ** 4) - 3
          end
        end

        def average_deviation_population m=nil
          type == :numeric or raise TypeError, "Vector must be numeric"
          m ||= mean
          (@data.inject( 0 ) { |memo, val| 
            @missing_values.has_key?(val) ? memo : ( val - m ).abs + memo
          }).quo( n_valid )
        end

        def recode!(&block)
          @data.recode!(&block)
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
        def percentile(q, strategy = :midpoint)
          sorted = only_valid(:array).sort

          case strategy
          when :midpoint
            v = (n_valid * q).quo(100)
            if(v.to_i!=v)
              sorted[v.to_i]
            else
              (sorted[(v-0.5).to_i].to_f + sorted[(v+0.5).to_i]).quo(2)
            end
          when :linear
            index = (q / 100.0) * (n_valid + 1)

            k = index.truncate
            d = index % 1

            if k == 0
              sorted[0]
            elsif k >= sorted.size
              sorted[-1]
            else
              sorted[k - 1] + d * (sorted[k] - sorted[k - 1])
            end
          else
            raise NotImplementedError.new "Unknown strategy #{strategy.to_s}"
          end
        end

        # Dichotomize the vector with 0 and 1, based on lowest value.
        # If parameter is defined, this value and lower will be 0 
        # and higher, 1.
        def dichotomize(low = nil)
          low ||= factors.min

          self.recode do |x|
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
          return Daru::Vector.new([nil]*@size) if m.nil? or sd == 0.0

          vector_standardized_compute m, sd
        end

        def box_cox_transformation lambda # :nodoc:
          raise "Should be a numeric" unless @type == :numeric

          self.recode do |x|
            if !x.nil?
              if(lambda == 0)
                Math.log(x)
              else
                (x ** lambda - 1).quo(lambda)
              end
            else
              nil
            end
          end
        end

        # Replace each non-nil value in the vector with its percentile.
        def vector_percentile
          c = size - missing_positions.size
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
            valid = missing_positions.empty? ? self : self.only_valid
            vds = valid.size
            (0...sample).collect{ valid[rand(vds)] }
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
            valid = missing_positions.empty? ? self : self.only_valid 
            raise ArgumentError, "Sample size couldn't be greater than n" if 
              sample > valid.size
            out  = []
            size = valid.size
            while out.size < sample
              value = rand(size)
              out.push(value) if !out.include?(value)
            end

            out.collect{|i| valid[i]}
          end
        end

        alias :sdp :standard_deviation_population
        alias :sds :standard_deviation_sample
        alias :std :sds
        alias :adp :average_deviation_population
        alias :cov :coefficient_of_variation
        alias :variance :variance_sample    
        alias :sd :standard_deviation_sample
        alias :ss :sum_of_squares
        alias :percentil :percentile
        alias :se :standard_error
      end
    end
  end
end