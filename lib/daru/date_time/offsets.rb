module Daru
  class DateOffset
    def initialize opts={}
      
    end

    def + other
      
    end
  end

  module Offsets
    class Second < DateOffset
    end

    class Minute < DateOffset
    end

    class Hour < DateOffset
    end

    class Day < DateOffset
    end

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