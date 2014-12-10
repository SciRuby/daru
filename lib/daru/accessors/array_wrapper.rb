module Daru
  module Accessors
    # Internal class for wrapping ruby array
    class ArrayWrapper
      module Statistics

        def average_deviation_population m=nil
          m ||= mean
          (@data.inject(0) {|memo, val| val + (val - m).abs }) / n_valid
        end

        def coefficient_of_variation
          standard_deviation_sample / mean
        end

        def count value=false
          if block_given?
            @data.inject(0){ |memo, val| memo += 1 if yield val; memo}
          else
            val = frequencies[value]
            val.nil? ? 0 : val
          end
        end

        def factors
          index = @data.sorted_indices
          index.reduce([]){|memo, val| memo.push(@data[val]) if memo.last != @data[val]; memo}
        end # TODO

        def frequencies
          @data.inject({}) do |hash, element|
            hash[element] ||= 0
            hash[element] += 1
            hash
          end
        end

        def has_missing_data?
          has_missing_data
        end

        def kurtosis m=nil
          m ||= mean
          fo  = @data.inject(0){ |a, x| a + ((x - m) ** 4) }
          fo.quo(@size * standard_deviation_sample(m) ** 4) - 3
        end

        def mean
          sum.quo(@size).to_f
        end

        def median
          percentile 50
        end

        def median_absolute_deviation
          m = median
          recode {|val| (val - m).abs }.median
        end

        def mode
          freqs = frequencies.values

          @data[freqs.index(freqs.max)]
        end

        def n_valid
          @size
        end

        def percentile percent
          sorted = @data.sort
          v      = (n_valid * percent).quo(100)
          if v.to_i != v
            sorted[v.round]
          else
            (sorted[(v - 0.5).round].to_f + sorted[(v + 0.5).round]).quo(2)
          end
        end

        def product
          @data.inject(:*)
        end

        def max
          @data.max
        end

        def min
          @data.min
        end

        def proportion value=1
          frequencies[value] / n_valid
        end

        def proportions
          len = n_valid
          frequencies.inject({}) { |hash, arr| hash[arr[0]] = arr[1] / len; hash }
        end

        def range
          max - min
        end

        def ranked
          sum = 0
          r = frequencies.sort.inject( {} ) do |memo, val|
            memo[val[0]] = ((sum + 1) + (sum + val[1])) / 2
            sum += val[1]
            memo
          end

          Daru::Vector.new @data.map { |e| r[e] }, index: @context.index,
            name: @context.name, dtype: @context.dtype
        end

        def recode(&block)
          @data.map(&block)
        end

        def recode!(&block)
          @data.map!(&block)
        end

        # Calculate skewness using (sigma(xi - mean)^3)/((N)*std_dev_sample^3)
        def skew m=nil
          m ||= mean
          th  = @data.inject(0) { |memo, val| memo + ((val - m)**3) }
          th.quo (@size * (standard_deviation_sample(m)**3))
        end

        def standard_deviation_population m=nil
          m ||= mean
          Math::sqrt(variance_population(m))
        end

        def standard_deviation_sample m=nil
          Math::sqrt(variance_sample(m))
        end

        def standard_error
          standard_deviation_sample/(Math::sqrt(@size))
        end

        def sum_of_squared_deviation
          (@data.inject(0) { |a,x| x.square + a } - (sum.square.quo(@size))).to_f
        end

        def sum_of_squares(m=nil)
          m ||= mean
          @data.inject(0) { |memo, val| memo + (val - m)**2 }
        end

        def sum
          @data.inject(:+)
        end

        # Sample variance with denominator (N-1)
        def variance_sample m=nil
          m ||= self.mean

          sum_of_squares(m).quo(@size - 1)
        end

        # Population variance with denominator (N)
        def variance_population m=nil
          m ||= mean

          sum_of_squares(m).quo(@size).to_f
        end
      end # module Statistics

      include Statistics
      include Enumerable

      def each(&block)
        @data.each(&block)
      end

      def map!(&block)
        @data.map!(&block)
      end

      attr_accessor :size
      attr_reader   :data
      attr_reader   :has_missing_data

      def initialize vector, context
        @data = vector.to_a
        @context = context

        set_size
      end

      def [] index
        @data[index]
      end

      def []= index, value
        has_missing_data = true if value.nil?
        @data[index] = value
        set_size
      end

      def == other
        @data == other
      end

      def delete_at index
        @data.delete_at index
        set_size
      end

      def index key
        @data.index key
      end

      def << element
        @data << element
        set_size
      end

      def uniq
        @data.uniq
      end

      def to_a
        @data
      end

      def dup
        ArrayWrapper.new @data.dup, @context
      end

     private

      def set_size
        @size = @data.size
      end
    end
  end
end