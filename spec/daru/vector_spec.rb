RSpec.describe Daru::Vector do
  subject(:vector) { described_class.new(data, index: index, name: name) }

  let(:data) { [1, 2, 3] }
  let(:index) { %i[a b c] }
  let(:name) { nil }

  its(:size) { is_expected.to eq 3 }
  its(:to_a) { is_expected.to eq [1, 2, 3] }
  its(:to_h) { is_expected.to eq(a: 1, b: 2, c: 3) }

  describe '#initialize' do
    context 'from array' do
      subject { described_class.new [1, 2, 3] }

      its(:to_a) { is_expected.to eq [1, 2, 3] }
      its(:index) { is_expected.to eq Daru::Index.new [0, 1, 2] }

      context 'with index' do
        subject { described_class.new [1, 2, 3], index: Daru::Index.new(%i[a b c]) }

        its(:index) { is_expected.to eq Daru::Index.new %i[a b c] }
      end

      context 'with index to be coerced' do
        subject { described_class.new [1, 2, 3], index: %i[a b c] }

        its(:index) { is_expected.to eq Daru::Index.new %i[a b c] }
      end

      context 'too small index' do
        subject { described_class.new [1, 2, 3], index: %i[a b] }

        its_call { is_expected.to raise_error(ArgumentError, /Expected index size >= vector size./) }
      end

      context 'too large index' do
        subject { described_class.new [1, 2, 3], index: %i[a b c d e] }

        its(:to_a) { is_expected.to eq [1, 2, 3, nil, nil] }
        its(:index) { is_expected.to eq Daru::Index.new %i[a b c d e] }
      end
    end

    context 'from hash' do
      subject { described_class.new(a: 1, b: 2, c: 3) }

      its(:to_a) { is_expected.to eq [1, 2, 3] }
      its(:index) { is_expected.to eq Daru::Index.new %i[a b c] }

      context 'with name' do
        subject { described_class.new({a: 1, b: 2, c: 3}, name: 'foo') }

        its(:name) { is_expected.to eq 'foo' }
      end

      context 'with index' # TODO: should raise
    end

    context 'from enumerable' do
      subject { described_class.new 1..3 }

      its(:to_a) { is_expected.to eq [1, 2, 3] }
      its(:index) { is_expected.to eq Daru::Index.new [0, 1, 2] }
    end
  end

  describe '#==' do
    it { is_expected.to eq described_class.new(data, index: index, name: name) }
    it { is_expected.not_to eq described_class.new(data, index: index.reverse, name: name) }
    it { is_expected.not_to eq described_class.new(data.reverse, index: index, name: name) }
    it { is_expected.to eq described_class.new(data, index: index, name: 'foobar') } # name doesn't matter, data matters
  end

  describe '#inspect'

  describe '#to_s' do
    its(:to_s) { is_expected.to eq '#<Daru::Vector(3)>' }
    context 'named' do
      let(:name) { 'baz' }

      its(:to_s) { is_expected.to eq '#<Daru::Vector: baz(3)>' }
    end
  end

  describe '#[]' do
    context 'by index' do
      its([:a]) { is_expected.to eq 1 }
      it { expect { vector[:d] }.to raise_error(IndexError) }
      its(%i[b c]) { is_expected.to eq described_class.new [2, 3], index: %i[b c] }
      its([:a..:c]) { is_expected.to eq described_class.new [1, 2, 3], index: %i[a b c] }
      its([:a...:c]) { is_expected.to eq described_class.new [1, 2], index: %i[a b] }
    end

    context 'by MultiIndex' do
      let(:data) { 1..4 }
      let(:index) { Daru::MultiIndex.new [%w[India Delhi], %w[India Pune], %w[Ukraine Kyiv], %w[Ukraine Kharkiv]] }

      its(%w[Ukraine Kharkiv]) { is_expected.to eq 4 }
      its(%w[Ukraine]) { is_expected.to eq described_class.new [3, 4], index: Daru::MultiIndex.new([%w[Ukraine Kyiv], %w[Ukraine Kharkiv]]) }
    end

    context 'by DateTimeIndex'

    context 'by numeric position' do
      its([0]) { is_expected.to eq 1 }
      its([1, 2]) { is_expected.to eq described_class.new [2, 3], index: %i[b c] }
      its([0..2]) { is_expected.to eq described_class.new [1, 2, 3], index: %i[a b c] }
      its([0...2]) { is_expected.to eq described_class.new [1, 2], index: %i[a b] }
    end
  end

  describe '#at' do
    subject { method_call(vector, :at) }

    its([1]) { is_expected.to eq 2 }
    its([1, 2]) { is_expected.to eq described_class.new [2, 3], index: %i[b c] }
    it { expect { vector.at(7) }.to raise_error IndexError }
  end

  describe '#each' do
    context 'without block' do
      its(:each) { is_expected.to be_a Enumerator }
    end

    context 'with block' do
      subject { ->(block) { vector.each(&block) } }

      it { is_expected.to yield_successive_args([:a, 1], [:b, 2], [:c, 3]) }
    end
  end

  describe 'Enumerable' do
    describe '#first(N)' do
      subject { method_call(vector, :first) }

      its([2]) { is_expected.to eq described_class.new [1, 2], index: %i[a b] }
      # its([]) { is_expected.to eq 1 } -- TODO
    end

    describe '#select' do
      subject { vector.select { |idx, val| val.odd? } }

      it { is_expected.to eq described_class.new [1, 3], index: %i[a c] }
    end

    describe '#map' do
      subject { vector.map { |idx, val| val + 1 } }

      it { is_expected.to eq [2, 3, 4] } # map does not preserves class
    end

    describe '#sort_by' do
      subject { vector.sort_by { |idx, val| -val } }

      it { is_expected.to eq described_class.new [3, 2, 1], index: %i[c b a] }
    end
  end

  describe '#sort_by_index' do
    subject { vector.sort_by_index }

    let(:index) { %i[c a b] }

    it { is_expected.to eq described_class.new [2, 3, 1], index: %i[a b c] }
  end

  describe '#recode!' do
    before { vector.recode! { |val| val + 1 } }

    it { is_expected.to eq described_class.new [2, 3, 4], index: %i[a b c] }
  end

  describe '#recode' do
    subject { vector.recode { |val| val + 1 } }

    it { is_expected.to eq described_class.new [2, 3, 4], index: %i[a b c] }
  end

  describe '#reindex'

  describe '#reorder'

  describe '#select_values'

  describe '#reject_values'

  describe '#replace_values'

  # mutable part
  describe '#[]='
end
