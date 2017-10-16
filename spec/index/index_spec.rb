require 'spec_helper.rb'

RSpec.describe Daru::Index do
  def method_call(object, method)
    ->(*arg) { object.send(method, *arg) }
  end

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
    its(:'each.to_a') { is_expected.to eq %w[speaker mic guitar amp] }
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
    subject { method_call(index, :key) }

    its([2]) { is_expected.to eq 'guitar' }
    its([20]) { is_expected.to be_nil }
    its([nil]) { is_expected.to be_nil }
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
    subject { method_call(index, :valid?) }

    context 'single index' do
      its([2]) { is_expected.to eq true }
      its(['piano']) { is_expected.to eq false }
    end

    context 'multiple indexes' do
      its(['guitar', 1]) { is_expected.to eq true }
      its(['guitar', 8]) { is_expected.to eq false }
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

  describe '#[]' do
    subject { method_call(index, :[]) }

    its(['mic'..'amp']) { is_expected.to eq [1, 2, 3] }
    its(%w[amp mic speaker]) { is_expected.to eq [3, 1, 0] }

    context 'first index is not valid' do
      its(['foo'..'bar']) { is_expected.to be_nil }
    end

    context 'first index is valid, second is not' do
      its(['mic'..'bar']) { is_expected.to eq [1, 2, 3] }
    end

    context 'invalid' do
      its(['piano']) { is_expected.to be_nil }
    end

    context 'mixed type index' do
      let(:index) { described_class.new ['a','b','c',:d,:a,8,3,5] }

      its(['a'..'c']) { is_expected.to eq [0, 1, 2] }
      its([0,5,3,2]) { is_expected.to eq([nil, 7, 6, nil]) }
    end
  end

  describe '#pos' do
    subject { method_call(index, :pos) }

    let(:index) { described_class.new [:a, :b, 1, 2] }

    context 'by index' do
      its([:a]) { is_expected.to eq 0 }
      its([:a, 1]) { is_expected.to eq [0, 2] }
    end

    context 'by position' do
      its([0]) { is_expected.to eq 0 }
      its([0, 3]) { is_expected.to eq [0, 3] }
    end

    its([1..3]) { is_expected.to eq [1, 2, 3] }
  end

  describe '#subset' do
    subject { method_call(idx, :subset) }

    let(:idx) { described_class.new [:a, :b, 1, 2] }

    its([:a, 1]) { is_expected.to eq described_class.new [:a, 1] }
    its([0, 3]) { is_expected.to eq described_class.new [:a, 2] }
    its([1..3]) { is_expected.to eq described_class.new [:b, 1, 2] }
  end

  describe '#at' do
    subject(:at) { method_call(idx, :at) }

    let(:idx) { described_class.new [:a, :b, 1] }

    its([1]) { is_expected.to eq :b }
    its([1, 2]) { is_expected.to eq described_class.new [:b, 1] }
    its([1..2]) { is_expected.to eq described_class.new [:b, 1] }
    its([1..-1]) { is_expected.to eq described_class.new [:b, 1] }
    its([1..1]) { is_expected.to eq described_class.new [:b] }
    it { expect { at.call(3) }.to raise_error IndexError }
    it { expect { at.call(2, 3) }.to raise_error IndexError }
  end

  describe '#is_values' do
    subject { method_call(idx, :is_values) }

    let(:idx) { described_class.new [:one, 'one', 1, 2, 'two', nil, [1, 2]] }

    its([]) { is_expected.to eq Daru::Vector.new([false, false, false, false, false, false, false]) }
    its(['one']) { is_expected.to eq Daru::Vector.new([false, true, false, false, false, false, false]) }
    its([2, :one]) { is_expected.to eq Daru::Vector.new([true, false, false, true, false, false, false]) }
    its(['one', 1]) { is_expected.to eq Daru::Vector.new([false, true, true, false, false, false, false]) }
    its(['two', nil]) { is_expected.to eq Daru::Vector.new([false, false, false, false, true, true, false]) }

    context 'subarray is present in arguments' do
      its([[1, 2]]) { is_expected.to eq Daru::Vector.new([false, false, false, false, false, false, true]) }
    end
  end

  describe '#reorder' do
    subject { index.reorder([3,0,1,2]) }

    it { is_expected.to eq described_class.new %w[amp speaker mic guitar] }

    context 'preserve name' do
      let(:index) { described_class.new %w[speaker mic guitar amp], name: 'music' }

      its(:name) { is_expected.to eq 'music' }
    end
  end
end
