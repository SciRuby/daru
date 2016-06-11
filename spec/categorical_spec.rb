describe Daru::Vector do
  context "initialize" do
    context "default parameters" do
      let(:dv) { Daru::Vector.new [:a, 1, :a, 1, :c], type: :category }
      subject { dv }
      
      it { is_expected.to be_a Daru::Vector }
      its(:size) { is_expected.to eq 5 }
      its(:type) { is_expected.to eq :category }
      its(:ordered?) { is_expected.to eq false }
      its(:to_a) { is_expected.to eq [:a, 1, :a, 1, :c] }
      its(:base_category) { is_expected.to eq :a }
      its(:coding_scheme) { is_expected.to eq :dummy }
      its(:index) { is_expected.to be_a Daru::Index }
      its(:'index.to_a') { is_expected.to eq [0, 1, 2, 3, 4] }
    end
    
    context "with index" do
      context "as array" do
        let(:dv) do
          Daru::Vector.new [:a, 1, :a, 1, :c],
            type: :category,
            index: ['a', 'b', 'c', 'd', 'e']
        end
        subject { dv }
        
        its(:index) { is_expected.to be_a Daru::Index }
        its(:'index.to_a') { is_expected.to eq ['a', 'b', 'c', 'd', 'e'] }
      end
      
      context "as range" do
        let(:dv) do
          Daru::Vector.new [:a, 1, :a, 1, :c],
            type: :category,
            index: 'a'..'e'
        end
        subject { dv }
          
        its(:index) { is_expected.to be_a Daru::Index }
        its(:'index.to_a') { is_expected.to eq ['a', 'b', 'c', 'd', 'e'] }
      end
      
      context "as index object" do
        let(:tuples) do
          [
            [:one, :tin, :bar],
            [:one, :pin, :bar],
            [:two, :pin, :bar],
            [:two, :tin, :bar],
            [:thr, :pin, :foo]
          ]
        end
        let(:idx) { Daru::MultiIndex.from_tuples tuples }
        let(:dv) do
          Daru::Vector.new [:a, 1, :a, 1, :c],
            type: :category,
            index: idx
        end
        subject { dv }
        
        its(:index) { is_expected.to be_a Daru::MultiIndex }
        its(:'index.to_a') { is_expected.to eq tuples }
      end
      
      context "invalid index" do
        it { expect { Daru::Vector.new [1, 1, 2],
          type: :category,
          index: [1, 2]
        }.to raise_error ArgumentError }
      end
    end
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
  
  context "#categories" do
    let(:dv) { Daru::Vector.new [:a, 1, :a, 1, :c], type: :category }
    subject { dv.categories }
    
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
  
  context "#categories=" do
    let(:dv) { Daru::Vector.new [:a, 1, :a, 1, :c], type: :category }
    subject { dv }
    before { dv.categories = [1, 2, 3] }
    
    its(:to_a) { is_expected.to eq [1, 2, 1, 2, 3] }
  end
  
  context "#order=" do
    context "valid reordering" do
      let(:dv) { Daru::Vector.new [:a, 1, :a, 1, :c], type: :category }
      subject { dv }
      before { dv.order = [:c, 1, :a] }
      
      its(:categories) { is_expected.to eq [:c, 1, :a] }
      its(:to_a) { is_expected.to eq [:a, 1, :a, 1, :c] }
    end
    
    context "invalid reordering" do
      let(:dv) { Daru::Vector.new [:a, 1, :a, 1, :c], type: :category }

      it { expect { dv.order = [:c, 1, :b] }.to raise_error ArgumentError }
    end
  end
  
  context "#min" do
    context "ordered" do
      context "default ordering" do
        let(:dv) { Daru::Vector.new [:a, 1, :a, 1, :c], type: :category, ordered: true }

        it { expect(dv.min).to eq :a }
      end
      
      context "reorder" do
        let(:dv) { Daru::Vector.new [:a, 1, :a, 1, :c], type: :category, ordered: true }
        before { dv.order = [1, :a, :c] }
        
        it { expect(dv.min).to eq 1 }
      end
    end
    
    context "unordered" do
      let(:dv) { Daru::Vector.new [:a, 1, :a, 1, :c], type: :category }

      it { expect { dv.min }.to raise_error ArgumentError }
    end
  end

  context "#max" do
    context "ordered" do
      context "default ordering" do
        let(:dv) { Daru::Vector.new [:a, 1, :a, 1, :c], type: :category, ordered: true }

        it { expect(dv.max).to eq :c }
      end
      
      context "reorder" do
        let(:dv) { Daru::Vector.new [:a, 1, :a, 1, :c], type: :category, ordered: true }
        before { dv.order = [1, :c, :a] }
        
        it { expect(dv.max).to eq :a }
      end
    end
    
    context "unordered" do
      let(:dv) { Daru::Vector.new [:a, 1, :a, 1, :c], type: :category }

      it { expect { dv.max }.to raise_error ArgumentError }
    end
  end
  
  context "#sort!" do
    context "ordered" do
      let(:dv) { Daru::Vector.new [:a, 1, :a, 1, :c], type: :category, ordered: true }
      subject { dv }
      before { dv.order = [:c, :a, 1]; dv.sort! }
      
      it { is_expected.to be_a Daru::Vector }
      its(:size) { is_expected.to eq 5 }
      its(:to_a) { is_expected.to eq [:c, :a, :a, 1, 1] }
      its(:'index.to_a') { is_expected.to eq [4, 0, 2, 1, 3] }
    end
    
    context "unordered" do
      
    end
  end
  
  context "#contrast_code" do
    context "dummy coding" do
      context "default base category" do
        let(:dv) { Daru::Vector.new [:a, 1, :a, 1, :c], type: :category, name: 'abc' }
        subject { dv.contrast_code }
        
        it { is_expected.to be_a Daru::DataFrame }
        its(:shape) { is_expected.to eq [5, 2] }
        its(:'abc_1.to_a') { is_expected.to eq [0, 1, 0, 1, 0] }
        its(:'abc_c.to_a') { is_expected.to eq [0, 0, 0, 0, 1] }
      end
      
      context "manual base category" do
        let(:dv) { Daru::Vector.new [:a, 1, :a, 1, :c], type: :category, name: 'abc' }
        before { dv.base_category = :c }
        subject { dv.contrast_code }
        
        it { is_expected.to be_a Daru::DataFrame }
        its(:shape) { is_expected.to eq [5, 2] }
        its(:'abc_a.to_a') { is_expected.to eq [1, 0, 1, 0, 0] }
        its(:'abc_1.to_a') { is_expected.to eq [0, 1, 0, 1, 0] }        
      end
    end
    
    context "simple coding" do
      context "default base category" do
        let(:dv) { Daru::Vector.new [:a, 1, :a, 1, :c], type: :category, name: 'abc' }
        subject { dv.contrast_code }
        before { dv.coding_scheme = :simple }
        
        it { is_expected.to be_a Daru::DataFrame }
        its(:shape) { is_expected.to eq [5, 2] }
        its(:'abc_1.to_a') { is_expected.to eq [-1/3.0, 2/3.0, -1/3.0, 2/3.0, -1/3.0] }
        its(:'abc_c.to_a') { is_expected.to eq [-1/3.0, -1/3.0, -1/3.0, -1/3.0, 2/3.0] }
      end
      
      context "manual base category" do
        let(:dv) { Daru::Vector.new [:a, 1, :a, 1, :c], type: :category, name: 'abc' }
        subject { dv.contrast_code }
        before do
          dv.coding_scheme = :simple
          dv.base_category = :c
        end
        
        it { is_expected.to be_a Daru::DataFrame }
        its(:shape) { is_expected.to eq [5, 2] }
        its(:'abc_a.to_a') { is_expected.to eq [2/3.0, -1/3.0, 2/3.0, -1/3.0, -1/3.0] }
        its(:'abc_1.to_a') { is_expected.to eq [-1/3.0, 2/3.0, -1/3.0, 2/3.0, -1/3.0] }
      end
    end

    context "helmert coding" do
      let(:dv) { Daru::Vector.new [:a, 1, :a, 1, :c], type: :category, name: 'abc' }
      subject { dv.contrast_code }
      before { dv.coding_scheme = :helmert }

      it { is_expected.to be_a Daru::DataFrame }
      its(:shape) { is_expected.to eq [5, 2] }
      its(:'abc_a.to_a') { is_expected.to eq [2/3.0, -1/3.0, 2/3.0, -1/3.0, -1/3.0] }
      its(:'abc_1.to_a') { is_expected.to eq [0, 1/2.0, 0, 1/2.0, -1/2.0] }
    end

    context "deviation coding" do
      let(:dv) { Daru::Vector.new [:a, 1, :a, 1, :c], type: :category, name: 'abc' }
      subject { dv.contrast_code }
      before { dv.coding_scheme = :deviation }

      it { is_expected.to be_a Daru::DataFrame }
      its(:shape) { is_expected.to eq [5, 2] }
      its(:'abc_a.to_a') { is_expected.to eq [1, 0, 1, 0, -1] }
      its(:'abc_1.to_a') { is_expected.to eq [0, 1, 0, 1, -1] }
    end
  end
end