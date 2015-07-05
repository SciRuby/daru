module Daru
  class DateOffset
    def initialize opts={}
      
    end

    def + other
      
    end
  end

  module Offsets
    class Week < DateOffset
    end
    
    class MonthBegin < DateOffset
    end

    class MonthEnd < DateOffset
    end

    class YearBegin < DateOffset
    end

    class YearEnd < DateOffset
    end
  end
end