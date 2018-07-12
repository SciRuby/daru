RSpec.describe Daru::DataFrame do
  let(:df) { described_class.new(
      {
        REF:    [2002, 2003, 3001, 3002, 3003],
        Handle: ['t-shirt1', 't-shirt1', 't-shirt2', 't-shirt2', 't-shirt2'],
        Size:   ['M', 'L', 'S', 'M', 'L'],
        Price:  [23,23,24,24,24]
      })}

  context 'cluster_kmeans' do
    let(:cols)      { [:REF, :Price] }
    let(:centroids) { 2 }

    subject { df.cluster_kmeans cols, centroids }

    its(:view) { is_expected.to be_an(Array) }
  end

  context 'cluster_hier' do
    let(:cols) { [:REF,:Price] }

    subject { df.cluster_hier cols }

    it { is_expected.to eq([[[[3001, 24], [3002, 24]], [3003, 24]], [[2002, 23], [2003, 23]]]) }
  end

  context 'sample_systematic' do
    let(:k) { 2 }

    subject { df.sample_systematic k }

    its(:REF) { is_expected.to eq(Daru::Vector.new([2002,3001,3003], index: [0,2,4])) }
  end

  context 'sample_stratified' do
    let(:division) { {(1..3)=>2,[0,4]=>1} }

    subject { df.sample_stratified division }

    its(:size) { is_expected.to eq(3) }
  end
end
