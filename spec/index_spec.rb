require 'spec_helper.rb'

describe Daru::Index do
  context "#initialize" do
    it "creates an Index from Array" do
      idx = Daru::Index.new ['speaker', 'mic', 'guitar', 'amp']

      expect(idx.to_a).to eq(['speaker', 'mic', 'guitar', 'amp'])
    end

    it "accepts all sorts of objects for Indexing" do
      idx = Daru::Index.new [:a, 'a', :hello, '23', 23]

      expect(idx.to_a).to eq([:a, 'a', :hello, '23', 23])
    end
  end

  context "#size" do
    it "correctly returns the size of the index" do
      idx = Daru::Index.new ['speaker', 'mic', 'guitar', 'amp']

      expect(idx.size).to eq(4)
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

  context "#[]" do
    before do
      @id = Daru::Index.new [:one, :two, :three, :four, :five, :six, :seven]
      @mixed_id = Daru::Index.new ['a','b','c',:d,:a,0,3,5]
    end

    it "works with ranges" do
      expect(@id[:two..:five]).to eq(Daru::Index.new([:two, :three, :four, :five], 
        [1,2,3,4]))

      expect(@mixed_id['b'..0]).to eq(Daru::Index.new(['b','c',:d,:a,0],
        [1,2,3,4,5]))
    end

    it "returns multiple keys if specified multiple indices" do
      expect(@id[[0,1,3,4]]).to eq(Daru::Index.new([:one, :two, :four, :five], 
        [0,1,3,4]))
      expect(@mixed_id[0,5,3,2]).to eq(Daru::Index.new(['a',0,:d,'c'],
        [[0,5,3,2]]))
    end

    it "returns correct index position for non-numeric index" do
      expect(@id[:four]).to eq(3)
      expect(@id[3]).to eq(3)
    end

    it "returns correct index position for mixed index" do
      expect(@mixed_id[0]).to eq(5)
      expect(@mixed_id['c'].to eq(2))
    end
  end
end