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

    it "creates DateTimeIndex if date-like objects specified" do
      i = Daru::Index.new([
        DateTime.new(2012,2,4), DateTime.new(2012,2,5), DateTime.new(2012,2,6)])
      expect(i.class).to eq(Daru::DateTimeIndex)
      expect(i.to_a).to eq([DateTime.new(2012,2,4), DateTime.new(2012,2,5), DateTime.new(2012,2,6)])
      expect(i.frequency).to eq('D')
    end

    context "create an Index with name" do
      context "if no name is set" do
        let(:idx) { Daru::Index.new [:a, :b, :c] }
        it { expect(idx.name).to be_nil }
      end

      context "correctly return the index name" do
        let(:idx) { Daru::Index.new [:a, :b, :c], name: 'index_name' }
        it { expect(idx.name).to eq 'index_name' }
      end

      context "set new index name" do
        let(:idx) { Daru::Index.new [:a, :b, :c], name: 'index_name' }
        before { idx.name = 'new_name' }
        it { expect(idx.name).to eq 'new_name' }
      end
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

  context '#key' do
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

  context "#valid?" do
    let(:idx) { Daru::Index.new [:a, :b, :c] }

    context "single index" do
      it { expect(idx.valid? 2).to eq true }
      it { expect(idx.valid? :d).to eq false }
    end

    context "multiple indexes" do
      it { expect(idx.valid? :a, 1).to eq true }
      it { expect(idx.valid? :a, 3).to eq false }
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

    context 'index with name' do
      subject { Daru::Index.new ['one', 'two', 'three'], name: 'number'  }
      its(:inspect) { is_expected.to eq "#<Daru::Index: number(3): {one, two, three}>" }
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

  context "#pos" do
    let(:idx) { described_class.new [:a, :b, 1, 2] }

    context "single index" do
      it { expect(idx.pos :a).to eq 0 }
    end

    context "multiple indexes" do
      subject { idx.pos :a, 1 }

      it { is_expected.to be_a Array }
      its(:size) { is_expected.to eq 2 }
      it { is_expected.to eq [0, 2] }
    end

    context "single positional index" do
      it { expect(idx.pos 0).to eq 0 }
    end

    context "multiple positional index" do
      subject { idx.pos 0, 3 }

      it { is_expected.to be_a Array }
      its(:size) { is_expected.to eq 2 }
      it { is_expected.to eq [0, 3] }
    end

    context "range" do
      subject { idx.pos 1..3 }

      it { is_expected.to be_a Array }
      its(:size) { is_expected.to eq 3 }
      it { is_expected.to eq [1, 2, 3] }
    end
  end

  context "#subset" do
    let(:idx) { described_class.new [:a, :b, 1, 2] }

    context "multiple indexes" do
      subject { idx.subset :a, 1 }

      it { is_expected.to be_a described_class }
      its(:size) { is_expected.to eq 2 }
      its(:to_a) { is_expected.to eq [:a, 1] }
    end

    context "multiple positional indexes" do
      subject { idx.subset 0, 3 }

      it { is_expected.to be_a described_class }
      its(:size) { is_expected.to eq 2 }
      its(:to_a) { is_expected.to eq [:a, 2] }
    end

    context "range" do
      subject { idx.subset 1..3 }

      it { is_expected.to be_a described_class }
      its(:size) { is_expected.to eq 3 }
      its(:to_a) { is_expected.to eq [:b, 1, 2] }
    end
  end

  context "#at" do
    let(:idx) { described_class.new [:a, :b, 1 ] }

    context "single position" do
      it { expect(idx.at 1).to eq :b }
    end

    context "multiple positions" do
      subject { idx.at 1, 2 }

      it { is_expected.to be_a described_class }
      its(:size) { is_expected.to eq 2 }
      its(:to_a) { is_expected.to eq [:b, 1] }
    end

    context "range" do
      subject { idx.at 1..2 }

      it { is_expected.to be_a described_class }
      its(:size) { is_expected.to eq 2 }
      its(:to_a) { is_expected.to eq [:b, 1] }
    end

    context "range with negative integer" do
      subject { idx.at 1..-1 }

      it { is_expected.to be_a described_class }
      its(:size) { is_expected.to eq 2 }
      its(:to_a) { is_expected.to eq [:b, 1] }
    end

    context "rangle with single element" do
      subject { idx.at 1..1 }

      it { is_expected.to be_a described_class }
      its(:size) { is_expected.to eq 1 }
      its(:to_a) { is_expected.to eq [:b] }
    end

    context "invalid position" do
      it { expect { idx.at 3 }.to raise_error IndexError }
    end

    context "invalid positions" do
      it { expect { idx.at 2, 3 }.to raise_error IndexError }
    end
  end

  # This context validate Daru::Index is like an enumerable.
  # #map and #select are samples and we do not need tests all
  # enumerable methods.
  context "Enumerable" do
    let(:idx) { Daru::Index.new ['speaker', 'mic', 'guitar', 'amp'] }

    context "#map" do
      it { expect(idx.map(&:upcase)).to eq(['SPEAKER', 'MIC', 'GUITAR', 'AMP']) }
    end

    context "select" do
      it { expect(idx.select {|w| w[0] == 'g' }).to eq(['guitar']) }
    end
  end
end
