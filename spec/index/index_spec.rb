require 'spec_helper.rb'

RSpec.describe Daru::Index do
  describe '.new' do
    subject { described_class.new(data) }

    context 'with one-level array' do
      let(:data) { [:one, 'one', 1, 2, :two] }

      it { is_expected.to be_a described_class }
      its(:name) { is_expected.to be_nil }
      its(:to_a) { is_expected.to eq data }

      context 'named' do
        subject { described_class.new data, name: 'index_name' }

        its(:name) { is_expected.to eq 'index_name' }
      end
    end

    context 'with array of tuples' do
      let(:data) {
        [
          %i[b one bar],
          %i[b two bar],
          %i[b two baz],
          %i[b one foo]
        ]
      }

      it { is_expected.to be_a Daru::MultiIndex }
      its(:levels) { is_expected.to eq [[:b], %i[one two], %i[bar baz foo]] }
      its(:labels) { is_expected.to eq [[0,0,0,0],[0,1,1,0],[0,0,1,2]] }
    end

    context 'with array of dates' do
      let(:data) { [DateTime.new(2012,2,4), DateTime.new(2012,2,5), DateTime.new(2012,2,6)] }

      it { is_expected.to be_a Daru::DateTimeIndex }
      its(:to_a) { is_expected.to eq [DateTime.new(2012,2,4), DateTime.new(2012,2,5), DateTime.new(2012,2,6)] }
      its(:frequency) { is_expected.to eq 'D' }
    end
  end

  describe '#initialize' do
    subject { described_class.new data }

    context 'from Array' do
      let(:data) { %w[speaker mic guitar amp] }

      its(:to_a) { is_expected.to eq data }
    end

    context 'from Range' do
      let(:data) { 1..5 }

      its(:to_a) { is_expected.to eq [1, 2, 3, 4, 5] }
    end

    context 'from non-Enumerable' do
      let(:data) { 'foo' }

      its_call { is_expected.to raise_error ArgumentError }
    end
  end

  subject(:index) { described_class.new %w[speaker mic guitar amp] }

  its(:keys) { are_expected.to eq %w[speaker mic guitar amp] }
  its(:size) { is_expected.to eq 4 }

  describe 'Enumerable' do
    it { is_expected.to be_a Enumerable }
    its(:'each.to_a') { is_expected.to eq index.to_a }
  end

  describe '#inspect' do
    subject { index.inspect }

    context 'small index' do
      let(:index) { described_class.new %w[one two three] }

      it { is_expected.to eq '#<Daru::Index(3): {one, two, three}>' }
    end

    context 'large index' do
      let(:index) { described_class.new 'a'..'z' }

      it { is_expected.to eq '#<Daru::Index(26): {a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t ... z}>' }
    end

    context 'named index' do
      let(:index) { described_class.new %w[one two three], name: 'number'  }

      it { is_expected.to eq '#<Daru::Index(3): number {one, two, three}>' }
    end
  end

  describe '#==' do
    it { is_expected.to eq described_class.new %w[speaker mic guitar amp] }
    it { is_expected.not_to eq %w[speaker mic guitar amp] }
    it { is_expected.not_to eq described_class.new %w[speaker mic guitar amp], name: 'other' }
    it { is_expected.not_to eq described_class.new %w[speaker guitar mic amp] }
  end

  describe '#key' do
    it 'returns key by position' do
      expect(index.key(2)).to eq 'guitar'
    end

    it 'returns nil on too large pos' do
      expect(index.key(20)).to be_nil
    end

    it 'returns nil on wrong arg type' do
      expect(index.key(nil)).to be_nil
    end
  end

  describe '#sort' do
    let(:asc) { index.sort }
    let(:desc) { index.sort(ascending: false) }

    context 'string index' do
      specify { expect(asc).to eq described_class.new %w[amp guitar mic speaker] }
      specify { expect(desc).to eq described_class.new %w[speaker mic guitar amp] }
    end

    context 'number index' do
      let(:index) { described_class.new [100, 99, 101, 1, 2] }

      specify { expect(asc).to eq described_class.new [1, 2, 99, 100, 101] }
      specify { expect(desc).to eq described_class.new [101, 100, 99, 2, 1] }
    end
  end

  describe '#valid?' do
    context 'single index' do
      it { expect(index.valid?(2)).to eq true }
      it { expect(index.valid?('piano')).to eq false }
    end

    context 'multiple indexes' do
      it { expect(index.valid?('guitar', 1)).to eq true }
      it { expect(index.valid?('guitar', 8)).to eq false }
    end
  end

  describe '#&' do
    subject { left & right }

    let(:left) { described_class.new %i[miles geddy eric] }

    context 'with other Index' do
      let(:right) { described_class.new %i[geddy richie miles] }

      it { is_expected.to eq described_class.new %i[miles geddy] }
    end

    context 'with Array' do
      let(:right) { %i[bob geddy richie] }

      it { is_expected.to eq described_class.new %i[geddy] }
    end
  end

  context '#|' do
    subject { left | right }

    let(:left) { described_class.new %i[miles geddy eric] }

    context 'with other Index' do
      let(:right) { described_class.new %i[bob geddy richie] }

      it { is_expected.to eq described_class.new %i[miles geddy eric bob richie] }
    end

    context 'with Array' do
      let(:right) { %i[bob geddy richie] }

      it { is_expected.to eq described_class.new %i[miles geddy eric bob richie] }
    end
  end

  context '#[]' do
    before do
      @id = described_class.new %i[one two three four five six seven]
      @mixed_id = described_class.new ['a','b','c',:d,:a,8,3,5]
    end

    it 'works with ranges' do
      expect(@id[:two..:five]).to eq([1, 2, 3, 4])

      expect(@mixed_id['a'..'c']).to eq([0, 1, 2])

      # returns nil if first index is invalid
      # expect(@mixed_id.slice('d', 5)).to be_nil

      # returns positions till the end if first index is present
      # expect(@mixed_id.slice('c', 6)).to eq([2, 3, 4, 5, 6, 7])
    end

    it 'returns multiple keys if specified multiple indices' do
      expect(@id[:one, :two, :four, :five]).to eq([0, 1, 3, 4])
      expect(@mixed_id[0,5,3,2]).to eq([nil, 7, 6, nil])
    end

    it 'returns nil for invalid indexes' do
      expect(@id[:four]).to eq(3)
      expect(@id[3]).to be_nil
    end

    it 'returns correct index position for mixed index' do
      expect(@mixed_id[8]).to eq(5)
      expect(@mixed_id['c']).to eq(2)
    end
  end

  context '#pos' do
    let(:idx) { described_class.new [:a, :b, 1, 2] }

    context 'single index' do
      it { expect(idx.pos(:a)).to eq 0 }
    end

    context 'multiple indexes' do
      subject { idx.pos :a, 1 }

      it { is_expected.to be_a Array }
      its(:size) { is_expected.to eq 2 }
      it { is_expected.to eq [0, 2] }
    end

    context 'single positional index' do
      it { expect(idx.pos(0)).to eq 0 }
    end

    context 'multiple positional index' do
      subject { idx.pos 0, 3 }

      it { is_expected.to be_a Array }
      its(:size) { is_expected.to eq 2 }
      it { is_expected.to eq [0, 3] }
    end

    context 'range' do
      subject { idx.pos 1..3 }

      it { is_expected.to be_a Array }
      its(:size) { is_expected.to eq 3 }
      it { is_expected.to eq [1, 2, 3] }
    end
  end

  context '#subset' do
    let(:idx) { described_class.new [:a, :b, 1, 2] }

    context 'multiple indexes' do
      subject { idx.subset :a, 1 }

      it { is_expected.to be_a described_class }
      its(:size) { is_expected.to eq 2 }
      its(:to_a) { is_expected.to eq [:a, 1] }
    end

    context 'multiple positional indexes' do
      subject { idx.subset 0, 3 }

      it { is_expected.to be_a described_class }
      its(:size) { is_expected.to eq 2 }
      its(:to_a) { is_expected.to eq [:a, 2] }
    end

    context 'range' do
      subject { idx.subset 1..3 }

      it { is_expected.to be_a described_class }
      its(:size) { is_expected.to eq 3 }
      its(:to_a) { is_expected.to eq [:b, 1, 2] }
    end
  end

  context '#at' do
    let(:idx) { described_class.new [:a, :b, 1] }

    context 'single position' do
      it { expect(idx.at(1)).to eq :b }
    end

    context 'multiple positions' do
      subject { idx.at 1, 2 }

      it { is_expected.to be_a described_class }
      its(:size) { is_expected.to eq 2 }
      its(:to_a) { is_expected.to eq [:b, 1] }
    end

    context 'range' do
      subject { idx.at 1..2 }

      it { is_expected.to be_a described_class }
      its(:size) { is_expected.to eq 2 }
      its(:to_a) { is_expected.to eq [:b, 1] }
    end

    context 'range with negative integer' do
      subject { idx.at 1..-1 }

      it { is_expected.to be_a described_class }
      its(:size) { is_expected.to eq 2 }
      its(:to_a) { is_expected.to eq [:b, 1] }
    end

    context 'rangle with single element' do
      subject { idx.at 1..1 }

      it { is_expected.to be_a described_class }
      its(:size) { is_expected.to eq 1 }
      its(:to_a) { is_expected.to eq [:b] }
    end

    context 'invalid position' do
      it { expect { idx.at 3 }.to raise_error IndexError }
    end

    context 'invalid positions' do
      it { expect { idx.at 2, 3 }.to raise_error IndexError }
    end
  end

  context '#is_values' do
    let(:klass) { Daru::Vector }
    let(:idx) { described_class.new [:one, 'one', 1, 2, 'two', nil, [1, 2]] }

    context 'no arguments' do
      let(:answer) { [false, false, false, false, false, false, false] }

      it { expect(idx.is_values).to eq klass.new(answer) }
    end

    context 'single arguments' do
      let(:answer) { [false, true, false, false, false, false, false] }

      it { expect(idx.is_values('one')).to eq klass.new(answer) }
    end

    context 'multiple arguments' do
      context 'symbol and number as argument' do
        subject { idx.is_values 2, :one }

        let(:answer) { [true, false, false, true, false, false, false] }

        it { is_expected.to be_a Daru::Vector }
        its(:size) { is_expected.to eq 7 }
        it { is_expected.to eq klass.new(answer) }
      end

      context 'string and number as argument' do
        subject { idx.is_values('one', 1) }

        let(:answer) { [false, true, true, false, false, false, false] }

        it { is_expected.to be_a Daru::Vector }
        its(:size) { is_expected.to eq 7 }
        it { is_expected.to eq klass.new(answer) }
      end

      context 'nil is present in arguments' do
        subject { idx.is_values('two', nil) }

        let(:answer) { [false, false, false, false, true, true, false] }

        it { is_expected.to be_a Daru::Vector }
        its(:size) { is_expected.to eq 7 }
        it { is_expected.to eq klass.new(answer) }
      end

      context 'subarray is present in arguments' do
        subject { idx.is_values([1, 2]) }

        let(:answer) { [false, false, false, false, false, false, true] }

        it { is_expected.to be_a Daru::Vector }
        its(:size) { is_expected.to eq 7 }
        it { is_expected.to eq klass.new(answer) }
      end
    end
  end
end
