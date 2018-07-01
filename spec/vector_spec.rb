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

        it "initializes array with nils with dtype NMatrix" do
          dv = Daru::Vector.new [2, nil], dtype: :nmatrix
          expect(dv.to_a).to eq([2, nil])
          expect(dv.index.to_a).to eq([0, 1])
        end
      end

      context "#reorder!" do
        let(:vector_with_dtype) do
          Daru::Vector.new(
            [1, 2, 3, 4],
            index: [:a, :b, :c, :d],
            dtype: dtype)
        end
        let(:arranged_vector) do
          Daru::Vector.new([4,3,2,1], index: [:d, :c, :b, :a], dtype: dtype)
        end

        before do
          vector_with_dtype.reorder! [3, 2, 1, 0]
        end

        it "rearranges with passed order" do
          expect(vector_with_dtype).to eq arranged_vector
        end

        it "doesn't change dtype" do
          expect(vector_with_dtype.data.class).to eq arranged_vector.data.class
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

          it "raises exception for invalid index" do
            expect { @dv[:foo] }.to raise_error(IndexError)
            expect { @dv[:obi, :foo] }.to raise_error(IndexError)
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
              [:c,:two,:bar],
              [:d,:one,:foo]
            ]
            @multi_index = Daru::MultiIndex.from_tuples(@tuples)
            @vector = Daru::Vector.new(
              Array.new(13) { |i| i }, index: @multi_index,
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

          it "returns sub vector not a single element when passed the partial tuple" do
            mi = Daru::MultiIndex.from_tuples([[:foo]])
            expect(@vector[:d, :one]).to eq(Daru::Vector.new([12], index: mi,
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

          it "raises exception for invalid index" do
            expect { @vector[:foo] }.to raise_error(IndexError)
            expect { @vector[:a, :two, :foo] }.to raise_error(IndexError)
            expect { @vector[:x, :one] }.to raise_error(IndexError)
          end
        end

        context Daru::CategoricalIndex do
          # before { skip }
          context "non-numerical index" do
            let (:idx) { Daru::CategoricalIndex.new [:a, :b, :a, :a, :c] }
            let (:dv)  { Daru::Vector.new 'a'..'e', index: idx }

            context "single category" do
              context "multiple instances" do
                subject { dv[:a] }

                it { is_expected.to be_a Daru::Vector }
                its(:size) { is_expected.to eq 3 }
                its(:to_a) { is_expected.to eq  ['a', 'c', 'd'] }
                its(:index) { is_expected.to eq(
                  Daru::CategoricalIndex.new([:a, :a, :a])) }
              end

              context "single instance" do
                subject { dv[:c] }

                it { is_expected.to eq 'e' }
              end
            end

            context "multiple categories" do
              subject { dv[:a, :c] }

              it { is_expected.to be_a Daru::Vector }
              its(:size) { is_expected.to eq 4 }
              its(:to_a) { is_expected.to eq  ['a', 'c', 'd', 'e'] }
              its(:index) { is_expected.to eq(
                Daru::CategoricalIndex.new([:a, :a, :a, :c])) }
            end

            context "multiple positional indexes" do
              subject { dv[0, 1, 2] }

              it { is_expected.to be_a Daru::Vector }
              its(:size) { is_expected.to eq 3 }
              its(:to_a) { is_expected.to eq ['a', 'b', 'c'] }
              its(:index) { is_expected.to eq(
                Daru::CategoricalIndex.new([:a, :b, :a])) }
            end

            context "single positional index" do
              subject { dv[1] }

              it { is_expected.to eq 'b' }
            end

            context "invalid category" do
              it { expect { dv[:x] }.to raise_error IndexError }
            end

            context "invalid positional index" do
              it { expect { dv[30] }.to raise_error IndexError }
            end
          end

          context "numerical index" do
            let (:idx) { Daru::CategoricalIndex.new [1, 1, 2, 2, 3] }
            let (:dv)  { Daru::Vector.new 'a'..'e', index: idx }

            context "single category" do
              context "multiple instances" do
                subject { dv[1] }

                it { is_expected.to be_a Daru::Vector }
                its(:size) { is_expected.to eq 2 }
                its(:to_a) { is_expected.to eq  ['a', 'b'] }
                its(:index) { is_expected.to eq(
                  Daru::CategoricalIndex.new([1, 1])) }
              end

              context "single instance" do
                subject { dv[3] }

                it { is_expected.to eq 'e' }
              end
            end
          end
        end
      end

      context "#at" do
        context Daru::Index do
          let (:idx) { Daru::Index.new [1, 0, :c] }
          let (:dv) { Daru::Vector.new ['a', 'b', 'c'], index: idx }

          let (:idx_dt) { Daru::DateTimeIndex.new(['2017-01-01', '2017-02-01', '2017-03-01']) }
          let (:dv_dt) { Daru::Vector.new(['a', 'b', 'c'], index: idx_dt) }

          context "single position" do
            it { expect(dv.at 1).to eq 'b' }
          end

          context "multiple positions" do
            subject { dv.at 0, 2 }

            it { is_expected.to be_a Daru::Vector }
            its(:size) { is_expected.to eq 2 }
            its(:to_a) { is_expected.to eq ['a', 'c'] }
            its(:'index.to_a') { is_expected.to eq [1, :c] }
          end

          context "invalid position" do
            it { expect { dv.at 3 }.to raise_error IndexError }
          end

          context "invalid positions" do
            it { expect { dv.at 2, 3 }.to raise_error IndexError }
          end

          context "range" do
            subject { dv.at 0..1 }

            it { is_expected.to be_a Daru::Vector }
            its(:size) { is_expected.to eq 2 }
            its(:to_a) { is_expected.to eq ['a', 'b'] }
            its(:'index.to_a') { is_expected.to eq [1, 0] }
          end

          context "range with negative end" do
            subject { dv.at 0..-2 }

            it { is_expected.to be_a Daru::Vector }
            its(:size) { is_expected.to eq 2 }
            its(:to_a) { is_expected.to eq ['a', 'b'] }
            its(:'index.to_a') { is_expected.to eq [1, 0] }
          end

          context "range with single element" do
            subject { dv.at 0..0 }

            it { is_expected.to be_a Daru::Vector }
            its(:size) { is_expected.to eq 1 }
            its(:to_a) { is_expected.to eq ['a'] }
            its(:'index.to_a') { is_expected.to eq [1] }
          end

          context "Splat .at on DateTime index" do
            subject { dv_dt.at(*[1,2]) }

            it { is_expected.to be_a Daru::Vector }
            its(:size) { is_expected.to eq 2 }
            its(:to_a) { is_expected.to eq ['b', 'c'] }
            its(:'index.to_a') { is_expected.to eq ['2017-02-01', '2017-03-01'] }
          end
        end

        context Daru::MultiIndex do
          let (:idx) do
            Daru::MultiIndex.from_tuples [
              [:a,:one,:bar],
              [:a,:one,:baz],
              [:b,:two,:bar],
              [:a,:two,:baz],
            ]
          end
          let (:dv) { Daru::Vector.new 1..4, index: idx }

          context "single position" do
            it { expect(dv.at 1).to eq 2 }
          end

          context "multiple positions" do
            subject { dv.at 2, 3 }

            it { is_expected.to be_a Daru::Vector }
            its(:size) { is_expected.to eq 2 }
            its(:to_a) { is_expected.to eq [3, 4] }
            its(:'index.to_a') { is_expected.to eq [[:b, :two, :bar],
              [:a, :two, :baz]] }
          end

          context "invalid position" do
            it { expect { dv.at 4 }.to raise_error IndexError }
          end

          context "invalid positions" do
            it { expect { dv.at 2, 4 }.to raise_error IndexError }
          end

          context "range" do
            subject { dv.at 2..3 }

            it { is_expected.to be_a Daru::Vector }
            its(:size) { is_expected.to eq 2 }
            its(:to_a) { is_expected.to eq [3, 4] }
            its(:'index.to_a') { is_expected.to eq [[:b, :two, :bar],
              [:a, :two, :baz]] }
          end

          context "range with negative end" do
            subject { dv.at 2..-1 }

            it { is_expected.to be_a Daru::Vector }
            its(:size) { is_expected.to eq 2 }
            its(:to_a) { is_expected.to eq [3, 4] }
            its(:'index.to_a') { is_expected.to eq [[:b, :two, :bar],
              [:a, :two, :baz]] }
          end

          context "range with single element" do
            subject { dv.at 2..2 }

            it { is_expected.to be_a Daru::Vector }
            its(:size) { is_expected.to eq 1 }
            its(:to_a) { is_expected.to eq [3] }
            its(:'index.to_a') { is_expected.to eq [[:b, :two, :bar]] }
          end
        end

        context Daru::CategoricalIndex do
          let (:idx) { Daru::CategoricalIndex.new [:a, 1, 1, :a, :c] }
          let (:dv)  { Daru::Vector.new 'a'..'e', index: idx }

          context "multiple positional indexes" do
            subject { dv.at 0, 1, 2 }

            it { is_expected.to be_a Daru::Vector }
            its(:size) { is_expected.to eq 3 }
            its(:to_a) { is_expected.to eq ['a', 'b', 'c'] }
            its(:index) { is_expected.to eq(
              Daru::CategoricalIndex.new([:a, 1, 1])) }
          end

          context "single positional index" do
            subject { dv.at 1 }

            it { is_expected.to eq 'b' }
          end

          context "invalid position" do
            it { expect { dv.at 5 }.to raise_error IndexError }
          end

          context "invalid positions" do
            it { expect { dv.at 2, 5 }.to raise_error IndexError }
          end

          context "range" do
            subject { dv.at 0..2 }

            it { is_expected.to be_a Daru::Vector }
            its(:size) { is_expected.to eq 3 }
            its(:to_a) { is_expected.to eq ['a', 'b', 'c'] }
            its(:index) { is_expected.to eq(
              Daru::CategoricalIndex.new([:a, 1, 1])) }
          end

          context "range with negative end" do
            subject { dv.at 0..-3 }

            it { is_expected.to be_a Daru::Vector }
            its(:size) { is_expected.to eq 3 }
            its(:to_a) { is_expected.to eq ['a', 'b', 'c'] }
            its(:index) { is_expected.to eq(
              Daru::CategoricalIndex.new([:a, 1, 1])) }
          end

          context "range with single element" do
            subject { dv.at 0..0 }

            it { is_expected.to be_a Daru::Vector }
            its(:size) { is_expected.to eq 1 }
            its(:to_a) { is_expected.to eq ['a'] }
            its(:index) { is_expected.to eq(
              Daru::CategoricalIndex.new([:a])) }
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

          it "fails predictably on unknown index" do
            expect { @vector[:d] = 69 }.to raise_error(IndexError)
            expect { @vector[:b, :three] = 69 }.to raise_error(IndexError)
            expect { @vector[:b, :two, :test] = 69 }.to raise_error(IndexError)
          end
        end

        context Daru::CategoricalIndex do
          context "non-numerical index" do
            let (:idx) { Daru::CategoricalIndex.new [:a, :b, :a, :a, :c] }
            let (:dv)  { Daru::Vector.new 'a'..'e', index: idx }

            context "single category" do
              context "multiple instances" do
                subject { dv }
                before { dv[:a] = 'x' }

                its(:size) { is_expected.to eq 5 }
                its(:to_a) { is_expected.to eq  ['x', 'b', 'x', 'x', 'e'] }
                its(:index) { is_expected.to eq idx }
              end

              context "single instance" do
                subject { dv }
                before { dv[:b] = 'x' }

                its(:size) { is_expected.to eq 5 }
                its(:to_a) { is_expected.to eq  ['a', 'x', 'c', 'd', 'e'] }
                its(:index) { is_expected.to eq idx }
              end
            end

            context "multiple categories" do
              subject { dv }
              before { dv[:a, :c] = 'x' }

              its(:size) { is_expected.to eq 5 }
              its(:to_a) { is_expected.to eq  ['x', 'b', 'x', 'x', 'x'] }
              its(:index) { is_expected.to eq idx }
            end

            context "multiple positional indexes" do
              subject { dv }
              before { dv[0, 1, 2] = 'x' }

              its(:size) { is_expected.to eq 5 }
              its(:to_a) { is_expected.to eq ['x', 'x', 'x', 'd', 'e'] }
              its(:index) { is_expected.to eq idx }
            end

            context "single positional index" do
              subject { dv }
              before { dv[1] = 'x' }

              its(:size) { is_expected.to eq 5 }
              its(:to_a) { is_expected.to eq ['a', 'x', 'c', 'd', 'e'] }
              its(:index) { is_expected.to eq idx }
            end

            context "invalid category" do
              it { expect { dv[:x] = 'x' }.to raise_error IndexError }
            end

            context "invalid positional index" do
              it { expect { dv[30] = 'x'}.to raise_error IndexError }
            end
          end

          context "numerical index" do
            let (:idx) { Daru::CategoricalIndex.new [1, 1, 2, 2, 3] }
            let (:dv)  { Daru::Vector.new 'a'..'e', index: idx }

            context "single category" do
              subject { dv }
              before { dv[1] = 'x' }

              its(:size) { is_expected.to eq 5 }
              its(:to_a) { is_expected.to eq ['x', 'x', 'c', 'd', 'e'] }
              its(:index) { is_expected.to eq idx }
            end

            context "multiple categories" do
              subject { dv }
              before { dv[1, 2] = 'x' }

              its(:size) { is_expected.to eq 5 }
              its(:to_a) { is_expected.to eq ['x', 'x', 'x', 'x', 'e'] }
              its(:index) { is_expected.to eq idx }
            end
          end
        end
      end

      context "#set_at" do
        context Daru::Index do
          let (:idx) { Daru::Index.new [1, 0, :c] }
          let (:dv) { Daru::Vector.new ['a', 'b', 'c'], index: idx }

          context "single position" do
            subject { dv }
            before { dv.set_at [1], 'x' }

            its(:to_a) { is_expected.to eq ['a', 'x', 'c'] }
          end

          context "multiple positions" do
            subject { dv }
            before { dv.set_at [0, 2], 'x' }

            its(:to_a) { is_expected.to eq ['x', 'b', 'x'] }
          end

          context "invalid position" do
            it { expect { dv.set_at [3], 'x' }.to raise_error IndexError }
          end

          context "invalid positions" do
            it { expect { dv.set_at [2, 3], 'x' }.to raise_error IndexError }
          end
        end

        context Daru::MultiIndex do
          let(:idx) do
            Daru::MultiIndex.from_tuples [
              [:a,:one,:bar],
              [:a,:one,:baz],
              [:b,:two,:bar],
              [:a,:two,:baz],
            ]
          end
          let(:dv) { Daru::Vector.new 1..4, index: idx }

          context "single position" do
            subject { dv }
            before { dv.set_at [1], 'x' }

            its(:to_a) { is_expected.to eq [1, 'x', 3, 4] }
          end

          context "multiple positions" do
            subject { dv }
            before { dv.set_at [2, 3], 'x' }

            its(:to_a) { is_expected.to eq [1, 2, 'x', 'x'] }
          end

          context "invalid position" do
            it { expect { dv.set_at [4], 'x' }.to raise_error IndexError }
          end

          context "invalid positions" do
            it { expect { dv.set_at [2, 4], 'x' }.to raise_error IndexError }
          end
        end

        context Daru::CategoricalIndex do
          let (:idx) { Daru::CategoricalIndex.new [:a, 1, 1, :a, :c] }
          let (:dv)  { Daru::Vector.new 'a'..'e', index: idx }

          context "multiple positional indexes" do
            subject { dv }
            before { dv.set_at [0, 1, 2], 'x' }

            its(:to_a) { is_expected.to eq ['x', 'x', 'x', 'd', 'e'] }
          end

          context "single positional index" do
            subject { dv }
            before { dv.set_at [1], 'x' }

            its(:to_a) { is_expected.to eq ['a', 'x', 'c', 'd', 'e'] }
          end

          context "invalid position" do
            it { expect { dv.set_at [5], 'x' }.to raise_error IndexError }
          end

          context "invalid positions" do
            it { expect { dv.set_at [2, 5], 'x' }.to raise_error IndexError }
          end
        end
      end

      context '#head' do
        subject(:vector) do
          Daru::Vector.new (1..20).to_a, dtype: dtype
        end

        it 'takes 10 by default' do
          expect(vector.head).to eq Daru::Vector.new (1..10).to_a
        end

        it 'takes num if provided' do
          expect(vector.head(3)).to eq Daru::Vector.new (1..3).to_a
        end

        it 'does not fail on too large num' do
          expect(vector.head(3000)).to eq vector
        end
      end

      context '#tail' do
        subject(:vector) do
          Daru::Vector.new (1..20).to_a, dtype: dtype
        end

        it 'takes 10 by default' do
          expect(vector.tail).to eq Daru::Vector.new (11..20).to_a, index: (10..19).to_a
        end

        it 'takes num if provided' do
          expect(vector.tail(3)).to eq Daru::Vector.new (18..20).to_a, index: (17..19).to_a
        end

        it 'does not fail on too large num' do
          expect(vector.tail(3000)).to eq vector
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

      context "#to_df" do
        let(:dv) { Daru::Vector.new(['a','b','c'], name: :my_dv, index: ['alpha', 'beta', 'gamma']) }
        let(:df) { dv.to_df }

        it 'is a dataframe' do
          expect(df).to be_a Daru::DataFrame
        end

        it 'converts the vector to a single-vector dataframe' do
          expect(df[:my_dv]).to eq dv
        end

        it 'has the same index as the original vector' do
          expect(df.index).to eq dv.index
        end

        it 'has the same name as the vector' do
          expect(df.name).to eq :my_dv
        end
      end

      context "#to_h" do
        context Daru::Index do
          it "returns the vector as a hash" do
            dv = Daru::Vector.new [1,2,3,4,5], name: :a,
              index: [:one, :two, :three, :four, :five], dtype: dtype

            expect(dv.to_h).to eq({one: 1, two: 2, three: 3, four: 4, five: 5})
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
          #   expect(vector.to_h).to eq({
          #     [:a,:two,:bar] => 1,
          #     [:a,:two,:baz] => 2,
          #     [:b,:one,:bar] => 3,
          #     [:b,:two,:bar] => 4
          #   })
          # end
        end
      end

      context "#to_json" do
        subject(:vector) do
          Daru::Vector.new [1,2,3,4,5], name: :a,
              index: [:one, :two, :three, :four, :five], dtype: dtype
        end

        its(:to_json) { is_expected.to eq(vector.to_h.to_json) }
      end

      context "#to_s" do
        before do
          @v = Daru::Vector.new ["a", "b"], index: [1, 2]
        end

        it 'produces a class, size description' do
          expect(@v.to_s).to eq("#<Daru::Vector(2)>")
        end

        it 'produces a class, name, size description' do
          @v.name = "Test"
          expect(@v.to_s).to eq("#<Daru::Vector: Test(2)>")
        end

        it 'produces a class, name, size description when the name is a symbol' do
          @v.name = :Test
          expect(@v.to_s).to eq("#<Daru::Vector: Test(2)>")
        end
      end

      context "#uniq" do
        before do
          @v = Daru::Vector.new [1, 2, 2, 2.0, 3, 3.0], index:[:a, :b, :c, :d, :e, :f]
        end
        it "keeps only unique values" do
          expect(@v.uniq).to eq(Daru::Vector.new [1, 2, 2.0, 3, 3.0], index: [:a, :b, :d, :e, :f])
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

          it "places nils near the beginning of the vector when sorting ascendingly" do
            with_nils = Daru::Vector.new [22,4,nil,111,nil,2]

            expect(with_nils.sort).to eq(Daru::Vector.new([nil,nil,2,4,22,111], index: [2,4,5,1,0,3]))
          end if dtype == :array

          it "places nils near the beginning of the vector when sorting descendingly" do
            with_nils = Daru::Vector.new [22,4,nil,111,nil,2]

            expect(with_nils.sort(ascending: false)).to eq(
              Daru::Vector.new [111,22,4,2,nil,nil], index: [3,0,1,5,4,2])
          end

          it "correctly sorts vector in ascending order with non-numeric data and nils" do
            non_numeric = Daru::Vector.new ['a','b', nil, 'aa', '1234', nil]

            expect(non_numeric.sort(ascending: true)).to eq(
              Daru::Vector.new [nil,nil,'1234','a','aa','b'], index: [2,5,4,0,3,1])
          end

          it "correctly sorts vector in descending order with non-numeric data and nils" do
            non_numeric = Daru::Vector.new ['a','b', nil, 'aa', '1234', nil]

            expect(non_numeric.sort(ascending: false)).to eq(
              Daru::Vector.new ['b','aa','a','1234',nil,nil], index: [1,3,0,4,5,2])
          end
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

        context Daru::CategoricalIndex do
          let(:idx) { Daru::CategoricalIndex.new [:a, 1, :a, 1, :c] }
          let(:dv_numeric) { Daru::Vector.new [4, 5, 3, 2, 1], index: idx }
          let(:dv_string) { Daru::Vector.new ['xxxx', 'zzzzz', 'ccc', 'bb', 'a'], index: idx }
          let(:dv_nil) { Daru::Vector.new [3, nil, 2, 1, -1], index: idx }

          context "increasing order" do
            context "numeric" do
              subject { dv_numeric.sort }

              its(:size) { is_expected.to eq 5 }
              its(:to_a) { is_expected.to eq [1, 2, 3, 4, 5] }
              its(:'index.to_a') { is_expected.to eq [:c, 1, :a, :a, 1] }
            end

            context "non-numeric" do
              subject { dv_string.sort }

              its(:size) { is_expected.to eq 5 }
              its(:to_a) { is_expected.to eq ['a', 'bb', 'ccc', 'xxxx', 'zzzzz'] }
              its(:'index.to_a') { is_expected.to eq [:c, 1, :a, :a, 1] }
            end

            context "block" do
              subject { dv_string.sort { |a, b| a.length <=> b.length } }

              its(:to_a) { is_expected.to eq ['a', 'bb', 'ccc', 'xxxx', 'zzzzz'] }
              its(:'index.to_a') { is_expected.to eq [:c, 1, :a, :a, 1] }
            end

            context "nils" do
              subject { dv_nil.sort }

              its(:to_a) { is_expected.to eq [nil, -1, 1, 2, 3] }
              its(:'index.to_a') { is_expected.to eq [1, :c, 1, :a, :a] }
            end
          end

          context "decreasing order" do
            context "numeric" do
              subject { dv_numeric.sort(ascending: false) }

              its(:size) { is_expected.to eq 5 }
              its(:to_a) { is_expected.to eq [5, 4, 3, 2, 1] }
              its(:'index.to_a') { is_expected.to eq [1, :a, :a, 1, :c] }
            end

            context "non-numeric" do
              subject { dv_string.sort(ascending: false) }

              its(:size) { is_expected.to eq 5 }
              its(:to_a) { is_expected.to eq ['zzzzz', 'xxxx', 'ccc', 'bb', 'a'] }
              its(:'index.to_a') { is_expected.to eq [1, :a, :a, 1, :c] }
            end

            context "block" do
              subject do
                dv_string.sort(ascending: false) { |a, b| a.length <=> b.length }
              end

              its(:to_a) { is_expected.to eq ['zzzzz', 'xxxx', 'ccc', 'bb', 'a'] }
              its(:'index.to_a') { is_expected.to eq [1, :a, :a, 1, :c] }
            end

            context "nils" do
              subject { dv_nil.sort(ascending: false) }

              its(:to_a) { is_expected.to eq [3, 2, 1, -1, nil] }
              its(:'index.to_a') { is_expected.to eq [:a, :a, 1, :c, 1] }
            end
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

          expect(@vector.index.class).to eq(Daru::DateTimeIndex)
          expect(@vector['2012-1-1']).to eq(1)
        end

        it "accepts an array as index" do
          @vector.index = [5,4,3,2,1]

          expect(@vector.index.class).to eq(Daru::Index)
          expect(@vector[5]).to eq(1)
        end

        it "accepts an range as index" do
          @vector.index = 'a'..'e'

          expect(@vector.index.class).to eq(Daru::Index)
          expect(@vector['a']).to eq(1)
        end

        it "raises error for index size != vector size" do
          expect {
            @vector.index = Daru::Index.new([4,2,6])
          }.to raise_error(ArgumentError, 'Size of supplied index 3 '\
            'does not match size of Vector')
        end
      end

      context "#reindex!" do
        before do
          @vector = Daru::Vector.new([1,2,3,4,5])
          @index = Daru::Index.new([3,4,1,0,6])
        end
        it "intelligently reindexes" do
          @vector.reindex!(@index)
          expect(@vector).to eq(
            Daru::Vector.new([4,5,2,1,nil], index: @index))
        end
      end

      context "#reindex" do
        before do
          @vector = Daru::Vector.new([1,2,3,4,5])
          @index = Daru::Index.new([3,4,1,0,6])
        end
        it "intelligently reindexes" do
          expect(@vector.reindex(@index)).to eq(
            Daru::Vector.new([4,5,2,1,nil], index: @index))
        end
      end

      context "#dup" do
        before do
          @dv = Daru::Vector.new [1,2], name: :yoda, index: [:happy, :lightsaber]
        end

        it "copies the original data" do
          expect(@dv.dup.send(:data)).to eq([1,2])
        end

        it "creates a new data object" do
          expect(@dv.dup.send(:data).object_id).not_to eq(@dv.send(:data).object_id)
        end

        it "copies the name" do
          expect(@dv.dup.name).to eq(:yoda)
        end

        it "copies the original index" do
          expect(@dv.dup.index).to eq(Daru::Index.new([:happy, :lightsaber]))
        end

        it "creates a new index object" do
          expect(@dv.dup.index.object_id).not_to eq(@dv.index.object_id)
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
        subject { dv.summary }

        context 'all types' do
          let(:dv) { Daru::Vector.new([1,2,3,4,5], name: 'vector') }

          it { is_expected.to include dv.name }

          it { is_expected.to include "n :#{dv.size}" }

          it { is_expected.to include "non-missing:#{dv.size - dv.count_values(*Daru::MISSING_VALUES)}" }
        end

        unless dtype == :nmatrix
          context "numeric type" do
            let(:dv) { Daru::Vector.new([1,2,5], name: 'numeric') }

            it { is_expected. to eq %Q{
                |= numeric
                |  n :3
                |  non-missing:3
                |  median: 2
                |  mean: 2.6667
                |  std.dev.: 2.0817
                |  std.err.: 1.2019
                |  skew: 0.2874
                |  kurtosis: -2.3333
              }.unindent }
          end

          context "numeric type with missing values" do
            let(:dv) { Daru::Vector.new([1,2,5,nil,Float::NAN], name: 'numeric') }

            it { is_expected.not_to include 'skew' }
            it { is_expected.not_to include 'kurtosis' }
          end
        end

        if dtype == :array
          context "object type" do
            let(:dv) { Daru::Vector.new([1,1,2,2,"string",nil,Float::NAN], name: 'object') }

            if RUBY_VERSION >= '2.2'
              it { is_expected.to eq %Q{
                  |= object
                  |  n :7
                  |  non-missing:5
                  |  factors: 1,2,string
                  |  mode: 1,2
                  |  Distribution
                  |          string       1  50.00%
                  |             NaN       1  50.00%
                  |               1       2 100.00%
                  |               2       2 100.00%
                }.unindent }
            else
              it { is_expected.to eq %Q{
                |= object
                |  n :7
                |  non-missing:5
                |  factors: 1,2,string
                |  mode: 1,2
                |  Distribution
                |             NaN       1  50.00%
                |          string       1  50.00%
                |               2       2 100.00%
                |               1       2 100.00%
              }.unindent }
            end
          end
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

  context '#is_values' do
    let(:dv) { Daru::Vector.new [10, 11, 10, nil, nil] }

    context 'single value' do
      subject { dv.is_values 10 }
      it { is_expected.to be_a Daru::Vector }
      its(:to_a) { is_expected.to eq [true, false, true, false, false] }
    end

    context 'multiple values' do
      subject { dv.is_values 10, nil }
      it { is_expected.to be_a Daru::Vector }
      its(:to_a) { is_expected.to eq [true, false, true, true, true] }
    end
  end

  context "#clone_structure" do
    context Daru::Index do
      before do
        @vec = Daru::Vector.new([1,2,3,4,5], index: [:a,:b,:c,:d,:e])
      end

      it "clones a vector with its index and fills it with nils" do
        expect(@vec.clone_structure).to eq(Daru::Vector.new([nil,nil,nil,nil,nil], index: [:a,:b,:c,:d,:e]))
      end
    end

    context Daru::MultiIndex do
      pending
    end
  end

  context '#reject_values'do
    let(:dv) { Daru::Vector.new [1, nil, 3, :a, Float::NAN, nil, Float::NAN, 1],
      index: 11..18 }
    context 'reject only nils' do
      subject { dv.reject_values nil }

      it { is_expected.to be_a Daru::Vector }
      its(:to_a) { is_expected.to eq [1, 3, :a, Float::NAN, Float::NAN, 1] }
      its(:'index.to_a') { is_expected.to eq [11, 13, 14, 15, 17, 18] }
    end

    context 'reject only float::NAN' do
      subject { dv.reject_values Float::NAN }

      it { is_expected.to be_a Daru::Vector }
      its(:to_a) { is_expected.to eq [1, nil, 3, :a, nil, 1] }
      its(:'index.to_a') { is_expected.to eq [11, 12, 13, 14, 16, 18] }
    end

    context 'reject both nil and float::NAN' do
      subject { dv.reject_values nil, Float::NAN }

      it { is_expected.to be_a Daru::Vector }
      its(:to_a) { is_expected.to eq [1, 3, :a, 1] }
      its(:'index.to_a') { is_expected.to eq [11, 13, 14, 18] }
    end

    context 'reject any other value' do
      subject { dv.reject_values 1, 3 }

      it { is_expected.to be_a Daru::Vector }
      its(:to_a) { is_expected.to eq [nil, :a, Float::NAN, nil, Float::NAN] }
      its(:'index.to_a') { is_expected.to eq [12, 14, 15, 16, 17] }
    end

    context 'when resultant vector has only one value' do
      subject { dv.reject_values 1, :a, nil, Float::NAN }

      it { is_expected.to be_a Daru::Vector }
      its(:to_a) { is_expected.to eq [3] }
      its(:'index.to_a') { is_expected.to eq [13] }
    end

    context 'when resultant vector has no value' do
      subject { dv.reject_values 1, 3, :a, nil, Float::NAN, 5 }

      it { is_expected.to be_a Daru::Vector }
      its(:to_a) { is_expected.to eq [] }
      its(:'index.to_a') { is_expected.to eq [] }
    end

    context 'works for gsl' do
      let(:dv) { Daru::Vector.new [1, 2, 3, Float::NAN], dtype: :gsl,
        index: 11..14 }
      subject { dv.reject_values Float::NAN }

      it { is_expected.to be_a Daru::Vector }
      its(:dtype) { is_expected.to eq :gsl }
      its(:to_a) { is_expected.to eq [1, 2, 3].map(&:to_f) }
      its(:'index.to_a') { is_expected.to eq [11, 12, 13] }
    end

    context 'test caching' do
      let(:dv) { Daru::Vector.new [nil]*8, index: 11..18}
      before do
        dv.reject_values nil
        [1, nil, 3, :a, Float::NAN, nil, Float::NAN, 1].each_with_index do |v, pos|
          dv.set_at [pos], v
        end
      end

      context 'reject only nils' do
        subject { dv.reject_values nil }

        it { is_expected.to be_a Daru::Vector }
        its(:to_a) { is_expected.to eq [1, 3, :a, Float::NAN, Float::NAN, 1] }
        its(:'index.to_a') { is_expected.to eq [11, 13, 14, 15, 17, 18] }
      end

      context 'reject only float::NAN' do
        subject { dv.reject_values Float::NAN }

        it { is_expected.to be_a Daru::Vector }
        its(:to_a) { is_expected.to eq [1, nil, 3, :a, nil, 1] }
        its(:'index.to_a') { is_expected.to eq [11, 12, 13, 14, 16, 18] }
      end

      context 'reject both nil and float::NAN' do
        subject { dv.reject_values nil, Float::NAN }

        it { is_expected.to be_a Daru::Vector }
        its(:to_a) { is_expected.to eq [1, 3, :a, 1] }
        its(:'index.to_a') { is_expected.to eq [11, 13, 14, 18] }
      end

      context 'reject any other value' do
        subject { dv.reject_values 1, 3 }

        it { is_expected.to be_a Daru::Vector }
        its(:to_a) { is_expected.to eq [nil, :a, Float::NAN, nil, Float::NAN] }
        its(:'index.to_a') { is_expected.to eq [12, 14, 15, 16, 17] }
      end
    end
  end

  context '#include_values?' do
    context 'only nils' do
      context 'true' do
        let(:dv) { Daru::Vector.new [1, 2, 3, :a, 'Unknown', nil] }
        it { expect(dv.include_values? nil).to eq true }
      end

      context 'false' do
        let(:dv) { Daru::Vector.new [1, 2, 3, :a, 'Unknown'] }
        it { expect(dv.include_values? nil).to eq false }
      end
    end

    context 'only Float::NAN' do
      context 'true' do
        let(:dv) { Daru::Vector.new [1, nil, 2, 3, Float::NAN] }
        it { expect(dv.include_values? Float::NAN).to eq true }
      end

      context 'false' do
        let(:dv) { Daru::Vector.new [1, nil, 2, 3] }
        it { expect(dv.include_values? Float::NAN).to eq false }
      end
    end

    context 'both nil and Float::NAN' do
      context 'true with only nil' do
        let(:dv) { Daru::Vector.new [1, Float::NAN, 2, 3] }
        it { expect(dv.include_values? nil, Float::NAN).to eq true }
      end

      context 'true with only Float::NAN' do
        let(:dv) { Daru::Vector.new [1, nil, 2, 3] }
        it { expect(dv.include_values? nil, Float::NAN).to eq true }
      end

      context 'false' do
        let(:dv) { Daru::Vector.new [1, 2, 3] }
        it { expect(dv.include_values? nil, Float::NAN).to eq false }
      end
    end

    context 'any other value' do
      context 'true' do
        let(:dv) { Daru::Vector.new [1, 2, 3, 4, nil] }
        it { expect(dv.include_values? 1, 2, 3, 5).to eq true }
      end

      context 'false' do
        let(:dv) { Daru::Vector.new [1, 2, 3, 4, nil] }
        it { expect(dv.include_values? 5, 6).to eq false }
      end
    end
  end

  context '#count_values' do
    let(:dv) { Daru::Vector.new [1, 2, 3, 1, 2, nil, nil] }
    it { expect(dv.count_values 1, 2).to eq 4 }
    it { expect(dv.count_values nil).to eq 2 }
    it { expect(dv.count_values 3, Float::NAN).to eq 1 }
    it { expect(dv.count_values 4).to eq 0 }
  end

  context '#indexes' do
    context Daru::Index do
      let(:dv) { Daru::Vector.new [1, 2, 1, 2, 3, nil, nil, Float::NAN],
        index: 11..18 }

      subject { dv.indexes 1, 2, nil, Float::NAN }
      it { is_expected.to be_a Array }
      it { is_expected.to eq [11, 12, 13, 14, 16, 17, 18] }
    end

    context Daru::MultiIndex do
      let(:mi) do
        Daru::MultiIndex.from_tuples([
          ['M', 2000],
          ['M', 2001],
          ['M', 2002],
          ['M', 2003],
          ['F', 2000],
          ['F', 2001],
          ['F', 2002],
          ['F', 2003]
        ])
      end
      let(:dv) { Daru::Vector.new [1, 2, 1, 2, 3, nil, nil, Float::NAN],
        index: mi }

      subject { dv.indexes 1, 2, Float::NAN }
      it { is_expected.to be_a Array }
      it { is_expected.to eq(
        [
          ['M', 2000],
          ['M', 2001],
          ['M', 2002],
          ['M', 2003],
          ['F', 2003]
        ]) }
    end
  end

  context '#replace_values' do
    subject do
      Daru::Vector.new(
        [1, 2, 1, 4, nil, Float::NAN, nil, Float::NAN],
        index: 11..18
      )
    end

    context 'replace nils and NaNs' do
      before { subject.replace_values [nil, Float::NAN], 10 }
      its(:to_a) { is_expected.to eq [1, 2, 1, 4, 10, 10, 10, 10] }
    end

    context 'replace arbitrary values' do
      before { subject.replace_values [1, 2], 10 }
      its(:to_a) { is_expected.to eq(
        [10, 10, 10, 4, nil, Float::NAN, nil, Float::NAN]) }
    end

    context 'works for single value' do
      before { subject.replace_values nil, 10 }
      its(:to_a) { is_expected.to eq(
        [1, 2, 1, 4, 10, Float::NAN, 10, Float::NAN]) }
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

  context '#rolling_fillna!' do
    subject do
      Daru::Vector.new(
        [Float::NAN, 2, 1, 4, nil, Float::NAN, 3, nil, Float::NAN]
      )
    end

    context 'rolling_fillna! forwards' do
      before { subject.rolling_fillna!(:forward) }
      its(:to_a) { is_expected.to eq [0, 2, 1, 4, 4, 4, 3, 3, 3] }
    end

    context 'rolling_fillna! backwards' do
      before { subject.rolling_fillna!(direction: :backward) }
      its(:to_a) { is_expected.to eq [2, 2, 1, 4, 3, 3, 3, 0, 0] }
    end

    context 'all invalid vector' do
      subject do
        Daru::Vector.new(
          [Float::NAN, Float::NAN, Float::NAN, Float::NAN, Float::NAN]
        )
      end
      before { subject.rolling_fillna!(:forward) }
      its(:to_a) { is_expected.to eq [0, 0, 0, 0, 0] }
    end

    context 'with non-default index' do
      subject do
        Daru::Vector.new(
          [Float::NAN, 2, 1, 4, nil, Float::NAN, 3, nil, Float::NAN],
          index: %w[a b c d e f g h i]
        )
      end
      before { subject.rolling_fillna!(direction: :backward) }
      it { is_expected.to eq Daru::Vector.new([2, 2, 1, 4, 3, 3, 3, 0, 0], index: %w[a b c d e f g h i]) }
    end
  end

  context '#rolling_fillna' do
    subject do
      Daru::Vector.new(
        [Float::NAN, 2, 1, 4, nil, Float::NAN, 3, nil, Float::NAN]
      )
    end

    context 'rolling_fillna forwards' do
      it { expect(subject.rolling_fillna(:forward).to_a).to eq [0, 2, 1, 4, 4, 4, 3, 3, 3] }
    end

    context 'rolling_fillna backwards' do
      it { expect(subject.rolling_fillna(direction: :backward).to_a).to eq [2, 2, 1, 4, 3, 3, 3, 0, 0] }
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

    it 'raises on wrong axis' do
      expect { @vector.to_matrix(:strange) }.to raise_error(ArgumentError)
    end
  end

  context '#to_nmatrix' do
    let(:dv) { Daru::Vector.new [1, 2, 3, 4, 5] }

    context 'horizontal axis' do
      subject { dv.to_nmatrix }

      it { is_expected.to be_a NMatrix }
      its(:shape) { is_expected.to eq [1, 5] }
      its(:to_a) { is_expected.to eq [1, 2, 3, 4, 5] }
    end

    context 'vertical axis' do
      subject { dv.to_nmatrix :vertical }

      it { is_expected.to be_a NMatrix }
      its(:shape) { is_expected.to eq [5, 1] }
      its(:to_a) { is_expected.to eq [1, 2, 3, 4, 5].map { |i| [i] } }
    end

    context 'invalid axis' do
      it { expect { dv.to_nmatrix :hello }.to raise_error ArgumentError }
    end

    context 'vector contain non-numeric' do
      let(:dv) { Daru::Vector.new [1, 2, nil, 4] }
      it { expect { dv.to_nmatrix }.to raise_error ArgumentError }
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

  context "#reset_index!" do
    it "resets any index to a numerical serialized index" do
      v = Daru::Vector.new([1,2,3,4,5,nil,nil,4,nil])
      r = v.reject_values(*Daru::MISSING_VALUES).reset_index!
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

    it "returns vector" do
      expect(@v.rename 'hello').to be_a Daru::Vector
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

  describe '#lag' do
    let(:source) { Daru::Vector.new(1..5) }

    context 'by default' do
      subject { source.lag }
      it { is_expected.to eq Daru::Vector.new([nil, 1, 2, 3, 4]) }
    end

    subject { source.lag(amount) }

    context '0' do
      let(:amount) { 0 }
      it { is_expected.to eq Daru::Vector.new([1, 2, 3, 4, 5]) }
    end

    context 'same as vector size' do
      let(:amount) { source.size }
      it { is_expected.to eq Daru::Vector.new([nil]*source.size) }
    end

    context 'same as vector -ve size' do
      let(:amount) { -source.size }
      it { is_expected.to eq Daru::Vector.new([nil]*source.size) }
    end

    context 'positive' do
      let(:amount) { 2 }
      it { is_expected.to eq Daru::Vector.new([nil, nil, 1, 2, 3]) }
    end

    context 'negative' do
      let(:amount) { -1 }
      it { is_expected.to eq Daru::Vector.new([2, 3, 4, 5, nil]) }
    end

    context 'large positive' do
      let(:amount) { source.size + 100 }
      it { is_expected.to eq Daru::Vector.new([nil]*source.size) }
    end

    context 'large negative' do
      let(:amount) { -(source.size + 100) }
      it { is_expected.to eq Daru::Vector.new([nil]*source.size) }
    end

  end

  context "#group_by" do
    let(:dv) { Daru::Vector.new [:a, :b, :a, :b, :c] }

    context 'vector not specified' do
      subject { dv.group_by }

      it { is_expected.to be_a Daru::Core::GroupBy }
      its(:'groups.size') { is_expected.to eq 3 }
      its(:groups) { is_expected.to eq({[:a]=>[0, 2], [:b]=>[1, 3], [:c]=>[4]}) }
    end

    context 'vector name specified' do
      before { dv.name = :hello }
      subject { dv.group_by :hello }

      it { is_expected.to be_a Daru::Core::GroupBy }
      its(:'groups.size') { is_expected.to eq 3 }
      its(:groups) { is_expected.to eq({[:a]=>[0, 2], [:b]=>[1, 3], [:c]=>[4]}) }
    end

    context 'vector name invalid' do
      before { dv.name = :hello }
      it { expect { dv.group_by :abc }.to raise_error }
    end
  end

  context '#method_missing' do
    context 'getting' do
      subject(:vector) { Daru::Vector.new [1,2,3], index: [:a, :b, :c] }

      it 'returns value for existing index' do
        expect(vector.a).to eq 1
      end

      it 'raises on getting non-existent index' do
        expect { vector.d }.to raise_error NoMethodError
      end

      it 'sets existing index' do
        vector.a = 5
        expect(vector[:a]).to eq 5
      end

      it 'raises on non-existent index setting' do
        # FIXME: inconsistency between IndexError here and NoMethodError on getting - zverok
        expect { vector.d = 5 }.to raise_error IndexError
      end
    end
  end

  context "#sort_by_index" do
    let(:asc) { vector.sort_by_index }
    let(:desc) { vector.sort_by_index(ascending: false) }

    context 'numeric vector' do
      let(:vector) { Daru::Vector.new [11, 13, 12], index: [23, 21, 22] }
      specify { expect(asc.to_a).to eq [13, 12, 11] }
      specify { expect(desc.to_a).to eq [11, 12, 13] }
    end

    context 'mix variable type index' do
      let(:vector) { Daru::Vector.new [11, Float::NAN, nil],
                              index: [21, 23, 22] }
      specify { expect(asc.to_a).to eq [11, nil, Float::NAN] }
      specify { expect(desc.to_a).to eq [Float::NAN, nil, 11] }
    end
  end

  context '#db_type' do
    it 'is DATE for vector with any date in it' do
      # FIXME: is it sane?.. - zverok
      expect(Daru::Vector.new(['2016-03-01', 'foo', 4]).db_type).to eq 'DATE'
    end

    it 'is INTEGER for digits-only values' do
      expect(Daru::Vector.new(['123', 456, 789]).db_type).to eq 'INTEGER'
    end

    it 'is DOUBLE for digits-and-point values' do
      expect(Daru::Vector.new(['123.4', 456, 789e-10]).db_type).to eq 'DOUBLE'
    end

    it 'is VARCHAR for everyting else' do
      expect(Daru::Vector.new(['123 and stuff', 456, 789e-10]).db_type).to eq 'VARCHAR (255)'
    end
  end

  context 'on wrong dtypes' do
    it 'should not accept mdarray' do
      expect { Daru::Vector.new([], dtype: :mdarray) }.to raise_error(NotImplementedError)
    end

    it 'should not accept anything else' do
      expect { Daru::Vector.new([], dtype: :kittens) }.to raise_error(ArgumentError)
    end
  end

  context '#where clause when Nan, nil data value is present' do
    let(:v) { Daru::Vector.new([1,2,3,Float::NAN, nil]) }

    it 'missing/undefined data in Vector/DataFrame' do
      expect(v.where(v.lt(4))).to eq(Daru::Vector.new([1,2,3]))
      expect(v.where(v.lt(3))).to eq(Daru::Vector.new([1,2]))
      expect(v.where(v.lt(2))).to eq(Daru::Vector.new([1]))
    end
  end
end if mri?
