require 'spec_helper.rb'

describe Daru::Vector do
  [Array, NMatrix].each do |dtype|
    describe dtype do
      context "#initialize" do
        it "initializes from an Array" do
          dv = Daru::Vector.new [1,2,3,4,5], name: :ravan, 
            index: [:ek, :don, :teen, :char, :pach], dtype: dtype

          expect(dv.name) .to eq(:ravan)
          expect(dv.index).to eq(Daru::Index.new [:ek, :don, :teen, :char, :pach])
        end

        it "accepts Index object" do
          idx = Daru::Index.new [:yoda, :anakin, :obi, :padme, :r2d2]

          dv = Daru::Vector.new [1,2,3,4,5], name: :yoga, index: idx, dtype: dtype

          expect(dv.name) .to eq(:yoga)
          expect(dv.index).to eq(idx)
        end

        it "raises error for improper Index" do
          expect {
            dv = Daru::Vector.new [1,2,3,4,5], name: :yoga, index: [:i, :j, :k]
          }.to raise_error

          expect {
            idx = Daru::Index.new [:i, :j, :k]
            dv  = Daru::Vector.new [1,2,3,4,5], name: :yoda, index: idx, dtype: dtype 
          }.to raise_error
        end

        it "initializes without specifying an index" do
          dv = Daru::Vector.new [1,2,3,4,5], name: :vishnu, dtype: dtype

          expect(dv.index).to eq(Daru::Index.new [0,1,2,3,4])
        end

        it "inserts nils for extra indices" do
          dv = Daru::Vector.new [1,2,3], name: :yoga, index: [0,1,2,3,4], dtype: Array

          expect(dv).to eq([1,2,3,nil,nil].dv(:yoga,nil, Array))
        end
      end

      context "#[]" do
        before :each do
          @dv = Daru::Vector.new [1,2,3,4,5], name: :yoga, 
            index: [:yoda, :anakin, :obi, :padme, :r2d2], dtype: dtype
        end

        it "returns an element after passing an index" do
          expect(@dv[:yoda]).to eq(1)
        end

        it "returns an element after passing a numeric index" , :focus => true do
          expect(@dv[0]).to eq(1)
        end

        it "returns a vector with given indices for multiple indices" do
          expect(@dv[:yoda, :anakin]).to eq(Daru::Vector.new([1,2], name: :yoda, 
            index: [:yoda, :anakin], dtype: dtype))
        end
      end

      context "#[]=" do
        before :each do
          @dv = Daru::Vector.new [1,2,3,4,5], name: :yoga, 
            index: [:yoda, :anakin, :obi, :padme, :r2d2], dtype: dtype
        end

        it "assigns at the specified index" do
          @dv[:yoda] = 666

          expect(@dv[:yoda]).to eq(666)
        end

        it "assigns at the specified Integer index" do
          @dv[0] = 666

          expect(@dv[:yoda]).to eq(666)
        end
      end

      context "#concat" do
        before :each do
          @dv = Daru::Vector.new [1,2,3,4,5], name: :yoga, 
            index: [:warwick, :thompson, :jackson, :fender, :esp], dtype: dtype
        end

        it "concatenates a new element at the end of vector with index" do
          @dv.concat 6, :ibanez

          expect(@dv.index)   .to eq(
            [:warwick, :thompson, :jackson, :fender, :esp, :ibanez].to_index)
          expect(@dv[:ibanez]).to eq(6)
          expect(@dv[5])      .to eq(6)
        end

        it "concatenates without index if index is default numeric" do
          vector = Daru::Vector.new [1,2,3,4,5], name: :nums, dtype: dtype

          vector.concat 6

          expect(vector.index).to eq([0,1,2,3,4,5].to_index)
          expect(vector[5])   .to eq(6)
        end

        it "raises error if index not specified and non-numeric index" do
          expect {
            @dv.concat 6
          }.to raise_error
        end
      end

      context "#delete" do
        it "deletes specified value in the vector" do
          dv = Daru::Vector.new [1,2,3,4,5], name: :a, dtype: dtype

          dv.delete 3

          expect(dv).to eq(Daru::Vector.new [1,2,4,5], name: :a)
        end
      end

      context "#delete_at" do
        before :each do
          @dv = Daru::Vector.new [1,2,3,4,5], name: :a, 
            index: [:one, :two, :three, :four, :five], dtype: dtype
        end

        it "deletes element of specified index" do
          @dv.delete_at :one

          expect(@dv).to eq(Daru::Vector.new [2,3,4,5], name: :a, 
            index: [:two, :three, :four, :five]), dtype: dtype
        end

        it "deletes element of specified integer index" do
          @dv.delete_at 2

          expect(@dv).to eq(Daru::Vector.new [1,2,4,5], name: :a, 
            index: [:one, :two, :four, :five]), dtype: dtype
        end
      end

      context "#index_of" do
        it "returns index of specified value" do
          dv = Daru::Vector.new [1,2,3,4,5], name: :a, 
            index: [:one, :two, :three, :four, :five], dtype: dtype

          expect(dv.index_of(1)).to eq(:one)
        end
      end

      context "#to_hash" do
        it "returns the vector as a hash" do
          dv = Daru::Vector.new [1,2,3,4,5], name: :a, 
            index: [:one, :two, :three, :four, :five], dtype: dtype

          expect(dv.to_hash).to eq({one: 1, two: 2, three: 3, four: 4, five: 5})
        end
      end

      context "#uniq" do
        # TODO
      end
    end
  end
end if mri?