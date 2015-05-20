require 'spec_helper.rb'

describe "Daru.lazy_update" do
  context "A variable which will set whether Vector metadata is updated immediately or lazily." do
    describe Daru::Vector do
      it "does updates metadata immediately when LAZY_UPDATE is set to default false" do
        v = Daru::Vector.new [1,2,3,4,nil,nil,3,nil]
        v[1] = nil

        expect(v.missing_positions.include?(1)).to eq(true)
      end

      it "does NOT update metadata immediately when @@lazy_update is set to default true. Update done when #update is called", focus: true do
        Daru.lazy_update = true
        v    = Daru::Vector.new [1,2,3,4,nil,nil]
        v[1] = nil
        v[0] = nil

        expect(v.missing_positions.include?(0)).to eq(false)
        expect(v.missing_positions.include?(1)).to eq(false)

        v.update
        expect(v.missing_positions.include?(0)).to eq(true)
        expect(v.missing_positions.include?(1)).to eq(true)

        Daru.lazy_update = false
      end
    end

    describe Daru::DataFrame do
      before do 
        v = Daru::Vector.new [1,2,3,4,nil,nil,3,nil]
        @df = Daru::DataFrame.new({a: v, b: v, c: v})
      end

      it "does updates metadata immediately when LAZY_UPDATE is set to default false" do
        @df[:a][1] = nil

        expect(@df[:a].missing_positions.include?(1)).to eq(true)
      end

      it "does NOT update metadata immediately when @@lazy_update is set to default true. Update done when #update is called", focus: true do
        Daru.lazy_update = true
        @df[:c][0] = nil
        @df[:a][1] = nil

        expect(@df[:c].missing_positions.include?(0)).to eq(false)
        expect(@df[:a].missing_positions.include?(1)).to eq(false)

        @df.update
        expect(@df[:c].missing_positions.include?(0)).to eq(true)
        expect(@df[:a].missing_positions.include?(1)).to eq(true)

        Daru.lazy_update = false
      end      
    end
  end
end