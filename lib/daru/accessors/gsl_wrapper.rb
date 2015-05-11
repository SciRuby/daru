module Daru
  module Accessors
    class GSLWrapper
      include Enumerable
      extend Forwardable

      def_delegators :@data, :[], :[]=, :size, :to_a, :each, :mean, 
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
        
      end

      def == other
        @data == other.data
      end
    end
  end
end if Daru.has_gsl?