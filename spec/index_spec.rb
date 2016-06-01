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

    it "creates DateTimeIndex if date-like objects specified" do
      i = Daru::Index.new([
        DateTime.new(2012,2,4), DateTime.new(2012,2,5), DateTime.new(2012,2,6)])
      expect(i.class).to eq(Daru::DateTimeIndex)
      expect(i.to_a).to eq([DateTime.new(2012,2,4), DateTime.new(2012,2,5), DateTime.new(2012,2,6)])
      expect(i.frequency).to eq('D')
    end
  end

  context "#initialize" do
    it "creates an Index from Array" do
      idx = Daru::Index.new ['speaker', 'mic', 'guitar', 'amp']

      expect(idx.to_a).to eq(['speaker', 'mic', 'guitar', 'amp'])
    end

    it "creates an Index from Range" do
      idx = Daru::Index.new 1..5

      expect(idx).to eq(Daru::Index.new [1, 2, 3, 4, 5])
    end

    it "raises ArgumentError on invalid input type" do
      expect { Daru::Index.new 'foo' }.to raise_error ArgumentError
    end

    it "accepts all sorts of objects for Indexing" do
      idx = Daru::Index.new [:a, 'a', :hello, '23', 23]

      expect(idx.to_a).to eq([:a, 'a', :hello, '23', 23])
    end
  end

  context '#keys' do
    subject(:idx) { Daru::Index.new ['speaker', 'mic', 'guitar', 'amp'] }

    it 'returns key by position' do
      expect(idx.key(2)).to eq 'guitar'
    end

    it 'returns nil on too large pos' do
      expect(idx.key(20)).to be_nil
    end

    it 'returns nil on wrong arg type' do
      expect(idx.key(nil)).to be_nil
    end
  end

  context "#size" do
    it "correctly returns the size of the index" do
      idx = Daru::Index.new ['speaker', 'mic', 'guitar', 'amp']

      expect(idx.size).to eq(4)
    end
  end

  context '#inspect' do
    context 'small index' do
      subject { Daru::Index.new ['one', 'two', 'three']  }
      its(:inspect) { is_expected.to eq "#<Daru::Index(3): {one, two, three}>" }
    end

    context 'large index' do
      subject { Daru::Index.new ('a'..'z').to_a  }
      its(:inspect) { is_expected.to eq "#<Daru::Index(26): {a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t ... z}>" }
    end
  end

  context "#&" do
    before :each do
      @left = Daru::Index.new [:miles, :geddy, :eric]
      @right = Daru::Index.new [:geddy, :richie, :miles]
    end

    it "intersects 2 indexes and returns an Index" do
      expect(@left & @right).to eq([:miles, :geddy].to_index)
    end

    it "intersects an Index and an Array to return an Index" do
      expect(@left & [:bob, :geddy, :richie]).to eq([:geddy].to_index)
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
      @mixed_id = Daru::Index.new ['a','b','c',:d,:a,8,3,5]
    end

    it "works with ranges" do
      expect(@id[:two..:five]).to eq(Daru::Index.new([:two, :three, :four, :five]))

      expect(@mixed_id['a'..'c']).to eq(Daru::Index.new(['a','b','c']))

      # If both start and end are numbers then refer to numerical indexes
      expect(@mixed_id[0..2]).to eq(Daru::Index.new(['a','b','c']))

      # If atleast one is a number then refer to actual indexing
      expect(@mixed_id.slice('b',8)).to eq(Daru::Index.new(['b','c',:d,:a,8]))
    end

    it "returns multiple keys if specified multiple indices" do
      expect(@id[0,1,3,4]).to eq(Daru::Index.new([:one, :two, :four, :five]))
      expect(@mixed_id[0,5,3,2]).to eq(Daru::Index.new(['a', 8, :d, 'c']))
    end

    it "returns correct index position for non-numeric index" do
      expect(@id[:four]).to eq(3)
      expect(@id[3]).to eq(3)
    end

    it "returns correct index position for mixed index" do
      expect(@mixed_id[8]).to eq(5)
      expect(@mixed_id['c']).to eq(2)
    end
  end
end

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

    it "checks for non-existence of a tuple" do
      expect(@multi_mi.include?([:boo])).to eq(false)
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
        |#<Daru::MultiIndex(3x12)>
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
        |#<Daru::MultiIndex(2x300)>
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

    context '#tuples_with_rowspans' do
      subject { index.tuples_with_rowspans }

      it { is_expected.to eq [
          [[:a,4],[:one,2],[:bar,1]],
          [                [:baz,1]],
          [       [:two,2],[:bar,1]],
          [                [:baz,1]],
          [[:b,4],[:one,1],[:bar,1]],
          [       [:two,2],[:bar,1]],
          [                [:baz,1]],
          [       [:one,1],[:foo,1]],
          [[:c,4],[:one,2],[:bar,1]],
          [                [:baz,1]],
          [       [:two,2],[:foo,1]],
          [                [:bar,1]]
      ]}
    end

    context '#to_html' do
      let(:table) { Nokogiri::HTML(index.to_html) }

      describe 'first row' do
        subject { table.at('tr:first-child > th') }
        its(['colspan']) { is_expected.to eq '3' }
        its(:text) { is_expected.to eq 'Daru::MultiIndex(12x3)' }
      end

      describe 'next row' do
        let(:row) { table.at('tr:nth-child(2)') }
        subject { row.inner_html.scan(/<th.+?<\/th>/) }

        it { is_expected.to eq [
            '<th rowspan="4">a</th>',
            '<th rowspan="2">one</th>',
            '<th rowspan="1">bar</th>'
        ]}
      end
    end
  end
end
