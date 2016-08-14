RSpec.shared_context 'reject values checker' do |params|
  let(:dv) { params.keys.first[0] }
  let(:reject_values) { params.keys.first[1] }
  let(:result_values) { params.values.first[0] }
  let(:result_index) { params.values.first[1] }

  subject { dv.reject_values(*reject_values) }

  its(:category) { is_expected.to eq :category } if dv.catetory?
  its(:to_a) { is_expected.to eq result_values }
  its(:'index.to_a') { is_expected.to eq result_index }
end
