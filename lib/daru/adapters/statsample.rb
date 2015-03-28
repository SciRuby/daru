# File for patching DataFrame and Vector 
# to make them compatible with statsample.
module Daru
  class DataFrame
  end

  class Vector
    alias :flawed? :has_missing_data?
    alias :is_valid? :exists?

    module GSL_
      def gsl
        @gsl ||= GSL::Vector.alloc(@data.to_a) if nil_positions.size > 0
      end
    end
  end
end