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

    # TODO: array of vectors
  end
end
