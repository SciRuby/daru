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

  describe '#inspect' do
    context 'simple' do
      its(:inspect) {
        is_expected.to eq %{
        |#<Daru::Vector(3)>
        |   a   1
        |   b   2
        |   c   3
      }.unindent }
    end

    context 'with name' do
      let(:name) { 'test' }

      its(:inspect) {
        is_expected.to eq %{
        |#<Daru::Vector(3)>
        |      test
        |    a    1
        |    b    2
        |    c    3
      }.unindent }
    end

    context 'with nils' do
      let(:data) { [1, nil, 3] }

      its(:inspect) {
        is_expected.to eq %{
        |#<Daru::Vector(3)>
        |   a   1
        |   b nil
        |   c   3
      }.unindent }
    end

    context 'very large amount of data' do
      let(:data) { [1,2,3] * 100 }
      let(:name) { 'test' }
      let(:index) { nil }

      its(:inspect) {
        is_expected.to eq %{
        |#<Daru::Vector(300)>
        |      test
        |    0    1
        |    1    2
        |    2    3
        |    3    1
        |    4    2
        |    5    3
        |    6    1
        |    7    2
        |    8    3
        |    9    1
        |   10    2
        |   11    3
        |   12    1
        |   13    2
        |   14    3
        |  ...  ...
      }.unindent }
    end

    context 'really long name or data' do
      let(:data) { [1,2,'this is ridiculously long'] }
      let(:name) { 'and this is not much better faithfully' }

      its(:inspect) {
        is_expected.to eq %{
        |#<Daru::Vector(3)>
        |                      and this is not much
        |                    a                    1
        |                    b                    2
        |                    c this is ridiculously
      }.unindent }
    end

    context 'with multiindex' do
      let(:data) { [1,2,3,4,5,6,7] }
      let(:name) { 'test' }
      let(:index) {
        [
          %w[foo one],
          %w[foo two],
          %w[foo three],
          %w[bar one],
          %w[bar two],
          %w[bar three],
          %w[baz one]
        ]
      }

      its(:inspect) {
        is_expected.to eq %{
        |#<Daru::Vector(7)>
        |              test
        |   foo   one     1
        |         two     2
        |       three     3
        |   bar   one     4
        |         two     5
        |       three     6
        |   baz   one     7
      }.unindent}
    end

    context 'threshold and spacing settings'
  end

  describe '#to_s' do
    its(:to_s) { is_expected.to eq '#<Daru::Vector(3)>' }
    context 'named' do
      let(:name) { 'baz' }

      its(:to_s) { is_expected.to eq '#<Daru::Vector: baz(3)>' }
    end
  end

  describe '#type' do
    subject { ->(*data) { described_class.new(data).type } }

    its([1,2,3]) { is_expected.to eq :numeric }
    its([1,Float::NAN,nil]) { is_expected.to eq :numeric }
    its([1,2,'3']) { is_expected.to eq :object }
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

  describe '#index_of' do
    subject { method_call(vector, :index_of) }

    its([1]) { is_expected.to eq :a }
    its([4]) { is_expected.to be_nil }
  end

  describe '#has_label?' do
    subject { method_call(vector, :has_label?) }

    its([:a]) { is_expected.to be_truthy }
    its([:e]) { is_expected.to be_falsy }
  end

  describe '#count_values' do
    subject { method_call(vector, :count_values) }

    let(:data) { [1, 2, 1, '1', nil, nil, Float::NAN] }
    let(:index) { nil }

    its([1]) { is_expected.to eq 2 }
    its([nil, 2]) { is_expected.to eq 3 }
    its([Float::NAN]) { is_expected.to eq 1 }
  end

  describe '#positions' do
    subject { method_call(vector, :positions) }

    let(:data) { [1, 2, 1, '1', nil, nil, Float::NAN] }
    let(:index) { nil }

    its([1]) { is_expected.to eq [0, 2] }
    its([nil, 2]) { is_expected.to eq [1, 4, 5] }
    its([Float::NAN]) { is_expected.to eq [6] }
    its([3, 5]) { is_expected.to eq [] }
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
      subject { vector.select { |_idx, val| val.odd? } }

      it { is_expected.to eq described_class.new [1, 3], index: %i[a c] }
    end

    describe '#map' do
      subject { vector.map { |_idx, val| val + 1 } }

      it { is_expected.to eq [2, 3, 4] } # map does not preserves class
    end

    describe '#sort_by' do
      subject { vector.sort_by { |_idx, val| -val } }

      it { is_expected.to eq described_class.new [3, 2, 1], index: %i[c b a] }
    end

    describe '#uniq' do
      describe 'with block' do
        subject { vector.uniq { |_, v| v.odd? } }

        it { is_expected.to eq described_class.new [1, 2], index: %i[a b] }
      end

      describe 'without block' do
        subject { vector.uniq }

        let(:data) { [1, 1, 3] }

        it { is_expected.to eq described_class.new [1, 3], index: %i[a c] }
      end
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

  describe '#include_values?' do
    subject { method_call(vector, :include_values?) }

    let(:data) { [1, Float::NAN, nil] }

    its([1, nil]) { is_expected.to be_truthy }
    its([2, Float::NAN]) { is_expected.to be_truthy }
    its([2]) { is_expected.to be_falsy }
  end

  # mutable behavior
  describe '#[]='

  describe '#reindex!' do
    subject { ->(*values) { vector.reindex!(Daru::Index.new(values)) } }

    its(%i[c b a]) { is_expected.to eq described_class.new [3, 2, 1], index: %i[c b a] }
    its(%i[c a]) { is_expected.to eq described_class.new [3, 1], index: %i[c a] }
    its(%i[a d f]) { is_expected.to eq described_class.new [1, nil, nil], index: %i[a d f] }
  end

  describe '#reorder!' do
    subject { ->(*values) { vector.reorder!(values) } }

    its([0, 2, 1]) { is_expected.to eq described_class.new [1, 3, 2], index: %i[a c b] }
    its([0, 1]) { is_expected.to eq described_class.new [1, 2], index: %i[a b] }
    its([0, 2, 4]) { is_expected.to eq described_class.new [1, 3, nil], index: [:a, :c, nil] }

    # TODO: what is reasonable behavior here?
    # its([4, 8, 16]) { is_expected.to eq described_class.empty }
  end

  describe '#reset_index!' do
    subject { vector.reset_index! }

    it { is_expected.to eq described_class.new data, index: [0, 1, 2] }
  end

  describe '#rolling_fillna!' do
    let(:data) { [Float::NAN, 2, 1, 4, nil, Float::NAN, 3, nil, Float::NAN] }
    let(:index) { nil }

    context 'forward' do
      before { vector.rolling_fillna! }

      it { is_expected.to eq described_class.new [0, 2, 1, 4, 4, 4, 3, 3, 3] }
    end

    context 'backward' do
      before { vector.rolling_fillna!(:backward) }

      it { is_expected.to eq described_class.new [2, 2, 1, 4, 3, 3, 3, 0, 0] }
    end

    context 'all empty' do
      let(:data) { [Float::NAN, nil, Float::NAN] }

      before { vector.rolling_fillna! }

      it { is_expected.to eq described_class.new [0, 0, 0] }
    end
  end

  describe '#lag!' do
    subject { method_call(vector, :lag!) }

    its([0]) { is_expected.to eq described_class.new [1, 2, 3], index: %i[a b c] }
    its([1]) { is_expected.to eq described_class.new [nil, 1, 2], index: %i[a b c] }
    its([-1]) { is_expected.to eq described_class.new [2, 3, nil], index: %i[a b c] }
    its([100]) { is_expected.to eq described_class.new [nil, nil, nil], index: %i[a b c] }
  end
end
