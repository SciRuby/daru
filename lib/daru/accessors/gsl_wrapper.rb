module Daru
  module Accessors
    class GSLWrapper
      include Enumerable
      extend Forwardable
      include GSLStatistics

      def_delegators :@data, :[], :size, :to_a, :each, :mean, 
        :sum, :prod, :max, :min

      alias :product :prod

      attr_reader :data

      def map!(&block)
        @data.map!(&block)
        self
      end

      def initialize data, context
        @data = ::GSL::Vector.alloc(data)
        @context = context
      end

      def []= index, element
        if index == size
          push element
        else
          @data[index] = element
        end
      end

      def delete_at index
        @data.delete_at index
      end

      def index key
        @data.to_a.index key
      end

      def push value
        @data = @data.concat value
        self
      end
      alias :<< :push
      alias :concat :push

      def dup
        GSLWrapper.new(@data.to_a, @context)
      end

      def == other
        @data == other.data
      end
    end

    module GSLStatistics
      def vector_standarized_compute(m,sd)
        Daru::Vector.new @data.collect { |x| (x.to_f - m).quo(sd) }
      end
      
      def vector_centered_compute(m)
        @data.collect {|x| (x.to_f - m)}.to_scale
      end

      def sample_with_replacement(sample=1)
        r = GSL::Rng.alloc(GSL::Rng::MT19937,rand(10000))
        Statsample::Vector.new(r.sample(@data, sample).to_a,:scale)
      end
      
      def sample_without_replacement(sample=1)
        r = GSL::Rng.alloc(GSL::Rng::MT19937,rand(10000))
        r.choose(gsl, sample).to_a
      end

      def median
        sorted=GSL::Vector.alloc(@scale_data.sort)
        GSL::Stats::median_from_sorted_data(sorted)
      end
      
      def variance_sample(m=nil)
        m ||= mean
        @data.variance_m
      end
      
      def standard_deviation_sample(m=nil)
        m ||= mean
        @data.sd(m)
      end

      def variance_population(m=nil)
        m ||= mean
        @data.variance_with_fixed_mean(m)
      end

      def standard_deviation_population(m=nil)
        m ||= mean
        @data.sd_with_fixed_mean(m)
      end

      def skew
        @data.skew
      end

      def kurtosis
        @data.kurtosis
      end
    end
  end
end if Daru.has_gsl?