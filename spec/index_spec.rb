require 'spec_helper.rb'

describe Daru::Index do
  context "#initialize" do
    it "creates an Index from Array" do
      idx = Daru::Index.new ['speaker', 'mic', 'guitar', 'amp']

      expect(idx.to_a).to eq([:speaker, :mic, :guitar, :amp])
    end
  end

  context "#size" do
    it "correctly returns the size of the index" do
      idx = Daru::Index.new ['speaker', 'mic', 'guitar', 'amp']

      expect(idx.size).to eq(4)
    end
  end

  context "#re_index" do
    before :each do
      @old = Daru::Index.new [:bob, :fisher, :zakir]
    end
    it "returns a new index object" do
      n   = @old.re_index(@old + [:john, :shrinivas]) 

      expect(n.object_id).not_to eq(@old.object_id)
      expect(n.to_a).to eq([:bob, :fisher, :zakir, :john, :shrinivas])
    end

    it "does not over-ride existing indexes" do
      n = @old.re_index(@old + :bob)

      expect(n.object_id).not_to eq(@old.object_id)
      expect(n.to_a)     .to eq([:bob, :fisher, :zakir])
    end
  end

  context "#+" do
    before :each do
      @left = Daru::Index.new [:miles, :geddy, :eric]
      @right = Daru::Index.new [:bob, :jimi, :richie]
    end

    it "adds 2 indexes and returns an Index" do
      expect(@left + @right).to eq([:miles, :geddy, :eric, :bob, :jimi, :richie].to_index)
    end

    it "adds an Index and an Array to return an Index" do
      expect(@left + [:bob, :jimi, :richie]).to eq([:miles, :geddy, :eric, 
        :bob, :jimi, :richie].to_index)
    end
  end
end