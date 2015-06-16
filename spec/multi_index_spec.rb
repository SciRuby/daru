require 'spec_helper.rb'

describe Daru::MultiIndex do
  before(:each) do
    @index_tuples = [
      [:a,:one,:bar],
      [:a,:one,:baz],
      [:a,:two,:bar],
      [:a,:two,:baz],
      [:b,:one,:bar],
      [:b,:two,:bar],
      [:b,:two,:baz],
      [:b,:one,:foo],
      [:c,:one,:bar],
      [:c,:one,:baz],
      [:c,:two,:foo],
      [:c,:two,:bar]
    ]
    @multi_mi = Daru::MultiIndex.from_tuples(@index_tuples)
  end

  context ".initialize" do
    it "accepts labels and levels as arguments" do
      mi = Daru::MultiIndex.new(
        labels: [[:a,:a,:b,:b,:c,:c], [:one, :two]],
        levels: [[0,0,1,1,2,2], [0,1,0,1,0,1]])

      expect(mi[:a, :two]).to eq(1)
    end

    it "raises error for wrong number of labels or levels" do
      expect {
        Daru::MultiIndex.new(
          labels: [[:a,:a,:b,:b,:c,:c], [:one, :two]],
          levels: [[0,0,1,1,2,2]])
      }.to raise_error
    end
  end

  context ".from_tuples" do
    it "creates 2 layer MultiIndex from tuples" do
      tuples = [
        [:a, :one], 
        [:a, :two], 
        [:b, :one], 
        [:b, :two], 
        [:c, :one], 
        [:c, :two]
      ]
      mi = Daru::MultiIndex.from_tuples(tuples)
      expect(mi.levels).to eq([:a, :b, :c], [:one,:two])
      expect(mi.labels).to eq([[0,0,1,1,2,2], [0,1,0,1,0,1]])
    end

    it "creates a triple layer MultiIndex from tuples" do
      expect(@multi_mi.levels).to eq([[:a,:b,:c], [:one, :two],[:bar,:baz,:foo]])
      expect(@multi_mi.labels).to eq([
        [0,0,0,0,1,1,1,1,2,2,2,2],
        [0,0,1,1,0,1,1,0,0,0,1,1],
        [0,1,0,1,0,0,1,2,0,1,2,0]
      ])
    end
  end 

  context "#size" do
    it "returns size of MultiIndex" do
      expect(@multi_mi.size).to eq(12)
    end
  end

  context "#[]" do
    it "returns the row number when specifying the complete tuple" do
      expect(@multi_mi[:a, :one, :baz]).to eq(1)
    end

    it "returns an Array of indices when specifying incomplete tuple" do
      expect(@multi_mi[:b]).to eq([4,5,6,7])
      expect(@multi_mi[:b, :one]).to eq([4,7])
      # TODO: Return Daru::Index if a single layer of indexes is present.
    end

    it "returns actual index when specifying as an integer index" do
      expect(@multi_mi[1]).to eq(1)
    end
  end

  context "#include?" do
    it "checks if a completely specified tuple exists" do
      expect(@multi_mi.include?([:a,:one,:bar])).to eq(true)
    end

    it "checks if a top layer incomplete tuple exists" do
      expect(@multi_mi.include?([:a])).to eq(true)
    end

    it "checks if a middle layer incomplete tuple exists" do
      expect(@multi_mi.include?([:a, :one])).to eq(true)
    end

    it "checks for non-existence of a tuple" do
      expect(@multi_mi.include?([:boo])).to eq(false)
    end
  end

  context "#key" do
    it "returns the tuple of the specified number" do
      expect(@multi_mi.key(3)).to eq([:a,:two,:baz])
    end

    it "returns nil for non-existent pointer number" do
      expect(@multi_mi.key(100)).to eq(nil)
    end
  end

  context "#to_a" do
    it "returns tuples as an Array" do
      expect(@multi_mi.to_a).to eq(@index_tuples)
    end
  end

  context "#dup" do
    it "completely duplicates the object" do
      duplicate = @multi_mi.dup
      
      expect(duplicate)          .to eq(@multi_mi)
      expect(duplicate.object_id).to_not eq(@multi_mi.object_id)
    end
  end

  context "#==" do
    it "returns false for unequal MultiIndex comparisons" do
      mi1 = Daru::MultiIndex.from_tuples([
        [:a, :one, :bar],
        [:a, :two, :baz],
        [:b, :one, :foo],
        [:b, :two, :bar]
        ])
      mi2 = Daru::MultiIndex.from_tuples([
        [:a, :two, :bar],
        [:b, :one, :foo],
        [:a, :one, :baz],
        [:b, :two, :baz]
        ])

      expect(mi1 == mi2).to eq(false)
    end
  end

  context "#values" do
    it "returns an array of indices in order" do
      mi = Daru::MultiIndex.from_tuples([
        [:a, :one, :bar],
        [:a, :two, :baz],
        [:b, :one, :foo],
        [:b, :two, :bar]
        ])

      expect(mi.values).to eq([0,1,2,3])
    end
  end
end