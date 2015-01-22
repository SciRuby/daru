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
    @multi_mi = Daru::MultiIndex.new(@index_tuples)
  end

  context "#initialize" do
    it "creates 2 layer MultiIndex from tuples" do
      tuples = [[:a, :one], [:a, :two], [:b, :one], [:b, :two], [:c, :one], [:c, :two]]
      mi = Daru::MultiIndex.new(tuples)
      expect(mi.relation_hash).to eq({
        :a => {
          :one => 0, 
          :two => 1
        },
        :b => {
          :one => 2,
          :two => 3
        },
        :c => {
          :one => 4,
          :two => 5
        }
      })
    end

    it "creates a triple layer MultiIndex from tuples" do
      expect(@multi_mi.relation_hash).to eq({
        :a => {
          :one => {
            :bar => 0,
            :baz => 1
            },
          :two => {
            :bar => 2,
            :baz => 3
          }
        },
        :b => {
          :one => {
            :bar => 4,
            :foo => 7
          },
          :two => {
            :bar => 5,
            :baz => 6
          }
        },
        :c => {
          :one => {
            :bar => 8,
            :baz => 9
          },
          :two => {
            :foo => 10,
            :bar => 11,
          }
        }
      })
    end

    it "accepts array index values externally" do
      mi = Daru::MultiIndex.new([
        [:a,:one,:bar],
        [:a,:one,:baz],
        [:a,:two,:bar],
        [:a,:two,:baz],
        [:b,:one,:bar]
      ], [6,3,1,2,9])

      expect(mi.values).to eq([6,3,1,2,9])
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

    it "returns a MultiIndex when specifying incomplete tuple" do
      expect(@multi_mi[:b]).to eq(Daru::MultiIndex.new([
          [:one,:bar],
          [:two,:bar],
          [:two,:baz],
          [:one,:foo]
        ])
      )

      expect(@multi_mi[:b, :one]).to eq(Daru::MultiIndex.new([
          [:bar],
          [:foo]
        ])
      )
      # TODO: Return Daru::Index if a single layer of indexes is present.
    end

    it "returns a MultiIndex when specifying as an integer index" do
      expect(@multi_mi[1]).to eq(Daru::MultiIndex.new([
          [:one,:bar],
          [:two,:bar],
          [:two,:baz],
          [:one,:foo]
        ])
      )
    end

    it "supports numeric Ranges" do
      expect(@multi_mi[0..1]).to eq(Daru::MultiIndex.new([        
        [:a,:one,:bar],
        [:a,:one,:baz],
        [:a,:two,:bar],
        [:a,:two,:baz],
        [:b,:one,:bar],
        [:b,:two,:bar],
        [:b,:two,:baz],
        [:b,:one,:foo]
      ]))
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
      mi1 = Daru::MultiIndex.new([
        [:a, :one, :bar],
        [:a, :two, :baz],
        [:b, :one, :foo],
        [:b, :two, :bar]
        ])
      mi2 = Daru::MultiIndex.new([
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
      # TODO
    end
  end
end