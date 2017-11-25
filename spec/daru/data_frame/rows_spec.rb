require 'daru/data_frame/rows'

RSpec.describe Daru::DataFrame::Rows do
  def proxy(df, pos)
    Daru::DataFrame::Rows::Proxy.new(df, pos)
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
  its(:dataframe) { is_expected.to equal dataframe } # note the equal -- it is the same object exactly

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

  describe '#vector' do
    subject { rows.method(:vector) }
    its_call(1990) {
      is_expected.to ret(
        be_a(Daru::DataFrame::Rows::Proxy)
        .and eq(vec([51_838, 873_785, 32_730], index: %i[Ukraine India Argentina]))
        .and have_attributes(name: 1990)
      )
    }
  end

  describe '#vectors' do
    subject { rows.method(:vector) }

    its_call(1990) { is_expected.to ret [proxy(dataframe, 0)] }
    its_call(1990, 2010) { is_expected.to ret [proxy(dataframe, 0), proxy(dataframe, 2)] }
    its_call(1990...2010) { is_expected.to ret [proxy(dataframe, 0), proxy(dataframe, 1)] }
  end

  describe '#vectors_at' do
    subject { rows.method(:vector) }

    its_call(0) { is_expected.to ret [proxy(dataframe, 0)] }
    its_call(0, 2) { is_expected.to ret [proxy(dataframe, 0), proxy(dataframe, 2)] }
    its_call(0...2) { is_expected.to ret [proxy(dataframe, 0), proxy(dataframe, 1)] }
  end

  describe '#[]'

  describe '#each'

  describe '#slice' # should be "view"
  describe '#slice_at'

  describe 'Enumerable-alike behavior' do
    describe '#first'
    describe '#last'
    describe '#select'
    describe '#map'
    describe '#recode'
  end
end
