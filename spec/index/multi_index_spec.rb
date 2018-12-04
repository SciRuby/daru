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
        levels: [[:a,:b,:c], [:one, :two]],
        labels: [[0,0,1,1,2,2], [0,1,0,1,0,1]])

      expect(mi[:a, :two]).to eq(1)
    end

    it "raises error for wrong number of labels or levels" do
      expect {
        Daru::MultiIndex.new(
          levels: [[:a,:a,:b,:b,:c,:c], [:one, :two]],
          labels: [[0,0,1,1,2,2]])
      }.to raise_error
    end

    context "create an MultiIndex with name" do
      context 'if no name is set' do
        subject { Daru::MultiIndex.new(
                    levels: [[:a,:b,:c], [:one, :two]],
                    labels: [[0,0,1,1,2,2], [0,1,0,1,0,1]]) }
        its(:name) { is_expected.to be_nil }
      end

      context 'correctly return the MultiIndex name' do
        subject { Daru::MultiIndex.new(
                  levels: [[:a,:b,:c], [:one, :two]],
                  labels: [[0,0,1,1,2,2], [0,1,0,1,0,1]], name: ['n1', 'n2']) }
        its(:name) { is_expected.to eq ['n1', 'n2'] }
      end

      context "set new MultiIndex name" do
        subject {
          Daru::MultiIndex.new(
                  levels: [[:a,:b,:c], [:one, :two]],
                  labels: [[0,0,1,1,2,2], [0,1,0,1,0,1]], name: ['n1', 'n2']) }
        before(:each) { subject.name = ['k1', 'k2'] }
        its(:name) { is_expected.to eq ['k1', 'k2'] }
      end

      context "set new MultiIndex name having empty string" do
        subject {
          Daru::MultiIndex.new(
                  levels: [[:a,:b,:c], [:one, :two]],
                  labels: [[0,0,1,1,2,2], [0,1,0,1,0,1]], name: ['n1', 'n2']) }
        before { subject.name = ['k1', ''] }
        its(:name) { is_expected.to eq ['k1', ''] }
      end

      it "raises SizeError for wrong number of name" do
        error_msg = "\'names\' and \'levels\' should be of same size. Size of the \'name\' array is 2 and size of the MultiIndex \'levels\' and \'labels\' is 3.\nIf you don\'t want to set name for particular level (say level \'i\') then put empty string on index \'i\' of the \'name\' Array."
        expect { @multi_mi.name = ['n1', 'n2'] }.to raise_error(SizeError, error_msg)

        error_msg = "'names' and 'levels' should be of same size. Size of the 'name' array is 0 and size of the MultiIndex 'levels' and 'labels' is 3.\nIf you don\'t want to set name for particular level (say level 'i') then put empty string on index 'i' of the 'name' Array."
        expect { @multi_mi.name = [ ] }.to raise_error(SizeError, error_msg)

        error_msg = "'names' and 'levels' should be of same size. Size of the 'name' array is 1 and size of the MultiIndex 'levels' and 'labels' is 3.\nIf you don\'t want to set name for particular level (say level 'i') then put empty string on index 'i' of the 'name' Array."
        expect { @multi_mi.name = [''] }.to raise_error(SizeError, error_msg)

        error_msg = "'names' and 'levels' should be of same size. Size of the 'name' array is 4 and size of the MultiIndex 'levels' and 'labels' is 3."
        expect { @multi_mi.name = ['n1', 'n2', 'n3', 'n4'] }.to raise_error(SizeError, error_msg)
      end
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
      expect(mi.levels).to eq([[:a, :b, :c], [:one,:two]])
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

  context '.try_from_tuples' do
    it 'creates MultiIndex, if there are tuples' do
      tuples = [
        [:a, :one],
        [:a, :two],
        [:b, :one],
        [:b, :two],
        [:c, :one],
        [:c, :two]
      ]
      mi = Daru::MultiIndex.try_from_tuples(tuples)
      expect(mi).to be_a Daru::MultiIndex
    end

    it 'returns nil, if MultiIndex can not be created' do
      mi = Daru::MultiIndex.try_from_tuples([:a, :b, :c])
      expect(mi).to be_nil
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

    it "returns MultiIndex when specifying incomplete tuple" do
      expect(@multi_mi[:b]).to eq(Daru::MultiIndex.from_tuples([
        [:b,:one,:bar],
        [:b,:two,:bar],
        [:b,:two,:baz],
        [:b,:one,:foo]
      ]))
      expect(@multi_mi[:b, :one]).to eq(Daru::MultiIndex.from_tuples([
        [:b,:one,:bar],
        [:b,:one,:foo]
      ]))
      # TODO: Return Daru::Index if a single layer of indexes is present.
    end

    it "returns MultiIndex when specifying wholly numeric ranges" do
      expect(@multi_mi[3..6]).to eq(Daru::MultiIndex.from_tuples([
        [:a,:two,:baz],
        [:b,:one,:bar],
        [:b,:two,:bar],
        [:b,:two,:baz]
      ]))
    end

    it "raises error when specifying invalid index" do
      expect { @multi_mi[:a, :three] }.to raise_error IndexError
      expect { @multi_mi[:a, :one, :xyz] }.to raise_error IndexError
      expect { @multi_mi[:x] }.to raise_error IndexError
      expect { @multi_mi[:x, :one] }.to raise_error IndexError
      expect { @multi_mi[:x, :one, :bar] }.to raise_error IndexError
    end

    it "works with numerical first levels" do
      mi = Daru::MultiIndex.from_tuples([
        [2000, 'M'],
        [2000, 'F'],
        [2001, 'M'],
        [2001, 'F']
      ])

      expect(mi[2000]).to eq(Daru::MultiIndex.from_tuples([
        [2000, 'M'],
        [2000, 'F']
        ]))

      expect(mi[2000,'M']).to eq(0)
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

    it "checks for non-existence of completely specified tuple" do
      expect(@multi_mi.include?([:b, :two, :foo])).to eq(false)
    end

    it "checks for non-existence of a top layer incomplete tuple" do
      expect(@multi_mi.include?([:d])).to eq(false)
    end

    it "checks for non-existence of a middle layer incomplete tuple" do
      expect(@multi_mi.include?([:c, :three])).to eq(false)
    end
  end

  context "#key" do
    it "returns the tuple of the specified number" do
      expect(@multi_mi.key(3)).to eq([:a,:two,:baz])
    end

    it "returns nil for non-existent pointer number" do
      expect {
        @multi_mi.key(100)
      }.to raise_error ArgumentError
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

  context "#inspect" do
    context 'small index' do
      subject {
        Daru::MultiIndex.from_tuples [
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
      }

      its(:inspect) { is_expected.to eq %Q{
        |#<Daru::MultiIndex(12x3)>
        |   a one bar
        |         baz
        |     two bar
        |         baz
        |   b one bar
        |     two bar
        |         baz
        |     one foo
        |   c one bar
        |         baz
        |     two foo
        |         bar
        }.unindent
      }
    end

    context 'large index' do
      subject {
        Daru::MultiIndex.from_tuples(
          (1..100).map { |i| %w[a b c].map { |c| [i, c] } }.flatten(1)
        )
      }

      its(:inspect) { is_expected.to eq %Q{
        |#<Daru::MultiIndex(300x2)>
        |   1   a
        |       b
        |       c
        |   2   a
        |       b
        |       c
        |   3   a
        |       b
        |       c
        |   4   a
        |       b
        |       c
        |   5   a
        |       b
        |       c
        |   6   a
        |       b
        |       c
        |   7   a
        |       b
        | ... ...
        }.unindent
      }
    end

    context 'multi index with name' do
      subject {
        Daru::MultiIndex.new(
          levels: [[:a,:b,:c],[:one,:two],[:bar, :baz, :foo]],
          labels: [
            [0,0,0,0,1,1,1,1,2,2,2,2],
            [0,0,1,1,0,1,1,0,0,0,1,1],
            [0,1,0,1,0,0,1,2,0,1,2,0]], name: ['n1', 'n2', 'n3'])
      }

      its(:inspect) { is_expected.to start_with %Q{
        |#<Daru::MultiIndex(12x3)>
        |  n1  n2  n3
        }.unindent
      }
    end

    context 'multi index with name having empty string' do
      subject {
        mi= Daru::MultiIndex.new(
                  levels: [[:a,:b,:c],[:one,:two],[:bar, :baz, :foo]],
                  labels: [
                    [0,0,0,0,1,1,1,1,2,2,2,2],
                    [0,0,1,1,0,1,1,0,0,0,1,1],
                    [0,1,0,1,0,0,1,2,0,1,2,0]], name: ['n1', 'n2', 'n3'])
      }
      before { subject.name = ['n1', '', 'n3'] }

      its(:inspect) { is_expected.to start_with %Q{
        |#<Daru::MultiIndex(12x3)>
        |  n1      n3
        }.unindent
      }
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

  context "#|" do
    before do
      @mi1 = Daru::MultiIndex.from_tuples([
        [:a, :one, :bar],
        [:a, :two, :baz],
        [:b, :one, :foo],
        [:b, :two, :bar]
        ])
      @mi2 = Daru::MultiIndex.from_tuples([
        [:a, :two, :bar],
        [:b, :one, :foo],
        [:a, :one, :baz],
        [:b, :two, :baz]
        ])
    end

    it "returns a union of two MultiIndex objects" do
      expect(@mi1 | @mi2).to eq(Daru::MultiIndex.new(
        levels: [[:a, :b], [:one, :two], [:bar, :baz, :foo]],
        labels: [
          [0, 0, 1, 1, 0, 0, 1],
          [0, 1, 0, 1, 1, 0, 1],
          [0, 1, 2, 0, 0, 1, 1]
        ])
      )
    end
  end

  context "#&" do
    before do
      @mi1 = Daru::MultiIndex.from_tuples([
        [:a, :one],
        [:a, :two],
        [:b, :two]
        ])
      @mi2 = Daru::MultiIndex.from_tuples([
        [:a, :two],
        [:b, :one],
        [:b, :three]
        ])
    end

    it "returns the intersection of two MI objects" do
      expect(@mi1 & @mi2).to eq(Daru::MultiIndex.from_tuples([
        [:a, :two],
      ]))
    end
  end

  context "#empty?" do
    it "returns true if nothing present in MultiIndex" do
      expect(Daru::MultiIndex.new(labels: [[]], levels: [[]]).empty?).to eq(true)
    end
  end

  context "#drop_left_level" do
    it "drops the leftmost level" do
      expect(
        Daru::MultiIndex.from_tuples([
          [:c,:one,:bar],
          [:c,:one,:baz],
          [:c,:two,:foo],
          [:c,:two,:bar]
        ]).drop_left_level).to eq(
          Daru::MultiIndex.from_tuples([
            [:one,:bar],
            [:one,:baz],
            [:two,:foo],
            [:two,:bar]
          ])
      )
    end
  end

  context 'other forms of tuple list representation' do
    let(:index) {
      Daru::MultiIndex.from_tuples [
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
    }

    context '#sparse_tuples' do
      subject { index.sparse_tuples }

      it { is_expected.to eq [
          [:a ,:one,:bar],
          [nil, nil,:baz],
          [nil,:two,:bar],
          [nil, nil,:baz],
          [:b ,:one,:bar],
          [nil,:two,:bar],
          [nil, nil,:baz],
          [nil,:one,:foo],
          [:c ,:one,:bar],
          [nil, nil,:baz],
          [nil,:two,:foo],
          [nil, nil,:bar]
      ]}
    end
  end

  context "#pos" do
    let(:idx) do
      described_class.from_tuples([
        [:b,:one,:bar],
        [:b,:two,:bar],
        [:b,:two,:baz],
        [:b,:one,:foo]
      ])
    end

    context "single index" do
      it { expect(idx.pos :b, :one, :bar).to eq 0 }
    end

    context "multiple indexes" do
      subject { idx.pos :b, :one }

      it { is_expected.to be_a Array }
      its(:size) { is_expected.to eq 2 }
      it { is_expected.to eq [0, 3] }
    end

    context "single positional index" do
      it { expect(idx.pos 0).to eq 0 }
    end

    context "multiple positional indexes" do
      subject { idx.pos 0, 1 }

      it { is_expected.to be_a Array }
      its(:size) { is_expected.to eq 2 }
      it { is_expected.to eq [0, 1] }
    end

    # TODO: Add specs for IndexError
  end

  context "#subset" do
    let(:idx) do
      described_class.from_tuples([
        [:b, :one, :bar],
        [:b, :two, :bar],
        [:b, :two, :baz],
        [:b, :one, :foo]
      ])
    end

    context "multiple indexes" do
      subject { idx.subset :b, :one }

      it { is_expected.to be_a described_class }
      its(:size) { is_expected.to eq 2 }
      its(:to_a) { is_expected.to eq [[:bar], [:foo]] }
    end

    context "multiple positional indexes" do
      subject { idx.subset 0, 1 }

      it { is_expected.to be_a described_class }
      its(:size) { is_expected.to eq 2 }
      its(:to_a) { is_expected.to eq [[:b, :one, :bar], [:b, :two, :bar]] }
    end

    # TODO: Checks for invalid indexes
  end

  context "at" do
    let(:idx) do
      described_class.from_tuples([
        [:b, :one, :bar],
        [:b, :two, :bar],
        [:b, :two, :baz],
        [:b, :one, :foo]
      ])
    end

    context "single position" do
      it { expect(idx.at 2).to eq [:b, :two, :baz] }
    end

    context "multiple positions" do
      subject { idx.at 1, 2 }

      it { is_expected.to be_a described_class }
      its(:size) { is_expected.to eq 2 }
      its(:to_a) { is_expected.to eq [[:b, :two, :bar],
        [:b, :two, :baz]] }
    end

    context "range" do
      subject { idx.at 1..2 }

      it { is_expected.to be_a described_class }
      its(:size) { is_expected.to eq 2 }
      its(:to_a) { is_expected.to eq [[:b, :two, :bar],
        [:b, :two, :baz]] }
    end

    context "range with negative integers" do
      subject { idx.at 1..-2 }

      it { is_expected.to be_a described_class }
      its(:size) { is_expected.to eq 2 }
      its(:to_a) { is_expected.to eq [[:b, :two, :bar],
        [:b, :two, :baz]] }
    end

    context "rangle with single element" do
      subject { idx.at 1..1 }

      it { is_expected.to be_a described_class }
      its(:size) { is_expected.to eq 1 }
      its(:to_a) { is_expected.to eq [[:b, :two, :bar]] }
    end

    context "invalid position" do
      it { expect { idx.at 4 }.to raise_error IndexError }
    end

    context "invalid positions" do
      it { expect { idx.at 2, 4 }.to raise_error IndexError }
    end
  end

  context "#add" do
    let(:idx) do
      described_class.from_tuples [
        [:a, :one, :bar],
        [:a, :two, :bar],
        [:b, :two, :baz],
        [:b, :one, :foo]
      ]
    end

    context "single index" do
      subject { idx.add :b, :two, :baz }

      its(:to_a) { is_expected.to eq [
        [:a, :one, :bar],
        [:a, :two, :bar],
        [:b, :two, :baz],
        [:b, :one, :foo],
        [:b, :two, :baz]] }
    end
  end

  context "#valid?" do
    let(:idx) do
      described_class.from_tuples [
        [:a, :one, :bar],
        [:a, :two, :bar],
        [:b, :two, :baz],
        [:b, :one, :foo]
      ]
    end

    context "single index" do
      it { expect(idx.valid? :a, :one, :bar).to eq true }
      it { expect(idx.valid? :b, :two, :three).to eq false }
    end

    context "multiple indexes" do
      it { expect(idx.valid? :a, :one).to eq true }
      it { expect(idx.valid? :a, :three).to eq false }
    end
  end

  context '#to_df' do
    let(:idx) do
      described_class.from_tuples([
        %w[a one bar],
        %w[a two bar],
        %w[b two baz],
        %w[b one foo]
      ]).tap { |idx| idx.name = %w[col1 col2 col3] }
    end

    subject { idx.to_df }
    it { is_expected.to eq Daru::DataFrame.new(
           'col1' => %w[a a b b],
           'col2' => %w[one two two one],
           'col3' => %w[bar bar baz foo]
    )}
  end
end
