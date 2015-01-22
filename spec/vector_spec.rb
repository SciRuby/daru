require 'spec_helper.rb'

describe Daru::Vector do
  ALL_DTYPES = [:array, :nmatrix]

  ALL_DTYPES.each do |dtype|
    describe dtype do
      context "#initialize" do
        before do
          @tuples = [
            [:a, :one, :foo], 
            [:a, :two, :bar], 
            [:b, :one, :bar], 
            [:b, :two, :baz]
          ]

          @multi_index = Daru::MultiIndex.new(@tuples)
        end

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

        it "accepts a MultiIndex object" do
          dv = Daru::Vector.new [1,2,3,4], name: :mi, index: @multi_index, dtype: dtype

          expect(dv.name).to eq(:mi)
          expect(dv.index).to eq(@multi_index)
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

        it "raises error for improper MultiIndex" do
          expect {
            dv = Daru::Vector.new [1,2,3,4,5], name: :mi, index: @multi_index
          }.to raise_error
        end

        it "initializes without specifying an index" do
          dv = Daru::Vector.new [1,2,3,4,5], name: :vishnu, dtype: dtype

          expect(dv.index).to eq(Daru::Index.new [0,1,2,3,4])
        end

        it "inserts nils for extra indices" do
          dv = Daru::Vector.new [1,2,3], name: :yoga, index: [0,1,2,3,4], dtype: :array

          expect(dv).to eq([1,2,3,nil,nil].dv(:yoga,nil, Array))
        end

        it "inserts nils for extra indices (MultiIndex)" do
          dv = Daru::Vector.new [1,2], name: :mi, index: @multi_index, dtype: :array
          expect(dv).to eq(Daru::Vector.new([1,2,nil,nil], name: :mi, index: @multi_index, dtype: :array))
        end
      end

      context "#[]" do
        context Daru::Index do
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

        context Daru::MultiIndex do
          before do
            @tuples = [
              [:a,:one,:bar],
              [:a,:one,:baz],
              [:a,:two,:bar],
              [:a,:two,:baz],
              [:b,:one,:bar],
              [:b,:two,:bar],
              [:b,:two,:baz],
              [:b,:one,:foo],
              [:c,:one,:bar],
              [:c,:one,:baz],
              [:c,:two,:foo],
              [:c,:two,:bar]
            ]
            @multi_index = Daru::MultiIndex.new(@tuples)
            @vector = Daru::Vector.new Array.new(12) { |i| i }, index: @multi_index, 
              dtype: dtype, name: :mi_vector
          end

          it "returns a single element when passed a row number" do
            expect(@vector[1]).to eq(1)
          end

          it "returns a single element when passed the full tuple" do
            expect(@vector[:a, :one, :baz]).to eq(1)
          end

          it "returns sub vector when passed first layer of tuple", focus: true do
            mi = Daru::MultiIndex.new([
              [:one,:bar],
              [:one,:baz],
              [:two,:bar],
              [:two,:baz]])
            expect(@vector[:a]).to eq(Daru::Vector.new([0,1,2,3], index: mi, 
              dtype: dtype, name: :sub_vector))
          end

          it "returns sub vector when passed first and second layer of tuple" do
            mi = Daru::MultiIndex.new([
              [:foo],
              [:bar]])
            expect(@vector[:c,:two]).to eq(Daru::Vector.new([10,11], index: mi,
              dtype: dtype, name: :sub_sub_vector))
          end

          it "returns a vector with corresponding MultiIndex when specified numeric Range" do
            mi = Daru::MultiIndex.new([
              [:a,:two,:baz],
              [:b,:one,:bar],
              [:b,:two,:bar],
              [:b,:two,:baz],
              [:b,:one,:foo],
              [:c,:one,:bar],
              [:c,:one,:baz]
            ])
            expect(@vector[3..9]).to eq(Daru::Vector.new([3,4,5,6,7,8,9], index: mi,
              dtype: dtype, name: :slice))
          end
        end
      end

      context "#[]=" do
        context Daru::Index do
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

        context Daru::MultiIndex do
          before :each do
            @tuples = [
              [:a,:one,:bar],
              [:a,:one,:baz],
              [:a,:two,:bar],
              [:a,:two,:baz],
              [:b,:one,:bar],
              [:b,:two,:bar],
              [:b,:two,:baz],
              [:b,:one,:foo],
              [:c,:one,:bar],
              [:c,:one,:baz],
              [:c,:two,:foo],
              [:c,:two,:bar]
            ]
            @multi_index = Daru::MultiIndex.new(@tuples)
            @vector = Daru::Vector.new Array.new(12) { |i| i }, index: @multi_index, 
              dtype: dtype, name: :mi_vector
          end

          it "assigns all lower layer indices when specified a first layer index" do
            @vector[:b] = 69
            expect(@vector).to eq(Daru::Vector.new([0,1,2,3,69,69,69,69,8,9,10,11],
              index: @multi_index, name: :top_layer_assignment, dtype: dtype
              ))
          end

          it "assigns all lower indices when specified first and second layer index" do
            @vector[:b, :one] = 69
            expect(@vector).to eq(Daru::Vector.new([0,1,2,3,69,5,6,69,8,9,10,11],
              index: @multi_index, name: :second_layer_assignment, dtype: dtype))
          end

          it "assigns just the precise value when specified complete tuple" do
            @vector[:b, :one, :foo] = 69
            expect(@vector).to eq(Daru::Vector.new([0,1,2,3,4,5,6,69,8,9,10,11],
              index: @multi_index, name: :precise_assignment, dtype: dtype))
          end

          it "assigns correctly when numeric index" do
            @vector[7] = 69
            expect(@vector).to eq(Daru::Vector.new([0,1,2,3,4,5,6,69,8,9,10,11],
              index: @multi_index, name: :precise_assignment, dtype: dtype))
          end
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
        context Daru::Index do
          it "deletes specified value in the vector" do
            dv = Daru::Vector.new [1,2,3,4,5], name: :a, dtype: dtype

            dv.delete 3
            expect(dv).to eq(Daru::Vector.new [1,2,4,5], name: :a)
          end
        end

        context Daru::MultiIndex do
          pending
        end
      end

      context "#delete_at" do
        context Daru::Index do
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

        context Daru::MultiIndex do
          pending "Possibly next release"
        end
      end

      context "#index_of" do
        context Daru::Index do
          it "returns index of specified value" do
            dv = Daru::Vector.new [1,2,3,4,5], name: :a, 
              index: [:one, :two, :three, :four, :five], dtype: dtype

            expect(dv.index_of(1)).to eq(:one)
          end
        end

        context Daru::MultiIndex do
          it "returns tuple of specified value" do
            mi = Daru::MultiIndex.new([
              [:a,:two,:bar],
              [:a,:two,:baz],
              [:b,:one,:bar],
              [:b,:two,:bar]
            ])
            vector = Daru::Vector.new([1,2,3,4], index: mi, dtype: dtype)
            expect(vector.index_of(3)).to eq([:b,:one,:bar])
          end
        end
      end

      context "#to_hash" do
        context Daru::Index do
          it "returns the vector as a hash" do
            dv = Daru::Vector.new [1,2,3,4,5], name: :a, 
              index: [:one, :two, :three, :four, :five], dtype: dtype

            expect(dv.to_hash).to eq({one: 1, two: 2, three: 3, four: 4, five: 5})
          end
        end

        context Daru::MultiIndex do
          pending
          # it "returns vector as a Hash" do
          #   pending
          #   mi = Daru::MultiIndex.new([
          #     [:a,:two,:bar],
          #     [:a,:two,:baz],
          #     [:b,:one,:bar],
          #     [:b,:two,:bar]
          #   ])
          #   vector = Daru::Vector.new([1,2,3,4], index: mi, dtype: dtype)
          #   expect(vector.to_hash).to eq({
          #     [:a,:two,:bar] => 1,
          #     [:a,:two,:baz] => 2,
          #     [:b,:one,:bar] => 3,
          #     [:b,:two,:bar] => 4
          #   })
          # end
        end
      end

      context "#uniq" do
        it "keeps only unique values" do
          # TODO: fill this in
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
        context Daru::Index do
          before do
            @dv = Daru::Vector.new [33,2,15,332,1], name: :dv, index: [:a, :b, :c, :d, :e]
          end

          it "sorts the vector with defaults and returns a new vector, preserving indexing" do
            expect(@dv.sort).to eq(Daru::Vector.new([1,2,15,33,332], name: :dv, index: [:e, :b, :c, :a, :d]))
          end

          it "sorts the vector in descending order" do
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

        context Daru::MultiIndex do
          before do
            mi = Daru::MultiIndex.new([
              [:a, :one,   :foo], 
              [:a, :two,   :bar], 
              [:b, :one,   :bar], 
              [:b, :two,   :baz],
              [:b, :three, :bar]
              ])
            @vector = Daru::Vector.new([44,22,111,0,-56], index: mi, name: :unsorted,
              dtype: dtype)
          end

          it "sorts vector" do
            mi_asc = Daru::MultiIndex.new([
              [:b, :three, :bar],
              [:b, :two,   :baz],
              [:a, :two,   :bar],
              [:a, :one,   :foo],
              [:b, :one,   :bar]
            ])
            expect(@vector.sort).to eq(Daru::Vector.new([-56,0,22,44,111], index: mi_asc,
              name: :ascending, dtype: dtype))
          end

          it "sorts in descending" do
            mi_dsc = Daru::MultiIndex.new([
              [:b, :one, :bar], 
              [:a, :one, :foo], 
              [:a, :two, :bar], 
              [:b, :two, :baz], 
              [:b, :three, :bar]
            ])
            expect(@vector.sort(ascending: false)).to eq(Daru::Vector.new(
              [111,44,22,0,-56], index: mi_dsc, name: :descending, dtype: dtype))
          end

          it "sorts using the supplied block" do
            mi_abs = Daru::MultiIndex.new([
              [:b, :two,   :baz],
              [:a, :two,   :bar],
              [:a, :one,   :foo],
              [:b, :three, :bar],
              [:b, :one,   :bar]
            ])
            expect(@vector.sort { |a,b| a.abs <=> b.abs }).to eq(Daru::Vector.new(
              [0,22,44,-56,111], index: mi_abs, name: :sort_abs, dtype: dtype))
          end
        end
      end

      context "#reindex" do
        context Daru::Index do
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

        context Daru::MultiIndex do
          pending
        end
      end
    end
  end # checking with ALL_DTYPES

  # works with arrays only
  context "#is_nil?" do
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
    context Daru::Index do
      it "clones a vector with its index and fills it with nils" do
        vec = Daru::Vector.new([1,2,3,4,5], index: [:a,:b,:c,:d,:e])
        expect(vec.clone_structure).to eq(Daru::Vector.new([nil,nil,nil,nil,nil], index: [:a,:b,:c,:d,:e]))
      end
    end
    
    context Daru::MultiIndex do
      pending
    end
  end

  context "#nil_positions" do
    context Daru::Index do
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

    context Daru::MultiIndex do
      pending
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

  context "#type" do
    before(:each) do
      @numeric = Daru::Vector.new([1,2,3,4,5])
      @multi = Daru::Vector.new([1,2,3,'sameer','d'])
      @with_nils = Daru::Vector.new([1,2,3,4,nil])
    end

    it "checks numeric data correctly" do
      expect(@numeric.type).to eq(:numeric)
    end

    it "checks for multiple types of data" do
      expect(@multi.type).to eq(:object)
    end

    it "tells NMatrix data type in case of NMatrix wrapper" do
      nm = Daru::Vector.new([1,2,3,4,5], dtype: :nmatrix)
      expect(nm.type).to eq(:int32)
    end

    it "changes type to object as per assignment" do
      expect(@numeric.type).to eq(:numeric)
      @numeric[2] = 'my string'
      expect(@numeric.type).to eq(:object)
    end

    it "changes type to numeric as per assignment" do
      expect(@multi.type).to eq(:object)
      @multi[3] = 45
      @multi[4] = 54
      expect(@multi.type).to eq(:numeric) 
    end

    it "reports numeric if nils with number data" do
      expect(@with_nils.type).to eq(:numeric)
    end

    it "stays numeric when nil is reassigned to a number" do
      @with_nils[4] = 66
      expect(@with_nils.type).to eq(:numeric)
    end

    it "changes to :object when nil is reassigned to anything but a number" do
      @with_nils[4] = 'string'
      expect(@with_nils.type).to eq(:object)
    end
  end 
end if mri?
