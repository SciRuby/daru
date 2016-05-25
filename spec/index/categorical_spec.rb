require 'spec_helper.rb'

describe Daru::CategoricalIndex do
  context "#pos" do
    context "when the category is non-numeric" do
      let(:idx) { Daru::CategoricalIndex.new [:a, :b, :a, :a, :c] }

      context "single category" do
        subject { idx.pos :a }
        
        it { is_expected.to eq [0, 2, 3] }
      end
      
      context "multiple categories" do
        subject { idx.pos :a, :c }
        
        it { is_expected.to eq Daru::Index.new [0, 2, 3, 4] }
      end

      context "invalid category" do
        subject { idx.pos :e }

        it { is_expected.to raise IndexError }
      end

      it "positional index" do
        it { expect( idx.pos 0).to eq 0 }
      end

      it "invalid positional index" do
        it { expect { idx.pos 5 }.to raise_error IndexError }
      end

      it "multiple positional indexes" do
        subject { idx.pos 0, 1, 2 }

        it { is_expected.to be_a Array }
        its(:size) { is_expected.to eq 3 }
        it { is_expected.to eq [0, 1, 2] }
      end
    end

    context "when the category is numeric" do
      let(:idx) { Daru::CategoricalIndex.new [0, 1, 0, 0, 2] }

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
end