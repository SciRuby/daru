require 'gsl' if Daru.has_gsl?

module Daru
  module Accessors
    class GSLWrapper
      include Enumerable
      extend Forwardable

      def_delegators :@data, :[], :[]=, :size, :to_a, :each, :mean, 
        :sum, :prod, :max, :min, :map!

      alias :product :prod

      attr_reader :data

      def initialize data, context
        @data = ::GSL::Vector.alloc(data)
        @context = context
      end

      def delete_at index
        
      end

      def index key
        
      end

      def push value
        
      end

      alias :<< :push

      def dup
        
      end
    end
  end
end