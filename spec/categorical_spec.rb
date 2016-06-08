describe Daru::Vector do
  context "initialize" do
    let(:dv) { Daru::Vector.new [:a, 1, :a, 1, :c], type: :category }
    subject { dv }
    
    it { is_expected.to be_a Daru::Vector }
    its(:size) { is_expected.to eq 5 }
    its(:type) { is_expected.to eq :category }
    its(:ordered?) { is_expected.to eq false }
    its(:to_a) { is_expected.to eq [:a, 1, :a, 1, :c] }
    its(:base_category) { is_expected.to eq :a }
    its(:coding_scheme) { is_expected.to eq :dummy }
  end
  
  context "#to_category" do
    let(:dv) { Daru::Vector.new [:a, 1, :a, 1, :c] }
    subject { dv.to_category }

    it { is_expected.to be_a Daru::Vector }
    its(:size) { is_expected.to eq 5 }
    its(:type) { is_expected.to eq :category }
    its(:ordered?) { is_expected.to eq false }
    its(:to_a) { is_expected.to eq [:a, 1, :a, 1, :c] }
  end
  
  context "#category" do
    let(:dv) { Daru::Vector.new [:a, 1, :a, 1, :c], type: :category }
    subject { dv.category }
    
    it { is_expected.to be_a Array }
    its(:size) { is_expected.to eq 3 }
    its(:'to_a') { is_expected.to eq [:a, 1, :c] }
  end
  
  context "#base_category" do
    let(:dv) { Daru::Vector.new [:a, 1, :a, 1, :c], type: :category }
    subject { dv }
    before { dv.base_category = 1 }
    
    its(:base_category) { is_expected.to eq 1 }
  end
  
  context "#coding_scheme" do
    let(:dv) { Daru::Vector.new [:a, 1, :a, 1, :c], type: :category }
    subject { dv }
    before { dv.coding_scheme = :deviation }
    
    its(:coding_scheme) { is_expected.to eq :deviation }
  end
  
  context "#contrast_code" do
    let(:dv) { Daru::Vector.new [:a, 1, :a, 1, :c], type: :category, name: 'abc' }
    subject { dv.contrast_code }
    
    it { is_expected.to be_a Daru::DataFrame }
    its(:shape) { is_expected.to eq [5, 2] }
    it { expect(subject['abc_1'].to_a).to eq [0, 1, 0, 1, 0] }
    it { expect(subject['abc_c'].to_a).to eq [0, 0, 0, 0, 1] }
  end
end