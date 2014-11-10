module Daru
  module Accessors
    # Internal class for wrapping ruby array
    class ArrayWrapper
      module Statistics
        # def average_deviation_population m=nil
        #   m ||= self.mean
        #   (self.reduce(0){|memo, val| val + (val - m).abs})/self.length
        # end

        # def coefficient_of_variation
        #   self.standard_deviation_sample/self.mean
        # end

        # def count x=false
        #   if block_given?
        #     self.reduce(0){|memo, val| memo += 1 if yield val; memo}
        #   else
        #     val = self.frequencies[x]
        #     val.nil? ? 0 : val
        #   end
        # end

        # def factors
        #   index = @data.sorted_indices
        #   index.reduce([]){|memo, val| memo.push(@data[val]) if memo.last != @data[val]; memo}
        # end

        # def frequencies
        #   index = @data.sorted_indices
        #   index.reduce({}){|memo, val| memo[@data[val]] ||= 0; memo[@data[val]] += 1; memo}
        # end

        def has_missing_data?
          self.has_missing_data
        end

        # def is_valid?
        #   true
        # end

        # def kurtosis(m=nil)
        #   m ||= self.mean
        #   fo=self.reduce(0){|a, x| a+((x-m)**4)}
        #   fo.quo(self.length*sd(m)**4)-3
        # end

        def mean
          @vector.inject(:+).quo(@size).to_f
        end

        # def median
        #   self.percentil(50)
        # end

        # def median_absolute_deviation
        #   m = self.median
        #   self.recode{|val| (val-m).abls}.median
        # end

        # def mode
        #   self.frequencies.max
        # end

        def n_valid
          @size
        end

        # def percentil(percent)
        #   index = @data.sorted_indices
        #   pos = (self.length * percent)/100
        #   if pos.to_i == pos
        #     @data[index[pos.to_i]]
        #   else
        #     pos = (pos-0.5).to_i
        #     (@data[index[pos]] + @data[index[pos+1]])/2
        #   end
        # end

        def product
          @vector.inject(:*)
        end

        def max
          @vector.max
        end

        def min
          @vector.min
        end

        # def proportion(val=1)
        #   self.frequencies[val]/self.n_valid
        # end

        # def proportion_confidence_interval_t
        #   raise "NotImplementedError"
        # end

        # def proportion_confidence_interval_z
        #   raise "NotImplementedError"
        # end

        # def proportions
        #   len = self.n_valid
        #   self.frequencies.reduce({}){|memo, arr| memo[arr[0]] = arr[1]/len}
        # end

        def range
          max - min
        end

        # def ranked
        #   sum = 0
        #   r = self.frequencies.sort.reduce({}) do |memo, val|
        #     memo[val[0]] = ((sum+1) + (sum+val[1]))/2
        #     sum += val[1]
        #     memo
        #   end
        #   Mikon::DArray.new(self.reduce{|val| r[val]})
        # end

        def recode(&block)
          @vector.map(&block)
        end

        def recode!(&block)
          @vector.map!(&block)
        end

        # Calculate skewness using (sigma(xi - mean)^3)/((N)*std_dev_sample^3)
        def skew m=nil
          m ||= self.mean
          th  = @vector.inject(0) { |memo, val| memo + ((val - m)**3) }
          th.quo (@size * (self.standard_deviation_sample(m)**3))
        end

        def standard_deviation_population m=nil
          m ||= self.mean
          Math.sqrt(self.variance_population(m))
        end

        def standard_deviation_sample(m=nil)
          Math.sqrt(variance_sample(m))
        end

        def standard_error
          self.standard_deviation_sample/(Math.sqrt(@size))
        end

        def sum_of_squared_deviation
          (@vector.inject(0) { |a,x| x.square + a } - (sum.square.quo(@size))).to_f
        end

        def sum_of_squares(m=nil)
          m ||= self.mean
          @vector.inject(0) { |memo, val| memo + (val - m)**2 }
        end

        def sum
          @vector.inject(:+)
        end

        # Sample variance with numerator (N-1)
        def variance_sample m=nil
          m ||= self.mean

          self.sum_of_squares(m).quo(@size - 1)
        end

        # Population variance with denominator (N)
        def variance_population m=nil
          m ||= self.mean

          self.sum_of_squares(m).quo @size
        end
      end # module Statistics

      include Statistics
      include Enumerable

      def each(&block)
        @vector.each(&block)
      end

      attr_accessor :size
      attr_reader   :vector
      attr_reader   :has_missing_data

      def initialize vector
        @vector = vector

        set_size
      end

      def [] index
        @vector[index]
      end

      def []= index, value
        has_missing_data = true if value.nil?
        @vector[index] = value
        set_size
      end

      def == other
        @vector == other
      end

      def delete_at index
        @vector.delete_at index
        set_size
      end

      def index key
        @vector.index key
      end

      def << element
        @vector << element
        set_size
      end

      def to_a
        @vector
      end

      def dup
        ArrayWrapper.new @vector.dup
      end

      def coerce dtype
        case
        when dtype == Array
          self
        when dtype == NMatrix
          Daru::Accessors::NMatrixWrapper.new @vector
        when dtype == MDArray
          raise NotImplementedError
        else
          raise ArgumentError, "Cant coerce to dtype #{dtype}"
        end
      end

     private

      def set_size
        @size = @vector.size
      end
    end
  end
end