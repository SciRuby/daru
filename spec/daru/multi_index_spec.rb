RSpec.describe Daru::MultiIndex do
  subject(:index) { described_class.new data }

  let(:data) {
    [
      %i[a one],
      %i[a two],
      %i[b one],
      %i[b two],
      %i[c one],
      %i[c two]
    ]
  }

  describe '#initialize' do
    subject { described_class.new data }

    its(:labels) { are_expected.to eq data }
    its(:width) { is_expected.to eq 2 }
    its(:to_a) { is_expected.to eq data }

    its(:relations_hash) {
      is_expected
        .to eq(a: {
                 one: 0,
                 two: 1
               },
               b: {
                 one: 2,
                 two: 3
               },
               c: {
                 one: 4,
                 two: 5
               })
    }

    context 'attempt to create one-level MultiIndex' do
      let(:data) { [[1], [2], [3]] }

      its_call { is_expected.to raise_error ArgumentError, 'MultiIndex should contain at least 2 values in each label' }
    end

    context 'different sizes of labels' do
      let(:data) { [%i[a one], %i[b two foo]] }

      its_call { is_expected.to raise_error ArgumentError, 'Different MultiIndex label sizes: [:a, :one], [:b, :two, :foo]' }
    end

    context 'non-uniq data' do
      let(:data) { [%i[a one], %i[a two], %i[a one]] }

      its(:labels) { are_expected.to eq([%i[a one], %i[a two]]) }
    end
  end

  describe '#inspect' do
    context 'small index' do
      let(:data) {
        [
          %i[a one bar],
          %i[a one baz],
          %i[a two bar],
          %i[a two baz],
          %i[b one bar],
          %i[b two bar],
          %i[b two baz],
          %i[b one foo],
          %i[c one bar],
          %i[c one baz],
          %i[c two foo],
          %i[c two bar]
        ]
      }

      its(:inspect) {
        is_expected.to eq %{
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
      let(:data) { (1..100).flat_map { |i| %w[a b c].map { |c| [i, c] } } }

      its(:inspect) {
        is_expected.to eq %{
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

    context 'named index' do
      subject { described_class.new(data, name: %w[n1 n2]) }

      its(:inspect) {
        is_expected.to start_with %{
        |#<Daru::MultiIndex(6x2)>
        |  n1  n2
        }.unindent
      }
    end

    context 'multi index with name having empty string' do
      subject { described_class.new(data, name: ['', 'n2']) }

      its(:inspect) {
        is_expected.to start_with %{
        |#<Daru::MultiIndex(6x2)>
        |      n2
        }.unindent
      }
    end
  end

  describe '#==' do
    it { is_expected.to eq described_class.new(data) }
    it { is_expected.not_to eq described_class.new(data.reverse) }
    it { is_expected.not_to eq Daru::Index.new(data.map(&:first)) }
  end

  describe '#label' do
    subject { method_call(index, :label) }

    its([3]) { is_expected.to eq %i[b two] }
    its([20]) { is_expected.to be_nil }
  end

  describe '#pos' do
    subject { method_call(index, :pos) }

    context 'by labels' do
      context 'single row' do
        its(%i[a two]) { is_expected.to eq 1 }
      end

      context 'entire sub-level of index' do
        its(%i[b]) { is_expected.to eq [2, 3] }
      end

      context 'not found' do
        it { expect { index.pos(:d) }.to raise_error IndexError, 'Undefined index label: [:d]' }
      end
    end

    context 'by positions' do
      its([0]) { is_expected.to eq 0 }
      its([1..3]) { is_expected.to eq [1, 2, 3] }
      its([1...3]) { is_expected.to eq [1, 2] }
      its([1, 2]) { is_expected.to eq [1, 2] }

      context 'too large' do
        it { expect { index.pos(10) }.to raise_error IndexError, 'Invalid index position: 10' }
      end
    end
  end
end
