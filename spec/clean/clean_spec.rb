RSpec.describe Daru::DataFrame do
  subject { described_class.new(
      {
        a: [3,4,5,6,7],
        b: ['mal','femal','M','F','Fem'],
        c: [10,nil,30,40,nil],
        d: ['a,c','a','b','b','b,a'],
        e: [:A,:N,:B,:C,:N]
      })}

  context 'fuzzy_replace' do
    let(:vec)  { :b }
    let(:dict) { ['MALE', 'FEMALE'] }

    before { subject.fuzzy_replace vec, dict }

    its(:b) { is_expected.to eq(Daru::Vector.new ['MALE','FEMALE','MALE','FEMALE','FEMALE']) }
  end

  context 'impute' do
    let(:vec) { :c }

    before { subject.impute vec }

    its(:c) { is_expected.to eq(Daru::Vector.new [10,20,30,40,50]) }
  end

  context 'split_cell!' do
    let(:cols) { [:d] }

    before { subject.split_cell! cols }

    its(:a) { is_expected.to eq(Daru::Vector.new [4,5,6,3,3,7,7]) }
    its(:d) { is_expected.to eq(Daru::Vector.new ['a','b','b','a','c','b','a']) }
  end

  context 'depend?' do
    it 'checks dependent columns' do
      expect(subject.depend? :c, :e).to eq(true)
      expect(subject.depend? :a, :b).to eq(true)
    end

    it 'checks independent columns' do
      expect(subject.depend? :a, :e).to eq(false)
    end
  end
end
