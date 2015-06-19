require 'spec_helper.rb'

describe Daru::Index do

  context ".new" do
    it "creates an Index object if Index-like data is supplied" do
      i = Daru::Index.new [:one, 'one', 1, 2, :two]
      expect(i.class).to eq(Daru::Index)
      expect(i.to_a) .to eq([:one, 'one', 1, 2, :two])
    end

    it "creates a MultiIndex if tuples are supplied" do
      i = Daru::Index.new([
        [:b,:one,:bar],
        [:b,:two,:bar],
        [:b,:two,:baz],
        [:b,:one,:foo]
      ])

      expect(i.class).to eq(Daru::MultiIndex)
      expect(i.levels).to eq([[:b], [:one, :two], [:bar, :baz, :foo]])
      expect(i.labels).to eq([[0,0,0,0],[0,1,1,0],[0,0,1,2]])
    end
  end

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

  context "#&" do
    it "returns an intersection of 2 index objects" do
    end
  end

  context "#|" do
    before :each do
      @left = Daru::Index.new [:miles, :geddy, :eric]
      @right = Daru::Index.new [:bob, :jimi, :richie]
    end

    it "unions 2 indexes and returns an Index" do
      expect(@left | @right).to eq([:miles, :geddy, :eric, :bob, :jimi, :richie].to_index)
    end

    it "unions an Index and an Array to return an Index" do
      expect(@left | [:bob, :jimi, :richie]).to eq([:miles, :geddy, :eric, 
        :bob, :jimi, :richie].to_index)
    end
  end

  context "#[]" do
    before do
      @id = Daru::Index.new [:one, :two, :three, :four, :five, :six, :seven]
      @mixed_id = Daru::Index.new ['a','b','c',:d,:a,0,3,5]
    end

    it "works with ranges" do
      expect(@id[:two..:five]).to eq(Daru::Index.new([:two, :three, :four, :five]))

      expect(@mixed_id['a'..'c']).to eq(Daru::Index.new(['a','b','c']))

      # If both start and end are numbers then refer to numerical indexes
      expect(@mixed_id[0..2]).to eq(Daru::Index.new(['a','b','c']))

      # If atleast one is a number then refer to actual indexing
      expect(@mixed_id.slice('b',0)).to eq(Daru::Index.new(['b','c',:d,:a,0]))
    end

    it "returns multiple keys if specified multiple indices" do
      expect(@id[0,1,3,4]).to eq(Daru::Index.new([0,1,3,4]))
      expect(@mixed_id[0,5,3,2]).to eq(Daru::Index.new([5, 7, 6, 2]))
    end

    it "returns correct index position for non-numeric index" do
      expect(@id[:four]).to eq(3)
      expect(@id[3]).to eq(3)
    end

    it "returns correct index position for mixed index" do
      expect(@mixed_id[0]).to eq(5)
      expect(@mixed_id['c']).to eq(2)
    end
  end
end