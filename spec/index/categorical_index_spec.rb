require 'spec_helper.rb'

describe Daru::CategoricalIndex do
  context "#pos" do
    context "when the category is non-numeric" do
      let(:idx) { described_class.new [:a, :b, :a, :a, :c] }

      context "single category" do
        subject { idx.pos :a }
        
        it { is_expected.to eq [0, 2, 3] }
      end
      
      context "multiple categories" do
        subject { idx.pos :a, :c }
        
        it { is_expected.to eq [0, 2, 3, 4] }
      end

      context "invalid category" do
        it { expect { idx.pos :e }.to raise_error IndexError }
      end

      context "positional index" do
        it { expect(idx.pos 0).to eq 0 }
      end

      context "invalid positional index" do
        it { expect { idx.pos 5 }.to raise_error IndexError }
      end

      context "multiple positional indexes" do
        subject { idx.pos 0, 1, 2 }

        it { is_expected.to be_a Array }
        its(:size) { is_expected.to eq 3 }
        it { is_expected.to eq [0, 1, 2] }
      end
    end

    context "when the category is numeric" do
      let(:idx) { described_class.new [0, 1, 0, 0, 2] }

      context "first preference to category" do
        subject { idx.pos 0 }

        it { is_expected.to be_a Array }
        its(:size) { is_expected.to eq 3 }
        it { is_expected.to eq [0, 2, 3] }
      end

      context "second preference to positional index" do
        subject { idx.pos 3 }

        it { is_expected.to eq 3 }
      end
    end
  end
  
  context "#subset" do
    let(:idx) { described_class.new [:a, 1, :a, 1, :c] }
    
    context "single index" do
      context "multiple instances" do
        subject { idx.subset :a }
        
        it { is_expected.to be_a described_class }
        its(:size) { is_expected.to eq 2 }
        its(:to_a) { is_expected.to eq [:a, :a] }
      end
    end
    
    context "multiple indexes" do
      subject { idx.subset :a, 1 }
      
      it { is_expected.to be_a described_class }
      its(:size) { is_expected.to eq 4 }
      its(:to_a) { is_expected.to eq [:a, 1, :a, 1] }
    end

    context "multiple positional indexes" do
      subject { idx.subset 0, 2 }
      
      it { is_expected.to be_a described_class }
      its(:size) { is_expected.to eq 2 }
      its(:to_a) { is_expected.to eq [:a, :a] }
    end
  end
  
  context "#at" do
    let(:idx) { described_class.new [:a, :a, :a, 1, :c] }
    
    context "single position" do
      it { expect(idx.at 1).to eq :a }
    end
    
    context "multiple positions" do
      subject { idx.at 0, 2, 3 }
      
      it { is_expected.to be_a described_class }
      its(:size) { is_expected.to eq 3 }
      its(:to_a) { is_expected.to eq [:a, :a, 1] }
    end
  end
  
  context "#add" do
    let(:idx) { described_class.new [:a, 1, :a, 1] }
    
    context "single index" do
      subject { idx.add :c }
      
      its(:to_a) { is_expected.to eq [:a, 1, :a, 1, :c] }
    end
    
    context "multiple indexes" do
      subject { idx.add :c, :d }
      
      its(:to_a) { is_expected.to eq [:a, 1, :a, 1, :c, :d] }
    end
  end
  
  context "#respond?" do
    let(:idx) { described_class.new [:a, 1, :a, 1] }

    context "single index" do
      it { expect(idx.respond? :a).to eq true }
      it { expect(idx.respond? 2).to eq true }
      it { expect(idx.respond? 4).to eq false }
    end
    
    context "multiple indexes" do
      it { expect(idx.respond? :a, 1).to eq true }
      it { expect(idx.respond? :a, 1, 5).to eq false }
    end
  end
end