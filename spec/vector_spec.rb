require 'spec_helper.rb'

describe Daru::Vector do
  ALL_DTYPES.each do |dtype|
    describe dtype.to_s do
      before do
        @common_all_dtypes =  Daru::Vector.new(
          [5, 5, 5, 5, 5, 6, 6, 7, 8, 9, 10, 1, 2, 3, 4, 11, -99, -99], 
          dtype: dtype, name: :common_all_dtypes)
      end

      context "#initialize" do
        before do
          @tuples = [
            [:a, :one, :foo], 
            [:a, :two, :bar], 
            [:b, :one, :bar], 
            [:b, :two, :baz]
          ]

          @multi_index = Daru::MultiIndex.from_tuples(@tuples)
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
          dv = Daru::Vector.new [1,2,3], name: :yoga, index: [0,1,2,3,4], dtype: dtype

          expect(dv).to eq([1,2,3,nil,nil].dv(:yoga,nil, :array))
        end

        it "inserts nils for extra indices (MultiIndex)" do
          dv = Daru::Vector.new [1,2], name: :mi, index: @multi_index, dtype: :array
          expect(dv).to eq(Daru::Vector.new([1,2,nil,nil], name: :mi, index: @multi_index, dtype: :array))
        end

        it "accepts all sorts of objects for indexing" do
          dv = Daru::Vector.new [1,2,3,4], index: ['a', 'b', :r, 0]
          expect(dv.to_a).to eq([1,2,3,4])
          expect(dv.index.to_a).to eq(['a', 'b', :r, 0])
        end
      end

      context ".new_with_size" do
        it "creates new vector from only size" do
          v1 = Daru::Vector.new 10.times.map { nil }, dtype: dtype
          v2 = Daru::Vector.new_with_size 10, dtype: dtype
          expect(v2).to eq(v1)
        end if [:array, :nmatrix].include?(dtype)

        it "creates new vector from only size and value" do
          a = rand
          v1 = Daru::Vector.new 10.times.map { a }, dtype: dtype
          v2 = Daru::Vector.new_with_size(10, value: a, dtype: dtype)
          expect(v2).to eq(v1)
        end

        it "accepts block" do
          v1 = Daru::Vector.new 10.times.map {|i| i * 2 }
          v2 = Daru::Vector.new_with_size(10, dtype: dtype) { |i| i * 2 }
          expect(v2).to eq(v1)
        end
      end

      context ".[]" do
        it "returns same results as R-c()" do
          reference = Daru::Vector.new([0, 4, 5, 6, 10])
          expect(Daru::Vector[0, 4, 5, 6, 10])          .to eq(reference)
          expect(Daru::Vector[0, 4..6, 10])             .to eq(reference)
          expect(Daru::Vector[[0], [4, 5, 6], [10]])    .to eq(reference)
          expect(Daru::Vector[[0], [4, [5, [6]]], [10]]).to eq(reference)

          expect(Daru::Vector[[0], Daru::Vector.new([4, 5, 6]), [10]])
                                                        .to eq(reference)
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

          it "returns a vector with given indices for multiple numeric indices" do
            expect(@dv[0,1]).to eq(Daru::Vector.new([1,2], name: :yoda, 
              index: [:yoda, :anakin], dtype: dtype))
          end

          it "returns a vector when specified symbol Range" do
            expect(@dv[:yoda..:anakin]).to eq(Daru::Vector.new([1,2], 
              index: [:yoda, :anakin], name: :yoga, dtype: dtype))
          end

          it "returns a vector when specified numeric Range" do
            expect(@dv[3..4]).to eq(Daru::Vector.new([4,5], name: :yoga, 
              index: [:padme, :r2d2], dtype: dtype))
          end

          it "returns correct results for index of multiple index" do
            v = Daru::Vector.new([1,2,3,4], index: ['a','c',1,:a])
            expect(v['a']).to eq(1)
            expect(v[:a]).to eq(4)
            expect(v[1]).to eq(3)
            expect(v[0]).to eq(1)
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
            @multi_index = Daru::MultiIndex.from_tuples(@tuples)
            @vector = Daru::Vector.new(
              Array.new(12) { |i| i }, index: @multi_index, 
              dtype: dtype, name: :mi_vector)
          end

          it "returns a single element when passed a row number" do
            expect(@vector[1]).to eq(1)
          end

          it "returns a single element when passed the full tuple" do
            expect(@vector[:a, :one, :baz]).to eq(1)
          end

          it "returns sub vector when passed first layer of tuple" do
            mi = Daru::MultiIndex.from_tuples([
              [:one,:bar],
              [:one,:baz],
              [:two,:bar],
              [:two,:baz]])
            expect(@vector[:a]).to eq(Daru::Vector.new([0,1,2,3], index: mi, 
              dtype: dtype, name: :sub_vector))
          end

          it "returns sub vector when passed first and second layer of tuple" do
            mi = Daru::MultiIndex.from_tuples([
              [:foo],
              [:bar]])
            expect(@vector[:c,:two]).to eq(Daru::Vector.new([10,11], index: mi,
              dtype: dtype, name: :sub_sub_vector))
          end

          it "returns a vector with corresponding MultiIndex when specified numeric Range" do
            mi = Daru::MultiIndex.from_tuples([
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

          it "assigns correctly for a mixed index Vector" do
            v = Daru::Vector.new [1,2,3,4], index: ['a',:a,0,66]
            v['a'] = 666
            expect(v['a']).to eq(666)

            v[0] = 666
            expect(v[0]).to eq(666)

            v[3] = 666
            expect(v[3]).to eq(666)

            expect(v).to eq(Daru::Vector.new([666,2,666,666], 
              index: ['a',:a,0,66]))
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
            @multi_index = Daru::MultiIndex.from_tuples(@tuples)
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
            Daru::Index.new([:warwick, :thompson, :jackson, :fender, :esp, :ibanez]))
          expect(@dv[:ibanez]).to eq(6)
          expect(@dv[5])      .to eq(6)
        end

        it "raises error if index not specified" do
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
            expect(dv).to eq(
              Daru::Vector.new [1,2,4,5], name: :a, index: [0,1,3,4])
          end
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
              index: [:two, :three, :four, :five], dtype: dtype)
          end

          it "deletes element of specified integer index" do
            pending
            @dv.delete_at 2

            expect(@dv).to eq(Daru::Vector.new [1,2,4,5], name: :a, 
              index: [:one, :two, :four, :five], dtype: dtype)
          end
        end
      end

      context "#delete_if" do
        it "deletes elements if block evaluates to true" do
          v = Daru::Vector.new [1,22,33,45,65,32,524,656,123,99,77], dtype: dtype
          ret = v.delete_if { |d| d % 11 == 0 }
          expect(ret).to eq(
            Daru::Vector.new([1,45,65,32,524,656,123], 
              index: [0,3,4,5,6,7,8], dtype: dtype))
          expect(ret.dtype).to eq(dtype)
        end
      end

      context "#keep_if" do
        it "keeps elements if block returns true" do
          v = Daru::Vector.new([1,22,33,45,65,32,524,656,123,99,77], dtype: dtype)
          ret = v.keep_if { |d| d < 35 }

          expect(ret).to eq(
            Daru::Vector.new([1,22,33,32], index: [0,1,2,5], dtype: dtype))
          expect(v.dtype).to eq(ret.dtype)
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
            mi = Daru::MultiIndex.from_tuples([
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
          #   mi = Daru::MultiIndex.from_tuples([
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
            mi = Daru::MultiIndex.from_tuples([
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
            mi_asc = Daru::MultiIndex.from_tuples([
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
            mi_dsc = Daru::MultiIndex.from_tuples([
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
            mi_abs = Daru::MultiIndex.from_tuples([
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

      context "#index=" do
        before do
          @vector = Daru::Vector.new([1,2,3,4,5])
        end

        it "simply reassigns index" do
          index  = Daru::DateTimeIndex.date_range(:start => '2012', :periods => 5)
          @vector.index = index

          expect(@vector.index.class).to eq(DateTimeIndex)
          expect(@vector['2012-1-1']).to eq(1)
        end

        it "raises error for index size != vector size" do
          expect {
            @vector.index = Daru::Index.new([4,2,6])
          }.to raise_error
        end
      end

      context "#reindex" do
        it "intelligently reindexes" do
          vector = Daru::Vector.new([1,2,3,4,5])
          index = Daru::Index.new([3,4,1,0,6])

          expect(vector.reindex(index)).to eq(
            Daru::Vector.new([4,5,2,1,nil], index: index))
        end
      end

      context "#collect" do
        it "returns an Array" do
          a = @common_all_dtypes.collect { |v| v }
          expect(a).to eq([5, 5, 5, 5, 5, 6, 6, 7, 8, 9, 10, 1, 2, 3, 4, 11, -99, -99])
        end
      end

      context "#map" do
        it "maps" do
          a = @common_all_dtypes.map { |v| v }
          expect(a).to eq([5, 5, 5, 5, 5, 6, 6, 7, 8, 9, 10, 1, 2, 3, 4, 11, -99, -99])
        end
      end

      context "#map!" do
        it "destructively maps" do
          @common_all_dtypes.map! { |v| v + 1 }
          expect(@common_all_dtypes).to eq(Daru::Vector.new(
            [6, 6, 6, 6, 6, 7, 7, 8, 9, 10, 11, 2, 3, 4, 5, 12, -98, -98], 
            dtype: dtype))
        end
      end

      context "#recode" do
        it "maps and returns a vector of dtype of self by default" do
          a = @common_all_dtypes.recode { |v| v == -99 ? 1 : 0 }
          exp = Daru::Vector.new [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1]
          expect(a).to eq(exp)
          expect(a.dtype).to eq(:array)
        end

        it "maps and returns a vector of dtype gsl" do
          a = @common_all_dtypes.recode(:gsl) { |v| v == -99 ? 1 : 0 }
          exp = Daru::Vector.new [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1], dtype: :gsl
          expect(a).to eq(exp)
          expect(a.dtype).to eq(:gsl)
        end

        it "maps and returns a vector of dtype nmatrix" do
          a = @common_all_dtypes.recode(:nmatrix) { |v| v == -99 ? 1 : 0 }
          exp = Daru::Vector.new [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1], dtype: :nmatrix
          expect(a).to eq(exp)
          expect(a.dtype).to eq(:nmatrix)
        end
      end

      context "#recode!" do
        before :each do
          @vector =  Daru::Vector.new(
            [5, 5, 5, 5, 5, 6, 6, 7, 8, 9, 10, 1, 2, 3, 4, 11, -99, -99], 
            dtype: dtype, name: :common_all_dtypes)
        end

        it "destructively maps and returns a vector of dtype of self by default" do
          @vector.recode! { |v| v == -99 ? 1 : 0 }
          exp = Daru::Vector.new [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1]
          expect(@vector).to eq(exp)
          expect(@vector.dtype).to eq(dtype) 
        end

        it "destructively maps and returns a vector of dtype gsl" do
          @vector.recode!(:gsl) { |v| v == -99 ? 1 : 0 }
          exp = Daru::Vector.new [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1], dtype: :gsl
          expect(@vector).to eq(exp)
          expect(@vector.dtype).to eq(exp.dtype)
        end

        it "destructively maps and returns a vector of dtype nmatrix" do
          @vector.recode!(:nmatrix) { |v| v == -99 ? 1 : 0 }
          exp = Daru::Vector.new [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1], dtype: :nmatrix
          expect(@vector).to eq(exp)
          expect(@vector.dtype).to eq(exp.dtype)
        end
      end

      context "#verify" do
        it "returns a hash of invalid data and index of data" do
          v = Daru::Vector.new [1,2,3,4,5,6,-99,35,-100], dtype: dtype
          h = v.verify { |d| d > 0 }
          e = { 6 => -99, 8 => -100 }
          expect(h).to eq(e)
        end
      end

      context "#summary" do
        it "has name in the summary" do
          expect(@common_all_dtypes.summary.match("#{@common_all_dtypes.name}")).to_not eq(nil)
        end
      end

      context "#bootstrap" do
        it "returns a vector with mean=mu and sd=se" do
          rng = Distribution::Normal.rng(0, 1)
          vector =Daru::Vector.new_with_size(100, dtype: dtype) { rng.call}

          df = vector.bootstrap([:mean, :sd], 200)
          se = 1 / Math.sqrt(vector.size)
          expect(df[:mean].mean).to be_within(0.3).of(0)
          expect(df[:mean].sd).to be_within(0.02).of(se)
        end
      end
    end
  end # describe ALL_DTYPES.each

  # -----------------------------------------------------------------------
  # works with arrays only

  context "#splitted" do
    it "splits correctly" do
      a = Daru::Vector.new ['a', 'a,b', 'c,d', 'a,d', 'd', 10, nil]
      expect(a.splitted).to eq([%w(a), %w(a b), %w(c d), %w(a d), %w(d), [10], nil])
    end
  end

  context "#missing_values" do
    before do
      @common = Daru::Vector.new([5, 5, 5, 5, 5, 6, 6, 7, 8, 9, 10, 1, 2, 3, 4, nil, -99, -99])
    end

    it "allows setting the value to be treated as missing" do
      @common.missing_values = [10]
      expect(@common.only_valid.to_a.sort).to eq(
        [-99, -99, 1, 2, 3, 4, 5, 5, 5, 5, 5, 6, 6, 7, 8, 9]
      )
      expect(@common.to_a).to eq(
        [5, 5, 5, 5, 5, 6, 6, 7, 8, 9, 10, 1, 2, 3, 4, nil, -99, -99]
      )

      @common.missing_values = [-99]
      expect(@common.only_valid.to_a.sort).to eq(
        [1, 2, 3, 4, 5, 5, 5, 5, 5, 6, 6, 7, 8, 9, 10]
      )
      expect(@common.to_a).to eq(
        [5, 5, 5, 5, 5, 6, 6, 7, 8, 9, 10, 1, 2, 3, 4, nil, -99, -99]
      )

      @common.missing_values = []
      expect(@common.only_valid.to_a.sort).to eq(
        [-99, -99, 1, 2, 3, 4, 5, 5, 5, 5, 5, 6, 6, 7, 8, 9, 10]
      )
      expect(@common.to_a).to eq(
        [5, 5, 5, 5, 5, 6, 6, 7, 8, 9, 10, 1, 2, 3, 4, nil, -99, -99]  
      )
    end

    it "responds to has_missing_data? with explicit missing_values" do
      a = Daru::Vector.new [1,2,3,4,10]
      a.missing_values = [10]

      expect(a.has_missing_data?).to eq(true)
    end
  end

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

  context "#missing_positions" do
    context Daru::Index do
      before(:each) do
        @with_md = Daru::Vector.new([1,2,nil,3,4,nil])
      end

      it "returns the indexes of nils" do
        expect(@with_md.missing_positions).to eq([2,5])
      end

      it "updates after assingment" do
        @with_md[3] = nil
        expect(@with_md.missing_positions).to eq([2,3,5])
      end
    end

    context Daru::MultiIndex do
      it "returns indexes of nils" do
        mi = Daru::MultiIndex.from_tuples([
          ['M', 2000],
          ['M', 2001],
          ['M', 2002],
          ['M', 2003],
          ['F', 2000],
          ['F', 2001],
          ['F', 2002],
          ['F', 2003]
          ])
        vector = Daru::Vector.new([nil,2,4,5,3,nil,2,nil], index: mi)
        expect(vector.missing_positions).to eq([
          ['M',2000], 
          ['F',2001],
          ['F',2003]
        ])
      end
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
      @numeric    = Daru::Vector.new([1,2,3,4,5])
      @multi      = Daru::Vector.new([1,2,3,'sameer','d'])
      @with_nils  = Daru::Vector.new([1,2,3,4,nil])
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

  context "#to_matrix" do
    before do
      @vector = Daru::Vector.new [1,2,3,4,5,6]
    end

    it "converts Daru::Vector to a horizontal Ruby Matrix" do
      expect(@vector.to_matrix).to eq(Matrix[[1,2,3,4,5,6]])
    end

    it "converts Daru::Vector to a vertical Ruby Matrix" do
      expect(@vector.to_matrix(:vertical)).to eq(Matrix.columns([[1,2,3,4,5,6]]))
    end
  end

  context "#only_valid" do
    it "returns a Vector of only non-nil data" do
      vector = Daru::Vector.new [1,2,3,4,nil,3,nil], 
        index: [:a, :b, :c, :d, :e, :f, :g]
      expect(vector.only_valid).to eq(Daru::Vector.new([1,2,3,4,3], 
        index: [:a, :b, :c, :d, :f]))
    end
  end

  context "#only_numerics" do
    it "returns only numerical or missing data" do
      v = Daru::Vector.new([1,2,nil,3,4,'s','a',nil])
      expect(v.only_numerics).to eq(Daru::Vector.new([1,2,nil,3,4,nil],
        index: [0,1,2,3,4,7]))
    end
  end

  context "#to_gsl" do
    it "returns a GSL::Vector of non-nil data" do
      vector = Daru::Vector.new [1,2,3,4,nil,6,nil]
      expect(vector.to_gsl).to eq(GSL::Vector.alloc(1,2,3,4,6))

      gsl_vec = Daru::Vector.new [1,2,3,4,5], dtype: :gsl
      expect(gsl_vec.to_gsl).to eq(GSL::Vector.alloc(1,2,3,4,5))
    end
  end

  context "#split_by_separator" do
    def expect_correct_tokens hash
      expect(hash['a'].to_a).to eq([1, 1, 0, 1, 0, nil])
      expect(hash['b'].to_a).to eq([0, 1, 0, 0, 0, nil])
      expect(hash['c'].to_a).to eq([0, 0, 1, 0, 0, nil])
      expect(hash['d'].to_a).to eq([0, 0, 1, 1, 0, nil])
      expect(hash[10].to_a).to eq([0, 0, 0, 0, 1, nil])
    end

    before do
      @a = Daru::Vector.new ['a', 'a,b', 'c,d', 'a,d', 10, nil]
      @b = @a.split_by_separator(',')
    end

    it "returns a Hash" do
      expect(@b.class).to eq(Hash)
    end

    it "returned Hash has keys with with different values of @a" do
      expect(@b.keys).to eq(['a', 'b', 'c', 'd', 10])
    end

    it "returns a Hash, whose values are Daru::Vector" do
      @b.each_key do |key|
        expect(@b[key].class).to eq(Daru::Vector)
      end
    end

    it "ensures that hash values are n times the tokens appears" do
      expect_correct_tokens @b
    end

    it "gives the same values using a different separator" do
      a = Daru::Vector.new ['a', 'a*b', 'c*d', 'a*d', 10, nil]
      b = a.split_by_separator '*'
      expect_correct_tokens b
    end
  end

  context "#split_by_separator_freq" do
    it "returns the number of ocurrences of tokens" do
      a = Daru::Vector.new ['a', 'a,b', 'c,d', 'a,d', 10, nil]
      expect(a.split_by_separator_freq).to eq(
        { 'a' => 3, 'b' => 1, 'c' => 1, 'd' => 2, 10 => 1 }) 
    end
  end

  context "#n_valid" do
    it "returns number of non-missing positions" do
      v = Daru::Vector.new [1,2,3,4,nil,nil,3,5]
      expect(v.n_valid).to eq(6)
    end
  end

  context "#reset_index!" do
    it "resets any index to a numerical serialized index" do
      v = Daru::Vector.new([1,2,3,4,5,nil,nil,4,nil])
      r = v.only_valid.reset_index!
      expect(r).to eq(Daru::Vector.new([1,2,3,4,5,4]))
      expect(r.index).to eq(Daru::Index.new([0,1,2,3,4,5]))

      indexed = Daru::Vector.new([1,2,3,4,5], index: [:a, :b, :c, :d, :e])
      expect(indexed.reset_index!.index).to eq(Daru::Index.new([0,1,2,3,4]))
    end
  end

  context "#rename" do
    before :each do
      @v = Daru::Vector.new [1,2,3,4,5,5], name: :this_vector
    end

    it "assings name" do
      @v.rename :that_vector
      expect(@v.name).to eq(:that_vector)
    end

    it "stores name as a symbol" do
      @v.rename "This is a vector"
      expect(@v.name).to eq("This is a vector")
    end
  end

  context "#any?" do
    before do
      @v = Daru::Vector.new([1,2,3,4,5])
    end

    it "returns true if block returns true for any one of the elements" do
      expect(@v.any?{ |e| e == 1 }).to eq(true)
    end

    it "returns false if block is false for all elements" do
      expect(@v.any?{ |e| e > 10 }).to eq(false)
    end
  end 

  context "#all?" do
    before do
      @v = Daru::Vector.new([1,2,3,4,5])
    end

    it "returns true if block is true for all elements" do
      expect(@v.all? { |e| e < 6 }).to eq(true)
    end

    it "returns false if block is false for any one element" do
      expect(@v.all? { |e| e == 2 }).to eq(false)
    end
  end

  context "#only_missing" do
    it "returns a vector (with proper index) of all the elements marked 'missing'" do
      v = Daru::Vector.new([1,2,3,4,5,6,4,5,5,4,4,nil,nil,nil])
      v.missing_values = [nil, 5]

      expect(v.only_missing).to eq(Daru::Vector.new([5,5,5,nil,nil,nil], 
        index: [4,7,8,11,12,13]))
    end
  end

  context "#detach_index" do
    it "creates a DataFrame with first Vector as index and second as values of the Vector" do
      v = Daru::Vector.new([1,2,3,4,5,6], 
        index: ['a', 'b', 'c', 'd', 'e', 'f'], name: :values)
      expect(v.detach_index).to eq(Daru::DataFrame.new({
        index: ['a', 'b', 'c', 'd', 'e', 'f'],
        values: [1,2,3,4,5,6]
      }))
    end
  end

  context "#lag" do
    it "lags the vector by specified amount" do
      xiu = Daru::Vector.new([17.28, 17.45, 17.84, 17.74, 17.82, 17.85, 17.36, 17.3, 17.56, 17.49, 17.46, 17.4, 17.03, 17.01,
        16.86, 16.86, 16.56, 16.36, 16.66, 16.77])
      lag1 = xiu.lag

      expect(lag1[lag1.size - 1]).to be_within(0.001).of(16.66)
      expect(lag1[lag1.size - 2]).to be_within(0.001).of(16.36)

      #test with different lagging unit
      lag2 = xiu.lag(2)

      expect(lag2[lag2.size - 1]).to be_within(0.001).of(16.36)
      expect(lag2[lag2.size - 2]).to be_within(0.001).of(16.56)
    end
  end
end if mri?
