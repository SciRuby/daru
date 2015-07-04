require 'spec_helper'
include Daru

describe DateOffset do
  context "#initialize" do
    it "creates a seconds offset" do
      offset = DateOffset.new(secs: 5)
    end

    it "creates a minutes offset" 
      offset = DateOffset.new(mins: 2)
    end

    it "creates an hours offset"
      offset = DateOffset.new(hours: 3)
    end

    it "creates a days offset" do
      offset = DateOffset.new(days: 12)
    end

    it "creates a weeks offset" do
      offset = DateOffset.new(weeks: 2)
    end

    it "creates a months offset" do
      offset = DateOffset.new(months: 1)
    end
  end
end

describe Offsets::Week do
  context "#initialize" do
    [:sunday, :monday, :tuesday, :wednesday, :thursday, :friday, 
      :saturday].each_with_index do |day,i|
      it "creates an anchored weekly (#{day}) offset" do
        offset = Offsets::Week.new(weekday: i)
      end
    end
  end
end

describe Offsets::MonthBegin do
  context "#initialize" do
    it "creates a month begin offset" do
      offset = Offsets::MonthBegin.new
    end
  end
end

describe Offsets::MonthEnd do
  context "#initialize" do
    it "creates a month end offset" do
      offset = Offsets::MonthEnd.new
    end
  end
end

describe Offsets::YearBegin do
  context "#initialize" do
    it "creates a year begin offset" do
      offset = Offsets::YearBegin.new
    end
  end
end

describe Offsets::YearEnd do
  context "#initialize" do
    it "creates a year end offset" do
      offset = Offsets::YearEnd.new
    end
  end
end