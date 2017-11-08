RSpec.describe Daru::Vector do
  def vec(*arg)
    described_class.new(*arg)
  end

  subject(:vector) { vec(data, index: index, name: name) }

  let(:data) { [1, 2, 3] }
  let(:index) { %i[a b c] }
  let(:name) { nil }

  its(:size) { is_expected.to eq 3 }
  its(:to_a) { is_expected.to eq [1, 2, 3] }
  its(:to_h) { is_expected.to eq(a: 1, b: 2, c: 3) }

  describe '#initialize' do
    context 'from array' do
      subject { vec [1, 2, 3] }

      its(:to_a) { is_expected.to eq [1, 2, 3] }
      its(:index) { is_expected.to eq Daru::Index.new [0, 1, 2] }

      context 'with index' do
        subject { vec [1, 2, 3], index: Daru::Index.new(%i[a b c]) }

        its(:index) { is_expected.to eq Daru::Index.new %i[a b c] }
      end

      context 'with index to be coerced' do
        subject { vec [1, 2, 3], index: %i[a b c] }

        its(:index) { is_expected.to eq Daru::Index.new %i[a b c] }
      end

      context 'too small index' do
        subject { vec [1, 2, 3], index: %i[a b] }

        its_block { is_expected.to raise_error(ArgumentError, /Expected index size >= vector size./) }
      end

      context 'too large index' do
        subject { vec [1, 2, 3], index: %i[a b c d e] }

        its(:to_a) { is_expected.to eq [1, 2, 3, nil, nil] }
        its(:index) { is_expected.to eq Daru::Index.new %i[a b c d e] }
      end
    end

    context 'from hash' do
      subject { vec(a: 1, b: 2, c: 3) }

      its(:to_a) { is_expected.to eq [1, 2, 3] }
      its(:index) { is_expected.to eq Daru::Index.new %i[a b c] }

      context 'with name' do
        subject { vec({a: 1, b: 2, c: 3}, name: 'foo') }

        its(:name) { is_expected.to eq 'foo' }
      end

      context 'with index' # TODO: should raise
    end

    context 'from enumerable' do
      subject { vec 1..3 }

      its(:to_a) { is_expected.to eq [1, 2, 3] }
      its(:index) { is_expected.to eq Daru::Index.new [0, 1, 2] }
    end
  end

  describe '#==' do
    it { is_expected.to eq vec(data, index: index, name: name) }
    it { is_expected.not_to eq vec(data, index: index.reverse, name: name) }
    it { is_expected.not_to eq vec(data.reverse, index: index, name: name) }
    it { is_expected.to eq vec(data, index: index, name: 'foobar') } # name doesn't matter, data matters
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
    subject { ->(*data) { vec(data).type } }

    its_call(1,2,3) { is_expected.to ret :numeric }
    its_call(1,Float::NAN,nil) { is_expected.to ret :numeric }
    its_call(1,2,'3') { is_expected.to ret :object }
  end

  describe '#[]' do
    context 'by index' do
      its([:a]) { is_expected.to eq 1 }
      it { expect { vector[:d] }.to raise_error(IndexError) }
      its(%i[b c]) { is_expected.to eq vec [2, 3], index: %i[b c] }
      its([:a..:c]) { is_expected.to eq vec [1, 2, 3], index: %i[a b c] }
      its([:a...:c]) { is_expected.to eq vec [1, 2], index: %i[a b] }
    end

    context 'by MultiIndex' do
      let(:data) { 1..4 }
      let(:index) { Daru::MultiIndex.new [%w[India Delhi], %w[India Pune], %w[Ukraine Kyiv], %w[Ukraine Kharkiv]] }

      its(%w[Ukraine Kharkiv]) { is_expected.to eq 4 }
      its(%w[Ukraine]) { is_expected.to eq vec [3, 4], index: Daru::MultiIndex.new([%w[Ukraine Kyiv], %w[Ukraine Kharkiv]]) }
    end

    context 'by DateTimeIndex'

    context 'by numeric position' do
      its([0]) { is_expected.to eq 1 }
      its([1, 2]) { is_expected.to eq vec [2, 3], index: %i[b c] }
      its([0..2]) { is_expected.to eq vec [1, 2, 3], index: %i[a b c] }
      its([0...2]) { is_expected.to eq vec [1, 2], index: %i[a b] }
    end
  end

  describe '#at' do
    subject { vector.method(:at) }

    its_call(1) { is_expected.to ret 2 }
    its_call(1, 2) { is_expected.to ret vec [2, 3], index: %i[b c] }
    its_call(7) { is_expected.to raise_error IndexError }
  end

  describe '#index_of' do
    subject { vector.method(:index_of) }

    its_call(1) { is_expected.to ret :a }
    its_call(4) { is_expected.to ret be_nil }
  end

  describe '#has_label?' do
    subject { vector.method(:has_label?) }

    its_call(:a) { is_expected.to ret be_truthy }
    its_call(:e) { is_expected.to ret be_falsy }
  end

  describe '#count_values' do
    subject { vector.method(:count_values) }

    let(:data) { [1, 2, 1, '1', nil, nil, Float::NAN] }
    let(:index) { nil }

    its_call(1) { is_expected.to ret 2 }
    its_call(nil, 2) { is_expected.to ret 3 }
    its_call(Float::NAN) { is_expected.to ret 1 }
  end

  describe '#positions' do
    subject { vector.method(:positions) }

    let(:data) { [1, 2, 1, '1', nil, nil, Float::NAN] }
    let(:index) { nil }

    its_call(1) { is_expected.to ret [0, 2] }
    its_call(nil, 2) { is_expected.to ret [1, 4, 5] }
    its_call(Float::NAN) { is_expected.to ret [6] }
    its_call(3, 5) { is_expected.to ret [] }
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
      subject { vector.method(:first) }

      its_call(2) { is_expected.to ret vec [1, 2], index: %i[a b] }
      # its([]) { is_expected.to eq 1 } -- TODO
    end

    describe '#select' do
      subject { vector.select { |_idx, val| val.odd? } }

      it { is_expected.to eq vec [1, 3], index: %i[a c] }
    end

    describe '#map' do
      subject { vector.map { |_idx, val| val + 1 } }

      it { is_expected.to eq [2, 3, 4] } # map does not preserves class
    end

    describe '#sort_by' do
      subject { vector.sort_by { |_idx, val| -val } }

      it { is_expected.to eq vec [3, 2, 1], index: %i[c b a] }
    end

    describe '#uniq' do
      describe 'with block' do
        subject { vector.uniq { |_, v| v.odd? } }

        it { is_expected.to eq vec [1, 2], index: %i[a b] }
      end

      describe 'without block' do
        subject { vector.uniq }

        let(:data) { [1, 1, 3] }

        it { is_expected.to eq vec [1, 3], index: %i[a c] }
      end
    end
  end

  describe '#sort_by_index' do
    subject { vector.sort_by_index }

    let(:index) { %i[c a b] }

    it { is_expected.to eq vec [2, 3, 1], index: %i[a b c] }
  end

  describe '#recode!' do
    before { vector.recode! { |val| val + 1 } }

    it { is_expected.to eq vec [2, 3, 4], index: %i[a b c] }
  end

  describe '#recode' do
    subject { vector.recode { |val| val + 1 } }

    it { is_expected.to eq vec [2, 3, 4], index: %i[a b c] }
  end

  describe '#reindex'

  describe '#reorder'

  describe '#select_values'

  describe '#reject_values'

  describe '#replace_values'

  describe '#include_values?' do
    subject { vector.method(:include_values?) }

    let(:data) { [1, Float::NAN, nil] }

    its_call(1, nil) { is_expected.to ret be_truthy }
    its_call(2, Float::NAN) { is_expected.to ret be_truthy }
    its_call(2) { is_expected.to ret be_falsy }
  end

  # mutable behavior
  describe '#[]=' do
    # set value at labels and check the resulting vector
    subject { ->(*labels) { vector.tap { vector[*labels] = value }  } }
    let(:value) { 'x' }

    context 'by index' do
      its_call(:a) { is_expected.to ret vec ['x', 2, 3], index: %i[a b c] }
      its_call(:d) { is_expected.to raise_error(IndexError) }
      its_call(:b, :c) { is_expected.to ret vec [1, 'x', 'x'], index: %i[a b c] }
      its_call(:a..:c) { is_expected.to ret vec %w[x x x], index: %i[a b c] }
      its_call(:a...:c) { is_expected.to ret vec ['x', 'x', 3], index: %i[a b c] }
    end

    context 'by MultiIndex' do
      let(:data) { 1..4 }
      let(:index) { Daru::MultiIndex.new [%w[India Delhi], %w[India Pune], %w[Ukraine Kyiv], %w[Ukraine Kharkiv]] }

      its(%w[Ukraine Kharkiv]) { is_expected.to eq vec [1, 2, 3, 'x'], index: index }
      its(%w[Ukraine]) { is_expected.to eq vec [1, 2, 'x', 'x'], index: index }
    end

    context 'by DateTimeIndex'

    context 'by numeric position' do
      its_call(0) { is_expected.to ret vec ['x', 2, 3], index: %i[a b c] }
      its_call(1, 2) { is_expected.to ret vec [1, 'x', 'x'], index: %i[a b c] }
      its_call(0..2) { is_expected.to ret vec %w[x x x], index: %i[a b c] }
      its_call(0...2) { is_expected.to ret vec ['x', 'x', 3], index: %i[a b c] }
    end
  end

  describe '#reindex!' do
    subject { ->(*values) { vector.reindex!(Daru::Index.new(values)) } }

    its_call(:c, :b, :a) { is_expected.to ret vec [3, 2, 1], index: %i[c b a] }
    its_call(:c, :a) { is_expected.to ret vec [3, 1], index: %i[c a] }
    its_call(:a, :d, :f) { is_expected.to ret vec [1, nil, nil], index: %i[a d f] }
  end

  describe '#reorder!' do
    subject { ->(*values) { vector.reorder!(values) } }

    its_call(0, 2, 1) { is_expected.to ret vec [1, 3, 2], index: %i[a c b] }
    its_call(0, 1) { is_expected.to ret vec [1, 2], index: %i[a b] }
    its_call(0, 2, 4) { is_expected.to ret vec [1, 3, nil], index: [:a, :c, nil] }

    # TODO: what is reasonable behavior here?
    # its([4, 8, 16]) { is_expected.to eq described_class.empty }
  end

  describe '#reset_index!' do
    subject { vector.reset_index! }

    it { is_expected.to eq vec data, index: [0, 1, 2] }
  end

  describe '#rolling_fillna!' do
    let(:data) { [Float::NAN, 2, 1, 4, nil, Float::NAN, 3, nil, Float::NAN] }
    let(:index) { nil }

    context 'forward' do
      before { vector.rolling_fillna! }

      it { is_expected.to eq vec [0, 2, 1, 4, 4, 4, 3, 3, 3] }
    end

    context 'backward' do
      before { vector.rolling_fillna!(:backward) }

      it { is_expected.to eq vec [2, 2, 1, 4, 3, 3, 3, 0, 0] }
    end

    context 'all empty' do
      let(:data) { [Float::NAN, nil, Float::NAN] }

      before { vector.rolling_fillna! }

      it { is_expected.to eq vec [0, 0, 0] }
    end
  end

  describe '#lag!' do
    subject { vector.method(:lag!) }

    its_call(0) { is_expected.to ret vec [1, 2, 3], index: %i[a b c] }
    its_call(1) { is_expected.to ret vec [nil, 1, 2], index: %i[a b c] }
    its_call(-1) { is_expected.to ret vec [2, 3, nil], index: %i[a b c] }
    its_call(100) { is_expected.to ret vec [nil, nil, nil], index: %i[a b c] }
  end
end
