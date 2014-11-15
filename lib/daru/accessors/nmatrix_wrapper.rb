require 'nmatrix'

module Daru
  module Accessors

    # Internal class for wrapping NMatrix
    class NMatrixWrapper
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

        # def has_missing_data?
        #   @missing_data
        # end

        # def is_valid?
        #   true
        # end

        # def kurtosis(m=nil)
        #   m ||= self.mean
        #   fo=self.reduce(0){|a, x| a+((x-m)**4)}
        #   fo.quo(self.length*sd(m)**4)-3
        # end

        # def mean
        #   @vector[0...@size].mean.first
        # end

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

        # def ==(other)
        #   @data==other
        # end

        # def n_valid
        #   self.length
        # end

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

        # def product
        #   @data.inject(1){|memo, val| memo*val}
        # end

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

        # def push(val)
        #   self.expand(self.length+1)
        #   self[self.length-1] = recode
        # end

        # def range
        #   max - min
        # end

        # def ranked
        #   sum = 0
        #   r = self.frequencies.sort.reduce({}) do |memo, val|
        #     memo[val[0]] = ((sum+1) + (sum+val[1]))/2
        #     sum += val[1]
        #     memo
        #   end
        #   Mikon::DArray.new(self.reduce{|val| r[val]})
        # end

        # def recode(&block)
        #   Mikon::DArray.new(@data.map(&block))
        # end

        # def recode!(&block)
        #   @data.map!(&block)
        # end

        # def skew(m=nil)
        #   m ||= self.mean
        #   th = self.reduce(0){|memo, val| memo + ((val - m)**3)}
        #   th/((self.length)*self.sd(m)**3)
        # end

        # def standard_deviation_population(m=nil)
        #   m ||= self.mean
        #   Math.sqrt(self.variance_population(m))
        # end

        # def standard_deviation_sample(m=nil)
        #   if !m.nil?
        #     Math.sqrt(variance_sample(m))
        #   else
        #     @data.std.first
        #   end
        # end

        # def standard_error
        #   self.standard_deviation_sample/(Math.sqrt(self.length))
        # end

        # def sum_of_squared_deviation
        #   self.reduce(0){|memo, val| val**2 + memo}
        # end

        # def sum_of_squares(m=nil)
        #   m ||= self.mean
        #   self.reduce(0){|memo, val| memo + (val-m)**2}
        # end

        # def sum
        #   @data.sum.first
        # end

        # def variance_sample(m=nil)
        #   m ||= self.mean
        #   self.sum_of_squares(m)/(self.length-1)
        # end
      end # module Statistics

      include Statistics
      include Enumerable

      def each(&block)
        @vector.each(&block)
      end

      attr_reader :size, :vector, :missing_data

      def initialize vector, caller
        @size = vector.size
        @vector = NMatrix.new [@size*2], vector.to_a
        @missing_data = false
        @caller = caller
        # init with twice the storage for reducing the need to resize
      end

      def [] index
        @vector[index]
      end
 
      def []= index, value
        resize if index >= @size

        if value.nil?
          @missing_data = true
          @vector = @vector.cast(dtype: :object)
        end
        @vector[index] = value
      end 
 
      def == other
        @vector == other and @size == other.size
      end
 
      def delete_at index
        arry = @vector.to_a
        arry.delete_at index
        @vector = NMatrix.new [@size-1], arry
        @size -= 1
      end
 
      def index key
        @vector.to_a.index key
      end
 
      def << element
        if @size >= @vector.size
          resize
        end

        self[@size] = element

        @size += 1
      end
 
      def to_a
        @vector.to_a
      end
 
      def dup
        NMatrixWrapper.new @vector.to_a
      end

      def coerce dtype
        case 
        when dtype == Array
          Daru::Accessors::ArrayWrapper.new @vector[0..(@size-1)].to_a, @caller
        when dtype == NMatrix
          self
        when dtype == MDArray
          raise NotImplementedError
        else
          raise ArgumentError, "Cant coerce to dtype #{dtype}"
        end
      end

      def resize size = @size*2
        raise "Size must be greater than current size" if size < @size

        @vector = NMatrix.new [size], @vector.to_a
      end
    end
  end
end