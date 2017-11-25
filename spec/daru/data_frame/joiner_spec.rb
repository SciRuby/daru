require 'daru/data_frame/joiner'

RSpec.describe Daru::DataFrame::Joiner do
  subject(:joiner) { described_class.new(left, right, columns) }

  let(:left) {
    Daru::DataFrame.new(
      {
        population: [51_838, 45_962],
        year: [1990, 2010]
      },
      name: 'Ukraine'
    )
  }
  let(:right) {
    Daru::DataFrame.new(
      {
        population: [1_182_108, 1_053_898],
        year: [2010, 2000]
      },
      name: 'India'
    )
  }

  context 'with one join column' do
    let(:columns) { [:year] }

    its(:joined_columns) { are_expected.to eq ['Ukraine.population', :year, 'India.population'] }
    its(:join_values) { are_expected.to eq [[1990], [2010], [2000]] }

    its(:inner) {
      is_expected.to eq df({
        'Ukraine.population' => [45_962],
        year: [2010],
        'India.population' => [1_182_108]
      }, {})
    }
    its(:left) {
      is_expected.to eq df({
        'Ukraine.population' => [51_838, 45_962],
        year: [1990, 2010],
        'India.population' => [nil, 1_182_108]
      }, {})
    }
    its(:right) {
      is_expected.to eq df({
        'Ukraine.population' => [45_962, nil],
        year: [2010, 2000],
        'India.population' => [1_182_108, 1_053_898]
      }, {})
    }
    its(:outer) {
      is_expected.to eq df({
        'Ukraine.population' => [51_838, 45_962, nil],
        year: [1990, 2010, 2000],
        'India.population' => [nil, 1_182_108, 1_053_898]
      }, {})
    }
  end

  context 'with several join columns' do
  end

  context 'with unidentified join column' do
  end
end
