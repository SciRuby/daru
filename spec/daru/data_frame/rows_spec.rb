require 'daru/data_frame/rows'

RSpec.describe Daru::DataFrame::Rows do
  def proxy(df, pos)
    Daru::DataFrame::Rows::Proxy.new(df, pos)
  end

  def rs(df, *poss)
    Daru::DataFrame::Rows.new(df, positions: (poss.empty? ? nil : poss))
  end

  subject(:rows) { described_class.new(dataframe) }

  let(:dataframe) {
    df(
      {
        Ukraine: [51_838, 49_429, 45_962],
        India: [873_785, 1_053_898, 1_182_108],
        Argentina: [32_730, 37_057, 41_223]
      },
      index: [1990, 2000, 2010],
      name: 'Populations × 1000'
    )
  }

  its(:count) { is_expected.to eq 3 }
  its(:dataframe) { is_expected.to equal dataframe } # note the `equal` -- it is the same object exactly

  describe '#at' do
    subject { rows.method(:at) }
    its_call(0) {
      is_expected.to ret(
        be_a(Daru::DataFrame::Rows::Proxy)
        .and eq(vec([51_838, 873_785, 32_730], index: %i[Ukraine India Argentina]))
        .and have_attributes(name: 1990)
      )
    }
  end

  describe '#fetch' do
    subject { rows.method(:fetch) }
    its_call(1990) {
      is_expected.to ret(
        be_a(Daru::DataFrame::Rows::Proxy)
        .and eq(vec([51_838, 873_785, 32_730], index: %i[Ukraine India Argentina]))
        .and have_attributes(name: 1990)
      )
    }
  end

  describe '#slice' do
    subject { rows.method(:slice) }

    its_call(1990) { is_expected.to ret rs(dataframe, 0) }
    its_call(1990, 2010) { is_expected.to ret rs(dataframe, 0, 2) }
    its_call(1990...2010) { is_expected.to ret rs(dataframe, 0, 1) }
  end

  describe '#slice_at' do
    subject { rows.method(:slice_at) }

    its_call(0) { is_expected.to ret rs(dataframe, 0) }
    its_call(0, 2) { is_expected.to ret rs(dataframe, 0, 2) }
    its_call(0...2) { is_expected.to ret rs(dataframe, 0, 1) }
  end

  describe '#[]' # TODO: it should be fluent

  describe '#each' do
    subject { ->(block) { rows.each(&block) } }

    it {
      is_expected.to yield_successive_args(
        proxy(dataframe, 0),
        proxy(dataframe, 1),
        proxy(dataframe, 2)
      )
    }
  end

  context 'rows with positions specified' do
    subject(:rows) { described_class.new(dataframe, positions: [0, 2]) }
    its(:count) { is_expected.to eq 2 }
    describe '#each' do
      subject { ->(block) { rows.each(&block) } }

      it { expect(rows.slice(2000..2010)).to eq rs(dataframe, 2) }
      it { expect(rows.slice_at(1)).to eq rs(dataframe, 2) }

      it {
        is_expected.to yield_successive_args(
          proxy(dataframe, 0),
          proxy(dataframe, 2)
        )
      }
    end
  end

  describe 'Enumerable-alike behavior' do
    describe '#first'
    describe '#last'
    describe '#select' do
      subject { rows.select { |r| r.data.inject(:+) > 1_200_000  } }

      it { is_expected.to eq rs(dataframe, 2) }
    end

    describe '#map'
    describe '#recode'
  end
end
