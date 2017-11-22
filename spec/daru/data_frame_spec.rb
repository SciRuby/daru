RSpec.describe Daru::DataFrame do
  def df(*arg)
    described_class.new(*arg)
  end

  def vec(*arg)
    Daru::Vector.new(*arg)
  end

  def idx(*arg)
    Daru::Index.new(*arg)
  end

  describe '#initialize' do
    context 'empty' do
      subject { described_class.new }

      its(:index) { is_expected.to eq idx [] }
      its(:vectors) { is_expected.to eq idx [] }
      its(:data) { is_expected.to eq [] }
    end

    context 'from hash' do
      subject { described_class.new({a: [1, 2, 3], b: [4, 5, 6]}, index: %i[x y z]) }

      its(:index) { is_expected.to eq idx %i[x y z] }
      its(:vectors) { is_expected.to eq idx %i[a b] }
      its(:data) { is_expected.to eq [vec([1,2,3], index: %i[x y z]), vec([4,5,6], index: %i[x y z])] }

      context 'implicit index' do
        subject { described_class.new({a: [1, 2, 3], b: [4, 5, 6]}, {}) } # FIXME: this second {} is unacceptable!

        its(:index) { is_expected.to eq idx [0, 1, 2] }
        its(:vectors) { is_expected.to eq idx %i[a b] }
        its(:data) { is_expected.to eq [vec([1,2,3], index: [0, 1, 2]), vec([4,5,6], index: [0, 1, 2])] }
      end

      # TODO:
      # * different types of column (range, vector + deduce index from vectors);
      # * different shapes of data
    end

    context 'from array of hashes' do
      subject { described_class.new([{a: 1, b: 2}, {b: 3, a: 4, c: 5}, {c: 0}], index: %i[x y z]) }

      # FIXME: that's how it works now, but that's wrong, I'd expect
      #     a    b    c
      #  x  1    2    nil
      #  y  4    3    5
      #  z  nil  nil  0
      its(:index) { is_expected.to eq idx %i[x y z] }
      its(:vectors) { is_expected.to eq idx %i[a b] }
      its(:data) { is_expected.to eq [vec([1,4,nil], index: %i[x y z]), vec([2,3,nil], index: %i[x y z])] }
    end

    context 'from array of arrays' do
      subject { described_class.new([[1, 2, 3], [4, 5, 6]], index: %i[x y z]) }

      # FIXME: really?.. I'd say array of arrays is a list of rows... :philosoraptor:
      # Maybe that's for consistency with "array of vectors" situation
      its(:index) { is_expected.to eq idx %i[x y z] }
      its(:vectors) { is_expected.to eq idx [0, 1] }
      its(:data) { is_expected.to eq [vec([1,2,3], index: %i[x y z]), vec([4, 5, 6], index: %i[x y z])] }
    end

    context 'from array of vector' do
      subject { described_class.new([vec([1, 2, 3], name: 'first'), vec([4, 5, 6], name: 'second')], index: %i[x y z]) }

      its(:index) { is_expected.to eq idx %i[x y z] }
      its(:vectors) { is_expected.to eq idx %w[first second] }

      # TODO: It should copy index to vectors, but it does not
      # its(:data) { is_expected.to eq [vec([1,2,3], index: %i[x y z]), vec([4, 5, 6], index: %i[x y z])] }

      # TODO: deduce index
    end

    # TODO: providing different types of indexes for index and order
  end

  describe '#=='

  describe '#inspect' do
    subject { df.inspect }

    context 'empty' do
      let(:df) { described_class.new({}, order: %w[a b c]) }

      it {
        is_expected.to eq %{
          |#<Daru::DataFrame(0x3)>
          |   a   b   c
        }.unindent
      }
    end

    context 'simple' do
      let(:df) { described_class.new({a: [1,2,3], b: [3,4,5], c: [6,7,8]}, name: 'test') }

      it {
        is_expected.to eq %{
        |#<Daru::DataFrame: test (3x3)>
        |       a   b   c
        |   0   1   3   6
        |   1   2   4   7
        |   2   3   5   8
       }.unindent}
    end

    context 'if index name is set' do
      xcontext 'single index with name' do
        let(:df) { described_class.new({a: [1,2,3], b: [3,4,5], c: [6,7,8]}, name: 'test') }

        it {
          is_expected.to eq %{
          |#<Daru::DataFrame: test (3x3)>
          | index_name          a          b          c
          |          0          1          3          6
          |          1          2          4          7
          |          2          3          5          8
         }.unindent}
      end

      context 'MultiIndex with name' do
        let(:index) {
          Daru::MultiIndex.new(
            [%i[a one], %i[a two], %i[b one], %i[b two], %i[c one], %i[c two]],
            name: %w[s1 s2]
          )
        }
        let(:df) {
          described_class.new({a: [11, 12, 13, 14, 15, 16], b: [21, 22, 23, 24, 25, 26]},
            name: 'test', index: index)
        }

        it {
          is_expected.to eq %{
          |#<Daru::DataFrame: test (6x2)>
          |  s1  s2   a   b
          |   a one  11  21
          |     two  12  22
          |   b one  13  23
          |     two  14  24
          |   c one  15  25
          |     two  16  26
         }.unindent}
      end
    end

    context 'no name' do
      let(:df) { described_class.new({a: [1,2,3], b: [3,4,5], c: [6,7,8]}, {}) }

      it {
        is_expected.to eq %{
        |#<Daru::DataFrame(3x3)>
        |       a   b   c
        |   0   1   3   6
        |   1   2   4   7
        |   2   3   5   8
       }.unindent}
    end

    context 'with nils' do
      let(:df) { described_class.new({a: [1,nil,3], b: [3,4,5], c: [6,7,nil]}, name: 'test') }

      it {
        is_expected.to eq %{
        |#<Daru::DataFrame: test (3x3)>
        |       a   b   c
        |   0   1   3   6
        |   1 nil   4   7
        |   2   3   5 nil
       }.unindent}
    end

    context 'very long' do
      let(:df) { described_class.new({a: [1,1,1]*20, b: [1,1,1]*20, c: [1,1,1]*20}, name: 'test') }

      it {
        is_expected.to eq %{
        |#<Daru::DataFrame: test (60x3)>
        |       a   b   c
        |   0   1   1   1
        |   1   1   1   1
        |   2   1   1   1
        |   3   1   1   1
        |   4   1   1   1
        |   5   1   1   1
        |   6   1   1   1
        |   7   1   1   1
        |   8   1   1   1
        |   9   1   1   1
        |  10   1   1   1
        |  11   1   1   1
        |  12   1   1   1
        |  13   1   1   1
        |  14   1   1   1
        | ... ... ... ...
       }.unindent}
    end

    context 'long data lines' do
      let(:df) { described_class.new({a: [1,2,3], b: [4,5,6], c: ['this is ridiculously long',nil,nil]}, name: 'test') }

      it {
        is_expected.to eq %{
        |#<Daru::DataFrame: test (3x3)>
        |                     a          b          c
        |          0          1          4 this is ri
        |          1          2          5        nil
        |          2          3          6        nil
       }.unindent}
    end

    context 'index is a MultiIndex' do
      let(:df) {
        described_class.new(
          {
            a:   [1,2,3,4,5,6,7],
            b: %w[a b c d e f g]
          }, index: Daru::MultiIndex.new([
                                           %w[foo one],
                                           %w[foo two],
                                           %w[foo three],
                                           %w[bar one],
                                           %w[bar two],
                                           %w[bar three],
                                           %w[baz one]
                                         ]),
             name: 'test'
        )
      }

      it {
        is_expected.to eq %{
        |#<Daru::DataFrame: test (7x2)>
        |                 a     b
        |   foo   one     1     a
        |         two     2     b
        |       three     3     c
        |   bar   one     4     d
        |         two     5     e
        |       three     6     f
        |   baz   one     7     g
      }.unindent}
    end

    context 'vectors is a MultiIndex'

    context 'spacing and threshold settings'
  end

  describe '#to_s'

  subject(:dataframe) {
    described_class.new(
      {
        Ukraine: [51_838, 49_429, 45_962],
        India: [873_785, 1_053_898, 1_182_108],
        Argentina: [32_730, 37_057, 41_223]
      },
      index: [1990, 2000, 2010],
      name: 'Populations × 1000'
    )
  }

  describe '#[]' do
    subject { dataframe.method(:[]) }

    its_call(:Ukraine) { is_expected.to ret vec([51_838, 49_429, 45_962], index: [1990, 2000, 2010]) }
    its_call(:Ukraine, :India) {
      is_expected.to ret df(
        {
          Ukraine: [51_838, 49_429, 45_962],
          India: [873_785, 1_053_898, 1_182_108]
        },
        index: [1990, 2000, 2010],
        name: 'Populations × 1000'
      )
    }
    its_call(1) { is_expected.to ret vec([873_785, 1_053_898, 1_182_108], index: [1990, 2000, 2010]) }
    its_call(:Ukraine...:Argentina) {
      is_expected.to ret df(
        {
          Ukraine: [51_838, 49_429, 45_962],
          India: [873_785, 1_053_898, 1_182_108]
        },
        index: [1990, 2000, 2010],
        name: 'Populations × 1000'
      )
    }
    its_call(1990, :row) { is_expected.to ret vec([51_838, 873_785, 32_730], index: %i[Ukraine India Argentina]) }

    context 'with MultiIndex'
  end

  describe '#row' do
    subject { dataframe.row.method(:[]) }

    its_call(1990) { is_expected.to ret vec([51_838, 873_785, 32_730], index: %i[Ukraine India Argentina]) }
    its_call(1990, 2010) {
      is_expected.to ret df(
        {
          Ukraine: [51_838, 45_962],
          India: [873_785, 1_182_108],
          Argentina: [32_730, 41_223]
        },
        index: [1990, 2010]
      )
    }
    its_call(1990...2010) {
      is_expected.to ret df(
        {
          Ukraine: [51_838, 49_429],
          India: [873_785, 1_053_898],
          Argentina: [32_730, 37_057]
        },
        index: [1990, 2000]
      )
    }
  end

  #### QUERYING DATA

  #### CHANGING DATA

  #### ENUMERABLE-ALIKE
end
