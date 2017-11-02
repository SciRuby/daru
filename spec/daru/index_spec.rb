RSpec.describe Daru::Index do
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

      its_block { is_expected.to raise_error ArgumentError }
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

    xcontext 'with nils' do # TODO
      let(:index) { described_class.new ['one', 1, nil] }

      it { is_expected.to eq '#<Daru::Index(3): {one, 1, nil}>' }
    end
  end

  describe '#==' do
    it { is_expected.to eq described_class.new %w[speaker mic guitar amp] }
    it { is_expected.not_to eq %w[speaker mic guitar amp] }
    it { is_expected.not_to eq described_class.new %w[speaker mic guitar amp], name: 'other' }
    it { is_expected.not_to eq described_class.new %w[speaker guitar mic amp] }
  end

  describe '#key' do
    subject { index.method(:key) }

    its_call(2) { is_expected.to ret 'guitar' }
    its_call(20) { is_expected.to ret nil }
    its_call('guitar') { is_expected.to ret nil }
  end

  describe '#[]' do
    subject { index.method(:[]) }

    its_call('mic'..'amp') { is_expected.to ret [1, 2, 3] }
    its_call('mic'...'amp') { is_expected.to ret [1, 2] }
    its_call('amp'..'mic') { is_expected.to ret [] }
    its_call(*%w[amp mic speaker piano]) { is_expected.to ret [3, 1, 0, nil] }

    context 'first index is not valid' do
      its_call('foo'..'bar') { is_expected.to ret nil }
    end

    context 'first index is valid, second is not' do
      its_call('mic'..'bar') { is_expected.to ret [1, 2, 3] }
    end

    context 'invalid' do
      its_call('piano') { is_expected.to ret nil }
    end

    context 'mixed type index' do
      let(:index) { described_class.new ['a','b','c',:d,:a,8,3,5] }

      its_call('a'..'c') { is_expected.to ret [0, 1, 2] }
      its_call(0,5,3,2) { is_expected.to ret [nil, 7, 6, nil] }
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

  xdescribe '#valid?' do
    subject { index.method(:valid?) }

    context 'single index' do
      its_call(2) { is_expected.to ret true }
      its_call('piano') { is_expected.to ret false }
    end

    context 'multiple indexes' do
      its_call('guitar', 1) { is_expected.to ret true }
      its_call('guitar', 8) { is_expected.to ret false }
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

  describe '#|' do
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

  describe '#pos' do
    subject { index.method(:pos) }

    let(:index) { described_class.new [:a, :b, 1, 2] }

    context 'by label' do
      its_call(:a) { is_expected.to ret 0 }
      its_call(:a, 1) { is_expected.to ret [0, 2] }

      # it is treated as labels!
      its_call(1..3) { is_expected.to ret [2, 3] }

      its_call(:c) { is_expected.to raise_error(IndexError, 'Undefined index label: :c') }
      its_call(:a, :c) { is_expected.to raise_error(IndexError, 'Undefined index label: :c') }
    end

    context 'by position' do
      its_call(0) { is_expected.to ret 0 }
      its_call(0, 3) { is_expected.to ret [0, 3] }
      its_call(0..-1) { is_expected.to ret [0, 1, 2, 3] }

      its_call(6) { is_expected.to raise_error(IndexError, 'Invalid index position: 6') }
      its_call(0, 6) { is_expected.to raise_error(IndexError, 'Invalid index position: 6') }
    end
  end

  xdescribe '#subset' do
    subject { idx.method(:subset) }

    let(:idx) { described_class.new [:a, :b, 1, 2] }

    its_call(:a, 1) { is_expected.to ret described_class.new [:a, 1] }
    its_call(0, 3) { is_expected.to ret described_class.new [:a, 2] }
    its_call(1..3) { is_expected.to ret described_class.new [:b, 1, 2] }
  end

  describe '#at' do
    subject { idx.method(:at) }

    let(:idx) { described_class.new [:a, :b, 1] }

    its_call(1) { is_expected.to ret :b }
    its_call(1, 2) { is_expected.to ret described_class.new [:b, 1] }
    its_call(1..2) { is_expected.to ret described_class.new [:b, 1] }
    its_call(1..-1) { is_expected.to ret described_class.new [:b, 1] }
    its_call(1..1) { is_expected.to ret described_class.new [:b] }
    its_call(3) { is_expected.to raise_error IndexError }
    its_call(2, 3) { is_expected.to raise_error IndexError }
  end

  describe '#is_values' do
    subject { idx.method(:is_values) }

    let(:idx) { described_class.new [:one, 'one', 1, 2, 'two', nil, [1, 2]] }

    it { is_expected.to ret [false, false, false, false, false, false, false] }
    its_call('one') { is_expected.to ret [false, true, false, false, false, false, false] }
    its_call(2, :one) { is_expected.to ret [true, false, false, true, false, false, false] }
    its_call('one', 1) { is_expected.to ret [false, true, true, false, false, false, false] }
    its_call('two', nil) { is_expected.to ret [false, false, false, false, true, true, false] }
    its_call([1, 2]) { is_expected.to ret [false, false, false, false, false, false, true] }
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
