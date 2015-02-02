require 'spec_helper.rb'

describe Daru::Core::GroupBy do
  before do
    @df = Daru::DataFrame.new({
      a: %w{foo bar foo bar foo bar foo foo},
      b: %w{one one two three two two one three},
      c: [1,2,3,1,2,6,3,8],
      d: [11,22,33,44,55,66,77,88]
    })
  end

  context "#initialize" do
    it "groups by a single tuple" do
      grouped = @df.group_by(:a)
      
    end

    it "groups by a double layer hierarchy" do
      grouped = @df.group_by([:a, :c])
    end

    it "groups by a triple layer hierarchy" do
      grouped = @df.group_by([:a, :b, :c])
    end

    it "raises error if a non-existent vector is passed as args" do
      expect {
        @df.group_by([:a, :ted])
      }.to raise_error
    end
  end

  context "#mean" do

  end

  context "#count" do

  end

  context "#[]" do
    
  end
end