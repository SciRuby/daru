require 'spec_helper.rb'

describe Daru::Vector do
  ALL_DTYPES = [:array, :nmatrix]

  ALL_DTYPES.each do |dtype|
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

        it "returns an element after passing a numeric index" do
          expect(@dv[0]).to eq(1)
        end

        it "returns a vector with given indices for multiple indices" do
          expect(@dv[:yoda, :anakin]).to eq(Daru::Vector.new([1,2], name: :yoda, 
            index: [:yoda, :anakin], dtype: dtype))
        end

        it "returns a vector when specified symbol Range" do
          expect(@dv[:yoda..:anakin]).to eq(Daru::Vector.new([1,2], 
            index: [:yoda, :anakin], name: :yoga, dtype: dtype))
        end

        it "returns a vector when specified numeric Range" do
          expect(@dv[3..4]).to eq(Daru::Vector.new([4,5], name: :yoga, 
            index: [:padme, :r2d2], name: :yoga, dtype: dtype))
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

        it "sets dtype to Array if a nil is assigned" do
          @dv[0] = nil
          expect(@dv.dtype).to eq(:array)
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
        it "keeps only unique values" do
        end
      end

      context "#cast" do
        ALL_DTYPES.each do |new_dtype|
          it "casts from #{dtype} to #{new_dtype}" do
            v = Daru::Vector.new [1,2,3,4], dtype: dtype
            v.cast(dtype: new_dtype)
            expect(v.dtype).to eq(new_dtype)
          end
        end
      end

      context "#sort" do
        before do
          @dv = Daru::Vector.new [33,2,15,332,1], name: :dv, index: [:a, :b, :c, :d, :e]
        end

        it "sorts the vector with defaults and returns a new vector, preserving indexing" do
          expect(@dv.sort).to eq(Daru::Vector.new([1,2,15,33,332], name: :dv, index: [:e, :b, :c, :a, :d]))
        end

        it "sorts the vector in descending order", focus: true do
          expect(@dv.sort(ascending: false)).to eq(Daru::Vector.new([332,33,15,2,1], name: :dv, index: [:d, :a, :c, :b, :e]))
        end

        it "accepts a block" do
          str_dv = Daru::Vector.new ["My Jazz Guitar", "Jazz", "My", "Guitar"]

          sorted = str_dv.sort { |a,b| a.length <=> b.length }
          expect(sorted).to eq(Daru::Vector.new(["My", "Jazz", "Guitar", "My Jazz Guitar"], index: [2,1,3,0]))
        end

        it "places nils near the end of the vector" do
          pending
          with_nils = Daru::Vector.new [22,4,nil,111,nil,2]

          expect(with_nils.sort).to eq(Daru::Vector.new([2,4,22,111,nil,nil], index: [5,1,0,3,2,4]))
        end if dtype == :array
      end

      context "#reindex" do
        before do 
          @dv = Daru::Vector.new [1,2,3,4,5], name: :dv, index: [:a, :b, :c, :d, :e]
        end

        it "recreates index with sequential numbers" do
          a  = @dv.reindex(:seq)

          expect(a).to eq(Daru::Vector.new([1,2,3,4,5], name: :dv, index: [0,1,2,3,4]))
          expect(a).to_not eq(@dv)
        end

        it "accepts a new non-numeric index" do
          a = @dv.reindex([:hello, :my, :name, :is, :ted])

          expect(a).to eq(Daru::Vector.new([1,2,3,4,5], name: :dv, index: [:hello, :my, :name, :is, :ted]))
          expect(a).to_not eq(@dv)
        end
      end

      # works with arrays only
      context "#is_nil?"
        before(:each) do
          @with_md    = Daru::Vector.new([1,2,nil,3,4,nil])
          @without_md = Daru::Vector.new([1,2,3,4,5,6])
        end

        it "verifies missing data presence" do
          expect(@with_md.is_nil?)   .to eq(Daru::Vector.new([false,false,true,false,false,true]))
          expect(@without_md.is_nil?).to eq(Daru::Vector.new([false,false,false,false,false,false]))
        end
      end

      context "#clone_structure" do
        it "clones a vector with its index and fills it with nils" do
          vec = Daru::Vector.new([1,2,3,4,5], index: [:a,:b,:c,:d,:e])
          expect(vec.clone_structure).to eq(Daru::Vector.new([nil,nil,nil,nil,nil], index: [:a,:b,:c,:d,:e]))
        end
      end

      context "#nil_positions" do
        before(:each) do
          @with_md = Daru::Vector.new([1,2,nil,3,4,nil])
        end

        it "returns the indexes of nils" do
          expect(@with_md.nil_positions).to eq([2,5])
        end

        it "updates after assingment" do
          @with_md[3] = nil
          expect(@with_md.nil_positions).to eq([2,3,5])
        end
      end

      context "#replace_nils" do
        it "replaces all nils with the specified value" do
          vec = Daru::Vector.new([1,2,3,nil,nil,4])
          expect(vec.replace_nils(2)).to eq(Daru::Vector.new([1,2,3,2,2,4]))
        end

        it "replaces all nils with the specified value (bang)" do
          vec = Daru::Vector.new([1,2,3,nil,nil,4]).replace_nils!(2)
          expect(vec).to eq(Daru::Vector.new([1,2,3,2,2,4]))
        end
      end
  end
end if mri?
