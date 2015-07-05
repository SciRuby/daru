require 'spec_helper'
include Daru

describe DateOffset do
  context "#initialize, #+" do
    it "creates a seconds offset" do
      offset = DateOffset.new(secs: 5)
      expect(offset + DateTime.new(2012,3,4,23,4,00)).to eq(
        DateTime.new(2012,3,4,23,4,05))
    end

    it "creates a minutes offset"  do
      offset = DateOffset.new(mins: 2)
      expect(offset + DateTime.new(2013,4,5,12,45,44)).to eq(
        DateTime.new(2013,4,5,12,47,44))
    end

    it "creates an hours offset" do
      offset = DateOffset.new(hours: 3)
      expect(offset + DateTime.new(2024,3,2)).to eq(
        DateTime.new(2024,3,2,03,0,0))
    end

    it "creates a days offset" do
      offset = DateOffset.new(days: 12)
      expect(offset + DateTime.new(2012,5,4)).to eq(
        DateTime.new(2012,5,16))
    end

    it "creates a weeks offset" do
      offset = DateOffset.new(weeks: 2)
      expect(offset + DateTime.new(2012,3,1)).to eq(
        DateTime.new(2012,3,15))
    end

    it "creates a months offset" do
      offset = DateOffset.new(months: 1)
      expect(offset + DateTime.new(2012,3,1)).to eq(
        DateTime.new(2012,4,1))
    end
  end
end

include Daru::Offsets

describe Offsets do
  describe Week do
    context "#initialize" do
      [:sunday, :monday, :tuesday, :wednesday, :thursday, :friday, 
        :saturday].each_with_index do |day,i|
        it "creates an anchored weekly (#{day}) offset" do
          offset = Offsets::Week.new(weekday: i)
          # TODO
        end
      end
    end
  end

  describe MonthBegin do
    context "#initialize" do
      it "creates a month begin offset" do
        offset = Offsets::MonthBegin.new
        expect(offset + DateTime.new(2012,3,25)).to eq(
          DateTime.new(2012,4,1))
      end
    end
  end

  describe MonthEnd do
    context "#initialize" do
      it "creates a month end offset" do
        offset = Offsets::MonthEnd.new
        expect(offset + DateTime.new(2012,3,25)).to eq(
          DateTime.new(2012,3,31))
      end
    end
  end

  describe YearBegin do
    context "#initialize" do
      it "creates a year begin offset" do
        offset = Offsets::YearBegin.new
        expect(offset + DateTime.new(2012,3,25)).to eq(
          DateTime.new(2013,1,1))
      end
    end
  end

  describe YearEnd do
    context "#initialize" do
      it "creates a year end offset" do
        offset = Offsets::YearEnd.new
        expect(offset + DateTime.new(2012,2,29)).to eq(
          DateTime.new(2012,12,31))
      end
    end
  end
end
