require 'spec_helper.rb'

describe Daru::CategoricalIndex do
  let(:idx1) { Daru::CategoricalIndex.new [:a, :b, :a, :a, :c] }
  let(:idx2) { Daru::CategoricalIndex.new [0, 1, 0, 0, 2] }

  context "#[]" do
    context "when the category is non-numeric" do
      context "retrive single category" do
        subject { idx1[:a] }
        
        it { is_expected.to eq Daru::Index.new [0, 2, 3] }
      end
      
      context "retrive multiple categories" do
        subject {idx1[:a, :c] }
        
        it { is_expected.to eq Daru::Index.new [0, 2, 3, 4] }
      end

      it "returns the position given positional index" do
        expect(@idx1[0]).to eq(0)
      end

      it "raises exception given wrong positional index" do
        expect { @idx1[5] }.to raise_error
      end

      it "returns the positions give positional index" do
        expect(@idx1[0, 1, 2]).to eq(Daru::Index.new(
          [0, 1, 2]))
      end

      it "raises exception given wrong positional indexes" do
        expect { @idx1[0, 1, 5] }.to raise_error
      end
    end

    context "when the category is numeric" do
      # TO DO
    end
  end
end