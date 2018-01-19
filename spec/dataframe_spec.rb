describe Daru::DataFrame do
  before :each do
    @data_frame = Daru::DataFrame.new({b: [11,12,13,14,15], a: [1,2,3,4,5],
      c: [11,22,33,44,55]},
      order: [:a, :b, :c],
      index: [:one, :two, :three, :four, :five])
    tuples = [
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
    @multi_index = Daru::MultiIndex.from_tuples(tuples)

    @vector_arry1 = [11,12,13,14,11,12,13,14,11,12,13,14]
    @vector_arry2 = [1,2,3,4,1,2,3,4,1,2,3,4]

    @order_mi = Daru::MultiIndex.from_tuples([
      [:a,:one,:bar],
      [:a,:two,:baz],
      [:b,:two,:foo],
      [:b,:one,:foo]])

    @df_mi = Daru::DataFrame.new([
      @vector_arry1,
      @vector_arry2,
      @vector_arry1,
      @vector_arry2], order: @order_mi, index: @multi_index)
  end

  context ".rows" do
    before do
      @rows = [
        [1,2,3,4,5],
        [1,2,3,4,5],
        [1,2,3,4,5],
        [1,2,3,4,5]
      ]
    end

    context Daru::Index do
      it "creates a DataFrame from Array rows" do
        df = Daru::DataFrame.rows @rows, order: [:a,:b,:c,:d,:e]

        expect(df.index)      .to eq(Daru::Index.new [0,1,2,3])
        expect(df.vectors)    .to eq(Daru::Index.new [:a,:b,:c,:d,:e])
        expect(df[:a]) .to eq(Daru::Vector.new [1,1,1,1])
      end

      it "creates empty dataframe" do
        df = Daru::DataFrame.rows [], order: [:a, :b, :c]

        expect(df.vectors).to eq(Daru::Index.new [:a,:b,:c])
        expect(df.index).to be_empty
      end

      it "creates a DataFrame from Vector rows" do
        rows = @rows.map { |r| Daru::Vector.new r, index: [:a,:b,:c,:d,:e] }

        df = Daru::DataFrame.rows rows, order: [:a,:b,:c,:d,:e]

        expect(df.index)      .to eq(Daru::Index.new [0,1,2,3])
        expect(df.vectors)    .to eq(Daru::Index.new [:a,:b,:c,:d,:e])
        expect(df[:a]) .to eq(Daru::Vector.new [1,1,1,1])
      end

      it 'derives index & order from arrays' do
        df = Daru::DataFrame.rows @rows
        expect(df.index)    .to eq(Daru::Index.new [0,1,2,3])
        expect(df.vectors)  .to eq(Daru::Index.new %w[0 1 2 3 4])
      end

      it 'derives index & order from vectors' do
        rows = @rows.zip(%w[w x y z]).map { |r, n| Daru::Vector.new r, index: [:a,:b,:c,:d,:e], name: n }
        df = Daru::DataFrame.rows rows
        expect(df.index)    .to eq(Daru::Index.new %w[w x y z])
        expect(df.vectors)  .to eq(Daru::Index.new [:a,:b,:c,:d,:e])
      end

      it 'behaves, when rows are repeated' do
        rows = @rows.zip(%w[w w y z]).map { |r, n| Daru::Vector.new r, index: [:a,:b,:c,:d,:e], name: n }
        df = Daru::DataFrame.rows rows
        expect(df.index)    .to eq(Daru::Index.new %w[w_1 w_2 y z])
        expect(df.vectors)  .to eq(Daru::Index.new [:a,:b,:c,:d,:e])
      end

      it 'behaves, when vectors are unnamed' do
        rows = @rows.map { |r| Daru::Vector.new r, index: [:a,:b,:c,:d,:e] }
        df = Daru::DataFrame.rows rows
        expect(df.index)    .to eq(Daru::Index.new [0,1,2,3])
        expect(df.vectors)  .to eq(Daru::Index.new [:a,:b,:c,:d,:e])
      end
    end

    context Daru::MultiIndex do
      it "creates a DataFrame from rows" do
        df = Daru::DataFrame.rows(
          @rows*3, index: @multi_index, order: [:a,:b,:c,:d,:e])

        expect(df.index)     .to eq(@multi_index)
        expect(df.vectors)   .to eq(Daru::Index.new([:a,:b,:c,:d,:e]))
        expect(df[:a]).to eq(Daru::Vector.new([1]*12, index: @multi_index))
      end

      it "crates a DataFrame from rows (MultiIndex order)" do
        rows = [
          [11, 1, 11, 1],
          [12, 2, 12, 2],
          [13, 3, 13, 3],
          [14, 4, 14, 4]
        ]
        index = Daru::MultiIndex.from_tuples([
          [:one,:bar],
          [:one,:baz],
          [:two,:foo],
          [:two,:bar]
        ])

        df = Daru::DataFrame.rows(rows, index: index, order: @order_mi)
        expect(df.index)  .to eq(index)
        expect(df.vectors).to eq(@order_mi)
        expect(df[:a, :one, :bar]).to eq(Daru::Vector.new([11,12,13,14],
          index: index))
      end

      it "creates a DataFrame from Vector rows" do
        rows = @rows*3
        rows.map! { |r| Daru::Vector.new(r, index: @multi_index) }

        df = Daru::DataFrame.rows rows, order: @multi_index

        expect(df.index).to eq(Daru::Index.new(Array.new(rows.size) { |i| i }))
        expect(df.vectors).to eq(@multi_index)
        expect(df[:a,:one,:bar]).to eq(Daru::Vector.new([1]*12))
      end
    end
  end

  context "#initialize" do

    it "initializes an empty DataFrame with no arguments" do
      df = Daru::DataFrame.new
      expect(df.nrows).to eq(0)
      expect(df.ncols).to eq(0)
    end

    context Daru::Index do
      it "initializes an empty DataFrame with empty source arg" do
        df = Daru::DataFrame.new({}, order: [:a, :b])

        expect(df.vectors).to eq(Daru::Index.new [:a, :b])
        expect(df.a.class).to eq(Daru::Vector)
        expect(df.a)      .to eq([].dv(:a))
      end

      it "initializes from a Hash" do
        df = Daru::DataFrame.new({b: [11,12,13,14,15], a: [1,2,3,4,5]}, order: [:a, :b],
          index: [:one, :two, :three, :four, :five])

        expect(df.index)  .to eq(Daru::Index.new [:one, :two, :three, :four, :five])
        expect(df.vectors).to eq(Daru::Index.new [:a, :b])
        expect(df.a.class).to eq(Daru::Vector)
        expect(df.a)      .to eq([1,2,3,4,5].dv(:a, df.index))
      end

      it "initializes from a Hash and preserves default order" do
        df = Daru::DataFrame.new({b: [11,12,13,14,15], a: [1,2,3,4,5]},
          index: [:one, :two, :three, :four, :five])

        expect(df.vectors).to eq(Daru::Index.new [:b, :a])
      end

      it "initializes from a Hash of Vectors" do
        va = Daru::Vector.new([1,2,3,4,5], index: [:one, :two, :three, :four, :five])
        vb = Daru::Vector.new([11,12,13,14,15], index: [:one, :two, :three, :four, :five])

        df = Daru::DataFrame.new({ b: vb, a: va }, order: [:a, :b], index: [:one, :two, :three, :four, :five])

        expect(df.index)  .to eq(Daru::Index.new [:one, :two, :three, :four, :five])
        expect(df.vectors).to eq(Daru::Index.new [:a, :b])
        expect(df.a.class).to eq(Daru::Vector)
        expect(df.a)      .to eq([1,2,3,4,5].dv(:a, [:one, :two, :three, :four, :five]))
      end

      it "initializes from an Array of Hashes" do
        df = Daru::DataFrame.new([{a: 1, b: 11}, {a: false, b: 12}, {a: 3, b: 13},
          {a: 4, b: 14}, {a: 5, b: 15}], order: [:b, :a],
          index: [:one, :two, :three, :four, :five])

        expect(df.index)  .to eq(Daru::Index.new [:one, :two, :three, :four, :five])
        expect(df.vectors).to eq(Daru::Index.new [:b, :a])
        expect(df.a.class).to eq(Daru::Vector)
        expect(df.a)      .to eq([1,false,3,4,5].dv(:a,[:one, :two, :three, :four, :five]))
      end

      it "initializes from Array of Arrays" do
        df = Daru::DataFrame.new([[1]*5, [2]*5, [3]*5], order: [:b, :a, :c])

        expect(df.index)  .to eq(Daru::Index.new(5))
        expect(df.vectors).to eq(Daru::Index.new([:b, :a, :c]))
        expect(df.a)      .to eq(Daru::Vector.new([2]*5))
      end

      it "initializes from Array of Vectors" do
        df = Daru::DataFrame.new([Daru::Vector.new([1]*5), Daru::Vector.new([2]*5),
         Daru::Vector.new([3]*5)], order: [:b, :a, :c])

        expect(df.index)  .to eq(Daru::Index.new(5))
        expect(df.vectors).to eq(Daru::Index.new([:b, :a, :c]))
        expect(df.a)      .to eq(Daru::Vector.new([2]*5))
      end

      it "accepts Index objects for row/col" do
        rows = Daru::Index.new [:one, :two, :three, :four, :five]
        cols = Daru::Index.new [:a, :b]

        df  = Daru::DataFrame.new({b: [11,12,13,14,15], a: [1,2,3,4,5]}, order: cols,
          index: rows)

        expect(df.a)      .to eq(Daru::Vector.new([1,2,3,4,5], order: [:a], index: rows))
        expect(df.b)      .to eq(Daru::Vector.new([11,12,13,14,15], name: :b, index: rows))
        expect(df.index)  .to eq(Daru::Index.new [:one, :two, :three, :four, :five])
        expect(df.vectors).to eq(Daru::Index.new [:a, :b])
      end

      it "initializes without specifying row/col index" do
        df = Daru::DataFrame.new({b: [11,12,13,14,15], a: [1,2,3,4,5]})

        expect(df.index)  .to eq(Daru::Index.new [0,1,2,3,4])
        expect(df.vectors).to eq(Daru::Index.new [:b, :a])
      end

      it "aligns indexes properly" do
        df = Daru::DataFrame.new({
            b: [11,12,13,14,15].dv(:b, [:two, :one, :four, :five, :three]),
            a:      [1,2,3,4,5].dv(:a, [:two,:one,:three, :four, :five])
          },
            order: [:a, :b]
          )

        expect(df).to eq(Daru::DataFrame.new({
            b: [14,13,12,15,11].dv(:b, [:five, :four, :one, :three, :two]),
            a:      [5,4,2,3,1].dv(:a, [:five, :four, :one, :three, :two])
          }, order: [:a, :b])
        )
      end

      it "adds nil values for missing indexes and aligns by index" do
        df = Daru::DataFrame.new({
                 b: [11,12,13,14,15].dv(:b, [:two, :one, :four, :five, :three]),
                 a: [1,2,3]         .dv(:a, [:two,:one,:three])
               },
               order: [:a, :b]
             )

        expect(df).to eq(Daru::DataFrame.new({
            b: [14,13,12,15,11].dv(:b, [:five, :four, :one, :three, :two]),
            a:  [nil,nil,2,3,1].dv(:a, [:five, :four, :one, :three, :two])
          },
          order: [:a, :b])
        )
      end

      it "adds nils in first vector when other vectors have many extra indexes" do
        df = Daru::DataFrame.new({
            b: [11]                .dv(nil, [:one]),
            a: [1,2,3]             .dv(nil, [:one, :two, :three]),
            c: [11,22,33,44,55]    .dv(nil, [:one, :two, :three, :four, :five]),
            d: [49,69,89,99,108,44].dv(nil, [:one, :two, :three, :four, :five, :six])
          }, order: [:a, :b, :c, :d],
          index: [:one, :two, :three, :four, :five, :six])

        expect(df).to eq(Daru::DataFrame.new({
            b: [11,nil,nil,nil,nil,nil].dv(nil, [:one, :two, :three, :four, :five, :six]),
            a: [1,2,3,nil,nil,nil]     .dv(nil, [:one, :two, :three, :four, :five, :six]),
            c: [11,22,33,44,55,nil]    .dv(nil, [:one, :two, :three, :four, :five, :six]),
            d: [49,69,89,99,108,44]    .dv(nil, [:one, :two, :three, :four, :five, :six])
          }, order: [:a, :b, :c, :d],
          index: [:one, :two, :three, :four, :five, :six])
        )
      end

      it "correctly matches the supplied DataFrame index with the individual vector indexes" do
        df = Daru::DataFrame.new({
            b: [11,12,13] .dv(nil, [:one, :bleh, :blah]),
            a: [1,2,3,4,5].dv(nil, [:one, :two, :booh, :baah, :three]),
            c: [11,22,33,44,55].dv(nil, [0,1,3,:three, :two])
          }, order: [:a, :b, :c], index: [:one, :two, :three])

        expect(df).to eq(Daru::DataFrame.new({
            b: [11,nil,nil].dv(nil, [:one, :two, :three]),
            a: [1,2,5]     .dv(nil, [:one, :two, :three]),
            c: [nil,55,44] .dv(nil, [:one, :two, :three]),
          },
          order: [:a, :b, :c], index: [:one, :two, :three]
          )
        )
      end

      it "completes incomplete vectors" do
        df = Daru::DataFrame.new({b: [11,12,13,14,15], a: [1,2,3,4,5],
          c: [11,22,33,44,55]}, order: [:a, :c])

        expect(df.vectors).to eq([:a,:c,:b].to_index)
      end

      it "does not copy vectors when clone: false" do
        a = Daru::Vector.new([1,2,3,4,5])
        b = Daru::Vector.new([1,2,3,4,5])
        c = Daru::Vector.new([1,2,3,4,5])
        df = Daru::DataFrame.new({a: a, b: b, c: c}, clone: false)

        expect(df[:a].object_id).to eq(a.object_id)
        expect(df[:b].object_id).to eq(b.object_id)
        expect(df[:c].object_id).to eq(c.object_id)
      end

      it "allows creation of empty dataframe with only order" do
        df = Daru::DataFrame.new({}, order: [:a, :b, :c])
        df[:a] = Daru::Vector.new([1,2,3,4,5,6])

        expect(df.size).to eq(6)
        expect(df[:a]).to eq(Daru::Vector.new([1,2,3,4,5,6]))
        expect(df[:b]).to eq(Daru::Vector.new([nil,nil,nil,nil,nil,nil]))
        expect(df[:c]).to eq(Daru::Vector.new([nil,nil,nil,nil,nil,nil]))
      end

      it "allows creation of dataframe without specifying order or index" do
        df = Daru::DataFrame.new({})
        df[:a] = Daru::Vector.new([1,2,3,4,5])

        expect(df.size)        .to eq(5)
        expect(df.index.to_a)  .to eq([0,1,2,3,4])
        expect(df.vectors.to_a).to eq([:a])
        expect(df[:a])         .to eq(Daru::Vector.new([1,2,3,4,5]))
      end

      it "allows creation of dataframe with a default order" do
        arr_of_arrs_df    = Daru::DataFrame.new([[1,2,3], [4,5,6], [7,8,9]])
        arr_of_vectors_df = Daru::DataFrame.new([Daru::Vector.new([1,2,3]), Daru::Vector.new([4,5,6]), Daru::Vector.new([7,8,9])])

        expect(arr_of_arrs_df.vectors.to_a).to eq([0,1,2])
        expect(arr_of_vectors_df.vectors.to_a).to eq([0,1,2])
      end

      it "raises error for incomplete DataFrame index" do
        expect {
          df = Daru::DataFrame.new({b: [11,12,13,14,15], a: [1,2,3,4,5],
            c: [11,22,33,44,55]}, order: [:a, :b, :c],
            index: [:one, :two, :three])
        }.to raise_error
      end

      it "raises error for unequal sized vectors/arrays" do
        expect {
          df = Daru::DataFrame.new({b: [11,12,13], a: [1,2,3,4,5],
            c: [11,22,33,44,55]}, order: [:a, :b, :c],
            index: [:one, :two, :three])
        }.to raise_error
      end
    end

    context Daru::MultiIndex do
      it "creates empty DataFrame" do
        df = Daru::DataFrame.new({}, order: @order_mi)

        expect(df.vectors).to eq(@order_mi)
        expect(df[:a, :one, :bar]).to eq(Daru::Vector.new([]))
      end

      it "creates from Hash" do
        df = Daru::DataFrame.new({
          [:a,:one,:bar] => @vector_arry1,
          [:a,:two,:baz] => @vector_arry2,
          [:b,:one,:foo] => @vector_arry1,
          [:b,:two,:foo] => @vector_arry2
          }, order: @order_mi, index: @multi_index)

        expect(df.index)               .to eq(@multi_index)
        expect(df.vectors)             .to eq(@order_mi)
        expect(df[:a,:one,:bar]).to eq(Daru::Vector.new(@vector_arry1,
          index: @multi_index))
      end

      it "creates from Array of Hashes" do
        # TODO
      end

      it "creates from Array of Arrays" do
        df = Daru::DataFrame.new([@vector_arry1, @vector_arry2, @vector_arry1,
          @vector_arry2], index: @multi_index, order: @order_mi)

        expect(df.index)  .to eq(@multi_index)
        expect(df.vectors).to eq(@order_mi)
        expect(df[:a, :one, :bar]).to eq(Daru::Vector.new(@vector_arry1,
          index: @multi_index))
      end

      it "raises error for order MultiIndex of different size than supplied Array" do
        expect {
          df = Daru::DataFrame.new([@vector_arry1, @vector_arry2], order: @order_mi,
            index: @multi_index)
        }.to raise_error
      end

      it "aligns MultiIndexes properly" do
        pending
        mi_a = @order_mi
        mi_b = Daru::MultiIndex.from_tuples([
          [:b,:one,:foo],
          [:a,:one,:bar],
          [:b,:two,:foo],
          [:a,:one,:baz]
        ])
        mi_sorted = Daru::MultiIndex.from_tuples([
          [:a, :one, :bar],
          [:a, :one, :baz],
          [:b, :one, :foo],
          [:b, :two, :foo]
        ])
        order = Daru::MultiIndex.from_tuples([
          [:pee, :que],
          [:pee, :poo]
        ])
        a  = Daru::Vector.new([1,2,3,4], index: mi_a)
        b  = Daru::Vector.new([11,12,13,14], index: mi_b)
        df = Daru::DataFrame.new([b,a], order: order)

        expect(df).to eq(Daru::DataFrame.new({
          [:pee, :que] => Daru::Vector.new([1,2,4,3], index: mi_sorted),
          [:pee, :poo] => Daru::Vector.new([12,14,11,13], index: mi_sorted)
          }, order: order_mi))
      end

      it "adds nils in case of missing values" do
        # TODO
      end

      it "matches individual vector indexing with supplied DataFrame index" do
        # TODO
      end
    end
  end

  context "#[]" do
    context Daru::Index do
      before :each do
        @df = Daru::DataFrame.new({b: [11,12,13,14,15], a: [1,2,3,4,5],
          c: [11,22,33,44,55]}, order: [:a, :b, :c],
          index: [:one, :two, :three, :four, :five])
      end

      it "returns a Vector" do
        expect(@df[:a]).to eq([1,2,3,4,5].dv(:a, [:one, :two, :three, :four, :five]))
      end

      it "returns a Vector by default" do
        expect(@df[:a]).to eq(Daru::Vector.new([1,2,3,4,5], name: :a,
          index: [:one, :two, :three, :four, :five]))
      end

      it "returns a DataFrame" do
        temp = Daru::DataFrame.new({b: [11,12,13,14,15], a: [1,2,3,4,5]},
          order: [:a, :b], index: [:one, :two, :three, :four, :five])

        expect(@df[:a, :b]).to eq(temp)
      end

      it "accesses vector with Integer index" do
        expect(@df[0]).to eq([1,2,3,4,5].dv(:a, [:one, :two, :three, :four, :five]))
      end

      it "returns a subset of DataFrame when specified range" do
        subset = @df[:b..:c]
        expect(subset).to eq(Daru::DataFrame.new({
          b: [11,12,13,14,15],
          c: [11,22,33,44,55]
          }, index: [:one, :two, :three, :four, :five]))
      end

      it 'accepts axis parameter as a last argument' do
        expect(@df[:a, :vector]).to eq @df[:a]
        expect(@df[:one, :row]).to eq [1, 11, 11].dv(:one, [:a, :b, :c])
      end
    end

    context Daru::MultiIndex do
      it "accesses vector with an integer index" do
        expect(@df_mi[0]).to eq(
          Daru::Vector.new(@vector_arry1, index: @multi_index))
      end

      it "returns a vector when specifying full tuple" do
        expect(@df_mi[:a, :one, :bar]).to eq(
          Daru::Vector.new(@vector_arry1, index: @multi_index))
      end

      it "returns DataFrame when specified first layer of MultiIndex" do
        sub_order = Daru::MultiIndex.from_tuples([
          [:one, :bar],
          [:two, :baz]
          ])
        expect(@df_mi[:a]).to eq(Daru::DataFrame.new([
          @vector_arry1,
          @vector_arry2
        ], index: @multi_index, order: sub_order))
      end

      it "returns a Vector if the last level of MultiIndex is tracked" do
        expect(@df_mi[:a, :one, :bar]).to eq(
          Daru::Vector.new(@vector_arry1, index: @multi_index))
      end
    end
  end

  context "#[]=" do
    context Daru::Index do
      before :each do
        @df = Daru::DataFrame.new({b: [11,12,13,14,15], a: [1,2,3,4,5],
          c: [11,22,33,44,55]}, order: [:a, :b, :c],
          index: [:one, :two, :three, :four, :five])
      end

      it "assigns directly with the []= operator" do
        @data_frame[:a] = [100,200,300,400,500]
        expect(@data_frame).to eq(Daru::DataFrame.new({
          b: [11,12,13,14,15],
          a: [100,200,300,400,500],
          c: [11,22,33,44,55]}, order: [:a, :b, :c],
          index: [:one, :two, :three, :four, :five]))
      end

      it "assigns new vector with default length if given just a value" do
        @df[:d] = 1.0
        expect(@df[:d]).to eq(Daru::Vector.new([1.0, 1.0, 1.0, 1.0, 1.0],
        index: [:one, :two, :three, :four, :five], name: :d))
      end

      it "updates vector with default length if given just a value" do
        @df[:c] = 1.0
        expect(@df[:c]).to eq(Daru::Vector.new([1.0, 1.0, 1.0, 1.0, 1.0],
        index: [:one, :two, :three, :four, :five], name: :c))
      end

      it "appends an Array as a Daru::Vector" do
        @df[:d] = [69,99,108,85,49]

        expect(@df.d.class).to eq(Daru::Vector)
      end

      it "appends an arbitrary enumerable as a Daru::Vector" do
        @df[:d] = Set.new([69,99,108,85,49])

        expect(@df[:d]).to eq(Daru::Vector.new([69, 99, 108, 85, 49],
        index: [:one, :two, :three, :four, :five], name: :c))
      end

      it "replaces an already present vector" do
        @df[:a] = [69,99,108,85,49].dv(nil, [:one, :two, :three, :four, :five])

        expect(@df.a).to eq([69,99,108,85,49].dv(nil, [:one, :two, :three, :four, :five]))
      end

      it "appends a new vector to the DataFrame" do
        @df[:woo] = [69,99,108,85,49].dv(nil, [:one, :two, :three, :four, :five])

        expect(@df.vectors).to eq([:a, :b, :c, :woo].to_index)
      end

      it "creates an index for the new vector if not specified" do
        @df[:woo] = [69,99,108,85,49]

        expect(@df.woo.index).to eq([:one, :two, :three, :four, :five].to_index)
      end

      it "matches index of vector to be inserted with the DataFrame index" do
        @df[:shankar] = [69,99,108,85,49].dv(:shankar, [:two, :one, :three, :five, :four])

        expect(@df.shankar).to eq([99,69,108,49,85].dv(:shankar,
          [:one, :two, :three, :four, :five]))
      end

      it "matches index of vector to be inserted, inserting nils where no match found" do
        @df[:shankar] = [1,2,3].dv(:shankar, [:one, :james, :hetfield])

        expect(@df.shankar).to eq([1,nil,nil,nil,nil].dv(:shankar, [:one, :two, :three, :four, :five]))
      end

      it "raises error for Array assignment of wrong length" do
        expect{
          @df[:shiva] = [1,2,3]
          }.to raise_error
      end

      it "assigns correct name given empty dataframe" do
        df_empty = Daru::DataFrame.new({})
        df_empty[:a] = 1..5
        df_empty[:b] = 1..5

        expect(df_empty[:a].name).to equal(:a)
        expect(df_empty[:b].name).to equal(:b)
      end

      it "appends multiple vectors at a time" do
        # TODO
      end
    end

    context Daru::MultiIndex do
      it "raises error when incomplete index specified but index is absent" do
        expect {
          @df_mi[:d] = [100,200,300,400,100,200,300,400,100,200,300,400]
        }.to raise_error
      end

      it "assigns all sub-indexes when a top level index is specified" do
        @df_mi[:a] = [100,200,300,400,100,200,300,400,100,200,300,400]

        expect(@df_mi).to eq(Daru::DataFrame.new([
          [100,200,300,400,100,200,300,400,100,200,300,400],
          [100,200,300,400,100,200,300,400,100,200,300,400],
          @vector_arry1,
          @vector_arry2], index: @multi_index, order: @order_mi))
      end

      it "creates a new vector when full index specfied" do
        order = Daru::MultiIndex.from_tuples([
          [:a,:one,:bar],
          [:a,:two,:baz],
          [:b,:two,:foo],
          [:b,:one,:foo],
          [:c,:one,:bar]])
        answer = Daru::DataFrame.new([
          @vector_arry1,
          @vector_arry2,
          @vector_arry1,
          @vector_arry2,
          [100,200,300,400,100,200,300,400,100,200,300,400]
          ], index: @multi_index, order: order)
        @df_mi[:c,:one,:bar] = [100,200,300,400,100,200,300,400,100,200,300,400]

        expect(@df_mi).to eq(answer)
      end

      it "assigns correct name given empty dataframe" do
        df_empty = Daru::DataFrame.new([], index: @multi_index, order: @order_mi)
        df_empty[:c, :one, :bar] = 1..12

        expect(df_empty[:c, :one, :bar].name).to eq "conebar"
      end
    end
  end

  context '#method_missing' do
    let(:df) { Daru::DataFrame.new({
      :a  => [1, 2, 3, 4, 5],
      'b' => [5, 4, 3, 2, 1]
    }, index: 11..15)}

    context 'get vector' do
      context 'by string' do
        subject { df.b }

        it { is_expected.to be_a Daru::Vector }
        its(:to_a) { is_expected.to eq [5, 4, 3, 2, 1] }
        its(:'index.to_a') { is_expected.to eq [11, 12, 13, 14, 15] }
      end

      context 'by symbol' do
        subject { df.a }

        it { is_expected.to be_a Daru::Vector }
        its(:to_a) { is_expected.to eq [1, 2, 3, 4, 5] }
        its(:'index.to_a') { is_expected.to eq [11, 12, 13, 14, 15] }
      end
    end

    context 'set existing vector' do
      context 'by string' do
        before { df.b = [:a, :b, :c, :d, :e] }
        subject { df }

        it { is_expected.to be_a Daru::DataFrame }
        its(:'vectors.to_a') { is_expected.to eq [:a, 'b'] }
        its(:'b.to_a') { is_expected.to eq [:a, :b, :c, :d, :e] }
        its(:'index.to_a') { is_expected.to eq [11, 12, 13, 14, 15] }
      end

      context 'by symbol' do
        before { df.a = [:a, :b, :c, :d, :e] }
        subject { df }

        it { is_expected.to be_a Daru::DataFrame }
        its(:'vectors.to_a') { is_expected.to eq [:a, 'b'] }
        its(:'a.to_a') { is_expected.to eq [:a, :b, :c, :d, :e] }
        its(:'index.to_a') { is_expected.to eq [11, 12, 13, 14, 15] }
      end
    end

    context 'set new vector' do
      before { df.c = [5, 5, 5, 5, 5] }
      subject { df }

      it { is_expected.to be_a Daru::DataFrame }
      its(:'vectors.to_a') { is_expected.to eq [:a, 'b', :c] }
      its(:'c.to_a') { is_expected.to eq [5, 5, 5, 5, 5] }
      its(:'index.to_a') { is_expected.to eq [11, 12, 13, 14, 15] }
    end

    context 'reference invalid vector' do
      it { expect { df.d }.to raise_error NoMethodError }
    end
  end

  context '#add_vector' do
    subject(:data_frame) {
      Daru::DataFrame.new({b: [11,12,13,14,15], a: [1,2,3,4,5],
        c: [11,22,33,44,55]}, order: [:a, :b, :c],
        index: [:one, :two, :three, :four, :five])
    }
    before {
      data_frame.add_vector :a, [100,200,300,400,500]
    }

    it { is_expected.to eq(Daru::DataFrame.new({
          b: [11,12,13,14,15],
          a: [100,200,300,400,500],
          c: [11,22,33,44,55]}, order: [:a, :b, :c],
          index: [:one, :two, :three, :four, :five]))
    }
  end

  context "#row[]=" do
    context Daru::Index do
      before :each do
        @df = Daru::DataFrame.new({b: [11,12,13,14,15], a: [1,2,3,4,5],
          c: [11,22,33,44,55]}, order: [:a, :b, :c],
          index: [:one, :two, :three, :four, :five])
      end

      it "assigns specified row when Array" do
        @df.row[:one] = [49, 99, 59]

        expect(@df.row[:one])      .to eq([49, 99, 59].dv(:one, [:a, :b, :c]))
        expect(@df.row[:one].index).to eq([:a, :b, :c].to_index)
        expect(@df.row[:one].name) .to eq(:one)
      end

      it "assigns specified row when DV" do
        @df.row[:one] = [49, 99, 59].dv(nil, [:a, :b, :c])

        expect(@df.row[:one]).to eq([49, 99, 59].dv(:one, [:a, :b, :c]))
      end

      it "assigns correct elements when Vector of different index" do
        @df.row[:one] = Daru::Vector.new([44,62,11], index: [:b,:f,:a])

        expect(@df.row[:one]).to eq(Daru::Vector.new([11,44,nil], index: [:a,:b,:c]))
      end

      it "creates a new row from an Array" do
        @df.row[:patekar] = [9,2,11]

        expect(@df.row[:patekar]).to eq([9,2,11].dv(:patekar, [:a, :b, :c]))
      end

      it "creates a new row from a DV" do
        @df.row[:patekar] = [9,2,11].dv(nil, [:a, :b, :c])

        expect(@df.row[:patekar]).to eq([9,2,11].dv(:patekar, [:a, :b, :c]))
      end

      it "creates a new row from numeric row index and named DV" do
        @df.row[2] = [9,2,11].dv(nil, [:a, :b, :c])

        expect(@df.row[2]).to eq([9,2,11].dv(nil, [:a, :b, :c]))
      end

      it "correctly aligns assigned DV by index" do
        @df.row[:two] = [9,2,11].dv(nil, [:b, :a, :c])

        expect(@df.row[:two]).to eq([2,9,11].dv(:two, [:a, :b, :c]))
      end

      it "correctlu aligns assinged DV by index for new rows" do
        @df.row[:latest] = Daru::Vector.new([2,3,1], index: [:b,:c,:a])

        expect(@df.row[:latest]).to eq(Daru::Vector.new([1,2,3], index: [:a,:b,:c]))
      end

      it "inserts nils for indexes that dont exist in the DataFrame" do
        @df.row[:two] = [49, 99, 59].dv(nil, [:oo, :aah, :gaah])

        expect(@df.row[:two]).to eq([nil,nil,nil].dv(nil, [:a, :b, :c]))
      end

      it "correctly inserts row of a different length by matching indexes" do
        @df.row[:four] = [5,4,3,2,1,3].dv(nil, [:you, :have, :a, :big, :appetite, :spock])

        expect(@df.row[:four]).to eq([3,nil,nil].dv(:four, [:a, :b, :c]))
      end

      it "raises error for row insertion by Array of wrong length" do
        expect{
          @df.row[:one] = [1,2,3,4,5,6,7]
        }.to raise_error
      end
    end

    context Daru::MultiIndex do
      pending
      # TO DO
    end

    context Daru::CategoricalIndex do
      let(:idx) { Daru::CategoricalIndex.new [:a, 1, :a, 1, :c] }
      let(:df) do
        Daru::DataFrame.new({
          a: 'a'..'e',
          b: 1..5
        }, index: idx)
      end

      context "modify exiting row" do
        context "single category" do
          subject { df }
          before { df.row[:a] = ['x', 'y'] }

          it { is_expected.to be_a Daru::DataFrame }
          its(:index) { is_expected.to eq idx }
          its(:vectors) { is_expected.to eq Daru::Index.new [:a, :b] }
          its(:'a.to_a') { is_expected.to eq ['x', 'b', 'x', 'd', 'e'] }
          its(:'b.to_a') { is_expected.to eq ['y', 2, 'y', 4, 5] }
        end

        context "multiple categories" do
          subject { df }
          before { df.row[:a, 1] = ['x', 'y'] }

          it { is_expected.to be_a Daru::DataFrame }
          its(:index) { is_expected.to eq idx }
          its(:vectors) { is_expected.to eq Daru::Index.new [:a, :b] }
          its(:'a.to_a') { is_expected.to eq ['x', 'x', 'x', 'x', 'e'] }
          its(:'b.to_a') { is_expected.to eq ['y', 'y', 'y', 'y', 5] }
        end

        context "positional index" do
          subject { df }
          before { df.row[0, 2] = ['x', 'y'] }

          it { is_expected.to be_a Daru::DataFrame }
          its(:index) { is_expected.to eq idx }
          its(:vectors) { is_expected.to eq Daru::Index.new [:a, :b] }
          its(:'a.to_a') { is_expected.to eq ['x', 'b', 'x', 'd', 'e'] }
          its(:'b.to_a') { is_expected.to eq ['y', 2, 'y', 4, 5] }
        end
      end

      context "add new row" do
        # TODO
      end
    end
  end

  context "#row.at" do
    context Daru::Index do
      let(:idx) { Daru::Index.new [1, 0, :c] }
      let(:df) do
        Daru::DataFrame.new({
          a: 1..3,
          b: 'a'..'c'
        }, index: idx)
      end

      context "single position" do
        subject { df.row.at 1 }

        it { is_expected.to be_a Daru::Vector }
        its(:size) { is_expected.to eq 2 }
        its(:to_a) { is_expected.to eq [2, 'b'] }
        its(:'index.to_a') { is_expected.to eq [:a, :b] }
      end

      context "multiple positions" do
        subject { df.row.at 0, 2 }

        it { is_expected.to be_a Daru::DataFrame }
        its(:size) { is_expected.to eq 2 }
        its(:'index.to_a') { is_expected.to eq [1, :c] }
        its(:'a.to_a') { is_expected.to eq [1, 3] }
        its(:'b.to_a') { is_expected.to eq ['a', 'c'] }
      end

      context "invalid position" do
        it { expect { df.row.at 3 }.to raise_error IndexError }
      end

      context "invalid positions" do
        it { expect { df.row.at 2, 3 }.to raise_error IndexError }
      end

      context "range" do
        subject { df.row.at 0..1 }

        it { is_expected.to be_a Daru::DataFrame }
        its(:size) { is_expected.to eq 2 }
        its(:'index.to_a') { is_expected.to eq [1, 0] }
        its(:'a.to_a') { is_expected.to eq [1, 2] }
        its(:'b.to_a') { is_expected.to eq ['a', 'b'] }
      end

      context "range with negative end" do
        subject { df.row.at 0..-2 }

        it { is_expected.to be_a Daru::DataFrame }
        its(:size) { is_expected.to eq 2 }
        its(:'index.to_a') { is_expected.to eq [1, 0] }
        its(:'a.to_a') { is_expected.to eq [1, 2] }
        its(:'b.to_a') { is_expected.to eq ['a', 'b'] }
      end

      context "range with single element" do
        subject { df.row.at 0..0 }

        it { is_expected.to be_a Daru::DataFrame }
        its(:size) { is_expected.to eq 1 }
        its(:'index.to_a') { is_expected.to eq [1] }
        its(:'a.to_a') { is_expected.to eq [1] }
        its(:'b.to_a') { is_expected.to eq ['a'] }
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
      let (:df) do
        Daru::DataFrame.new({
          a: 1..4,
          b: 'a'..'d'
        }, index: idx )
      end

      context "single position" do
        subject { df.row.at 1 }

        it { is_expected.to be_a Daru::Vector }
        its(:size) { is_expected.to eq 2 }
        its(:to_a) { is_expected.to eq [2, 'b'] }
        its(:'index.to_a') { is_expected.to eq [:a, :b] }
      end

      context "multiple positions" do
        subject { df.row.at 0, 2 }

        it { is_expected.to be_a Daru::DataFrame }
        its(:size) { is_expected.to eq 2 }
        its(:'index.to_a') { is_expected.to eq [[:a, :one, :bar],
          [:b, :two, :bar]] }
        its(:'a.to_a') { is_expected.to eq [1, 3] }
        its(:'a.index.to_a') { is_expected.to eq [[:a, :one, :bar],
          [:b, :two, :bar]] }
        its(:'b.to_a') { is_expected.to eq ['a', 'c'] }
      end

      context "invalid position" do
        it { expect { df.row.at 4 }.to raise_error IndexError }
      end

      context "invalid positions" do
        it { expect { df.row.at 3, 4 }.to raise_error IndexError }
      end

      context "range" do
        subject { df.row.at 0..1 }

        it { is_expected.to be_a Daru::DataFrame }
        its(:size) { is_expected.to eq 2 }
        its(:'index.to_a') { is_expected.to eq [[:a, :one, :bar],
          [:a, :one, :baz]] }
        its(:'a.to_a') { is_expected.to eq [1, 2] }
        its(:'a.index.to_a') { is_expected.to eq [[:a, :one, :bar],
          [:a, :one, :baz]] }
        its(:'b.to_a') { is_expected.to eq ['a', 'b'] }
      end

      context "range with negative end" do
        subject { df.row.at 0..-3 }

        it { is_expected.to be_a Daru::DataFrame }
        its(:size) { is_expected.to eq 2 }
        its(:'index.to_a') { is_expected.to eq [[:a, :one, :bar],
          [:a, :one, :baz]] }
        its(:'a.to_a') { is_expected.to eq [1, 2] }
        its(:'a.index.to_a') { is_expected.to eq [[:a, :one, :bar],
          [:a, :one, :baz]] }
        its(:'b.to_a') { is_expected.to eq ['a', 'b'] }
      end

      context " range with single element" do
        subject { df.row.at 0..0 }

        it { is_expected.to be_a Daru::DataFrame }
        its(:size) { is_expected.to eq 1 }
        its(:'index.to_a') { is_expected.to eq [[:a, :one, :bar]] }
        its(:'a.to_a') { is_expected.to eq [1] }
        its(:'a.index.to_a') { is_expected.to eq [[:a, :one, :bar]] }
        its(:'b.to_a') { is_expected.to eq ['a'] }
      end
    end

    context Daru::CategoricalIndex do
      let (:idx) { Daru::CategoricalIndex.new [:a, 1, 1, :a, :c] }
      let (:df)  do
        Daru::DataFrame.new({
          a: 1..5,
          b: 'a'..'e'
        }, index: idx )
      end

      context "single positional index" do
        subject { df.row.at 1 }

        it { is_expected.to be_a Daru::Vector }
        its(:size) { is_expected.to eq 2 }
        its(:to_a) { is_expected.to eq [2, 'b'] }
        its(:'index.to_a') { is_expected.to eq [:a, :b] }
      end

      context "multiple positional indexes" do
        subject { df.row.at 0, 2 }

        it { is_expected.to be_a Daru::DataFrame }
        its(:size) { is_expected.to eq 2 }
        its(:'index.to_a') { is_expected.to eq [:a, 1] }
        its(:'a.to_a') { is_expected.to eq [1, 3] }
        its(:'a.index.to_a') { is_expected.to eq [:a, 1] }
        its(:'b.to_a') { is_expected.to eq ['a', 'c'] }
        its(:'b.index.to_a') { is_expected.to eq [:a, 1] }
      end

      context "invalid position" do
        it { expect { df.at 5 }.to raise_error IndexError }
      end

      context "invalid positions" do
        it { expect { df.at 4, 5 }.to raise_error IndexError }
      end

      context "range" do
        subject { df.row.at 0..1 }

        it { is_expected.to be_a Daru::DataFrame }
        its(:size) { is_expected.to eq 2 }
        its(:'index.to_a') { is_expected.to eq [:a, 1] }
        its(:'a.to_a') { is_expected.to eq [1, 2] }
        its(:'a.index.to_a') { is_expected.to eq [:a, 1] }
        its(:'b.to_a') { is_expected.to eq ['a', 'b'] }
        its(:'b.index.to_a') { is_expected.to eq [:a, 1] }
      end

      context "range with negative end" do
        subject { df.row.at 0..-4 }

        it { is_expected.to be_a Daru::DataFrame }
        its(:size) { is_expected.to eq 2 }
        its(:'index.to_a') { is_expected.to eq [:a, 1] }
        its(:'a.to_a') { is_expected.to eq [1, 2] }
        its(:'a.index.to_a') { is_expected.to eq [:a, 1] }
        its(:'b.to_a') { is_expected.to eq ['a', 'b'] }
        its(:'b.index.to_a') { is_expected.to eq [:a, 1] }
      end

      context " range with single element" do
        subject { df.row.at 0..0 }

        it { is_expected.to be_a Daru::DataFrame }
        its(:size) { is_expected.to eq 1 }
        its(:'index.to_a') { is_expected.to eq [:a] }
        its(:'a.to_a') { is_expected.to eq [1] }
        its(:'a.index.to_a') { is_expected.to eq [:a] }
        its(:'b.to_a') { is_expected.to eq ['a'] }
        its(:'b.index.to_a') { is_expected.to eq [:a] }
      end
    end
  end

  context "#row.set_at" do
    let(:df) do
      Daru::DataFrame.new({
        a: 1..3,
        b: 'a'..'c'
      })
    end

    context "single position" do
      subject { df }
      before { df.row.set_at [1], ['x', 'y'] }

      its(:size) { is_expected.to eq 3 }
      its(:'a.to_a') { is_expected.to eq [1, 'x', 3] }
      its(:'b.to_a') { is_expected.to eq ['a', 'y', 'c'] }
    end

    context "multiple position" do
      subject { df }
      before { df.row.set_at [0, 2], ['x', 'y'] }

      its(:size) { is_expected.to eq 3 }
      its(:'a.to_a') { is_expected.to eq ['x', 2, 'x'] }
      its(:'b.to_a') { is_expected.to eq ['y', 'b', 'y'] }
    end

    context "invalid position" do
      it { expect { df.row.set_at [3], ['x', 'y'] }.to raise_error IndexError }
    end

    context "invalid positions" do
      it { expect { df.row.set_at [2, 3], ['x', 'y'] }.to raise_error IndexError }
    end

    context "incorrect size" do
      it { expect { df.row.set_at [1], ['x', 'y', 'z'] }.to raise_error SizeError }
    end
  end

  context "#at" do
    context Daru::Index do
      let(:idx) { Daru::Index.new [:a, :b, :c] }
      let(:df) do
        Daru::DataFrame.new({
          1 => 1..3,
          a: 'a'..'c',
          b: 11..13
        }, index: idx)
      end

      context "single position" do
        subject { df.at 1 }

        it { is_expected.to be_a Daru::Vector }
        its(:size) { is_expected.to eq 3 }
        its(:to_a) { is_expected.to eq ['a', 'b', 'c'] }
        its(:index) { is_expected.to eq idx }
      end

      context "multiple positions" do
        subject { df.at 0, 2 }

        it { is_expected.to be_a Daru::DataFrame }
        its(:shape) { is_expected.to eq [3, 2] }
        its(:index) { is_expected.to eq idx }
        it { expect(df[1].to_a).to eq [1, 2, 3] }
        its(:'b.to_a') { is_expected.to eq [11, 12, 13] }
      end

      context "single invalid position" do
        it { expect { df. at 3 }.to raise_error IndexError }
      end

      context "multiple invalid positions" do
        it { expect { df.at 2, 3 }.to raise_error IndexError }
      end

      context "range" do
        subject { df.at 0..1 }

        it { is_expected.to be_a Daru::DataFrame }
        its(:shape) { is_expected.to eq [3, 2] }
        its(:index) { is_expected.to eq idx }
        it { expect(df[1].to_a).to eq [1, 2, 3] }
        its(:'a.to_a') { is_expected.to eq ['a', 'b', 'c'] }
      end

      context "range with negative end" do
        subject { df.at 0..-2 }

        it { is_expected.to be_a Daru::DataFrame }
        its(:shape) { is_expected.to eq [3, 2] }
        its(:index) { is_expected.to eq idx }
        it { expect(df[1].to_a).to eq [1, 2, 3] }
        its(:'a.to_a') { is_expected.to eq ['a', 'b', 'c'] }
      end

      context "range with single element" do
        subject { df.at 1..1 }

        it { is_expected.to be_a Daru::DataFrame }
        its(:shape) { is_expected.to eq [3, 1] }
        its(:index) { is_expected.to eq idx }
        its(:'a.to_a') { is_expected.to eq ['a', 'b', 'c'] }
      end
    end

    context Daru::MultiIndex do
      let (:idx) do
        Daru::MultiIndex.from_tuples [
          [:a,:one,:bar],
          [:a,:one,:baz],
          [:b,:two,:bar],
        ]
      end
      let(:df) do
        Daru::DataFrame.new({
          1 => 1..3,
          a: 'a'..'c',
          b: 11..13
        }, index: idx)
      end

      context "single position" do
        subject { df.at 1 }

        it { is_expected.to be_a Daru::Vector }
        its(:size) { is_expected.to eq 3 }
        its(:to_a) { is_expected.to eq ['a', 'b', 'c'] }
        its(:index) { is_expected.to eq idx }
      end

      context "multiple positions" do
        subject { df.at 0, 2 }

        it { is_expected.to be_a Daru::DataFrame }
        its(:shape) { is_expected.to eq [3, 2] }
        its(:index) { is_expected.to eq idx }
        it { expect(df[1].to_a).to eq [1, 2, 3] }
        its(:'b.to_a') { is_expected.to eq [11, 12, 13] }
      end

      context "single invalid position" do
        it { expect { df. at 3 }.to raise_error IndexError }
      end

      context "multiple invalid positions" do
        it { expect { df.at 2, 3 }.to raise_error IndexError }
      end

      context "range" do
        subject { df.at 0..1 }

        it { is_expected.to be_a Daru::DataFrame }
        its(:shape) { is_expected.to eq [3, 2] }
        its(:index) { is_expected.to eq idx }
        it { expect(df[1].to_a).to eq [1, 2, 3] }
        its(:'a.to_a') { is_expected.to eq ['a', 'b', 'c'] }
      end

      context "range with negative end" do
        subject { df.at 0..-2 }

        it { is_expected.to be_a Daru::DataFrame }
        its(:shape) { is_expected.to eq [3, 2] }
        its(:index) { is_expected.to eq idx }
        it { expect(df[1].to_a).to eq [1, 2, 3] }
        its(:'a.to_a') { is_expected.to eq ['a', 'b', 'c'] }
      end

      context "range with single element" do
        subject { df.at 1..1 }

        it { is_expected.to be_a Daru::DataFrame }
        its(:shape) { is_expected.to eq [3, 1] }
        its(:index) { is_expected.to eq idx }
        its(:'a.to_a') { is_expected.to eq ['a', 'b', 'c'] }
      end
    end

    context Daru::CategoricalIndex do
      let (:idx) { Daru::CategoricalIndex.new [:a, 1, 1] }
      let(:df) do
        Daru::DataFrame.new({
          1 => 1..3,
          a: 'a'..'c',
          b: 11..13
        }, index: idx)
      end

      context "single position" do
        subject { df.at 1 }

        it { is_expected.to be_a Daru::Vector }
        its(:size) { is_expected.to eq 3 }
        its(:to_a) { is_expected.to eq ['a', 'b', 'c'] }
        its(:index) { is_expected.to eq idx }
      end

      context "multiple positions" do
        subject { df.at 0, 2 }

        it { is_expected.to be_a Daru::DataFrame }
        its(:shape) { is_expected.to eq [3, 2] }
        its(:index) { is_expected.to eq idx }
        it { expect(df[1].to_a).to eq [1, 2, 3] }
        its(:'b.to_a') { is_expected.to eq [11, 12, 13] }
      end

      context "single invalid position" do
        it { expect { df. at 3 }.to raise_error IndexError }
      end

      context "multiple invalid positions" do
        it { expect { df.at 2, 3 }.to raise_error IndexError }
      end

      context "range" do
        subject { df.at 0..1 }

        it { is_expected.to be_a Daru::DataFrame }
        its(:shape) { is_expected.to eq [3, 2] }
        its(:index) { is_expected.to eq idx }
        it { expect(df[1].to_a).to eq [1, 2, 3] }
        its(:'a.to_a') { is_expected.to eq ['a', 'b', 'c'] }
      end

      context "range with negative index" do
        subject { df.at 0..-2 }

        it { is_expected.to be_a Daru::DataFrame }
        its(:shape) { is_expected.to eq [3, 2] }
        its(:index) { is_expected.to eq idx }
        it { expect(df[1].to_a).to eq [1, 2, 3] }
        its(:'a.to_a') { is_expected.to eq ['a', 'b', 'c'] }
      end

      context "range with single element" do
        subject { df.at 1..1 }

        it { is_expected.to be_a Daru::DataFrame }
        its(:shape) { is_expected.to eq [3, 1] }
        its(:index) { is_expected.to eq idx }
        its(:'a.to_a') { is_expected.to eq ['a', 'b', 'c'] }
      end
    end
  end

  context "#set_at" do
    let(:df) do
      Daru::DataFrame.new({
        1 => 1..3,
        a: 'a'..'c',
        b: 11..13
      })
    end

    context "single position" do
      subject { df }
      before { df.set_at [1], ['x', 'y', 'z'] }

      its(:shape) { is_expected.to eq [3, 3] }
      it { expect(df[1].to_a).to eq [1, 2, 3] }
      its(:'a.to_a') { is_expected.to eq ['x', 'y', 'z'] }
      its(:'b.to_a') { is_expected.to eq [11, 12, 13] }
    end

    context "multiple position" do
      subject { df }
      before { df.set_at [1, 2], ['x', 'y', 'z'] }

      its(:shape) { is_expected.to eq [3, 3] }
      it { expect(df[1].to_a).to eq [1, 2, 3] }
      its(:'a.to_a') { is_expected.to eq ['x', 'y', 'z'] }
      its(:'b.to_a') { is_expected.to eq ['x', 'y', 'z'] }
    end

    context "invalid position" do
      it { expect { df.set_at [3], ['x', 'y', 'z'] }.to raise_error IndexError }
    end

    context "invalid positions" do
      it { expect { df.set_at [2, 3], ['x', 'y', 'z'] }.to raise_error IndexError }
    end

    context "incorrect size" do
      it { expect { df.set_at [1], ['x', 'y'] }.to raise_error SizeError }
    end
  end

  context "#row[]" do
    context Daru::Index do
      before :each do
        @df = Daru::DataFrame.new({b: [11,12,13,14,15], a: [1,2,3,4,5],
          c: [11,22,33,44,55]}, order: [:a, :b, :c],
          index: [:one, :two, :three, :four, :five])
      end

      it "creates an index for assignment if not already specified" do
        @df.row[:one] = [49, 99, 59]

        expect(@df[:one, :row])      .to eq([49, 99, 59].dv(:one, [:a, :b, :c]))
        expect(@df[:one, :row].index).to eq([:a, :b, :c].to_index)
        expect(@df[:one, :row].name) .to eq(:one)
      end

      it "returns a DataFrame when specifying numeric Range" do
        expect(@df.row[0..2]).to eq(
          Daru::DataFrame.new({b: [11,12,13], a: [1,2,3],
            c: [11,22,33]}, order: [:a, :b, :c],
            index: [:one, :two, :three])
          )
      end

      it "returns a DataFrame when specifying symbolic Range" do
        expect(@df.row[:one..:three]).to eq(
          Daru::DataFrame.new({b: [11,12,13], a: [1,2,3],
            c: [11,22,33]}, order: [:a, :b, :c],
            index: [:one, :two, :three])
          )
      end

      it "returns a row with the given index" do
        expect(@df.row[:one]).to eq([1,11,11].dv(:one, [:a, :b, :c]))
      end

      it "returns a row with given Integer index" do
        expect(@df.row[0]).to eq([1,11,11].dv(:one, [:a, :b, :c]))
      end

      it "returns a row with given Integer index for default index-less DataFrame" do
        df = Daru::DataFrame.new({b: [11,12,13,14,15], a: [1,2,3,4,5],
          c: [11,22,33,44,55]}, order: [:a, :b, :c])

        expect(df.row[0]).to eq([1,11,11].dv(nil, [:a, :b, :c]))
        expect(df.row[3]).to eq([4,14,44].dv(nil, [:a, :b, :c]))
      end

      it "returns a row with given Integer index for numerical index DataFrame" do
        df = Daru::DataFrame.new({b: [11,12,13,14,15], a: [1,2,3,4,5],
          c: [11,22,33,44,55]}, order: [:a, :b, :c], index: [1,2,3,4,5])

        expect(df.row[0]).to eq([1,11,11].dv(nil, [:a, :b, :c]))
        expect(df.row[3]).to eq([3,13,33].dv(nil, [:a, :b, :c]))
      end
    end

    context Daru::MultiIndex do
      it "returns a Vector when specifying integer index" do
        expect(@df_mi.row[0]).to eq(Daru::Vector.new([11,1,11,1], index: @order_mi))
      end

      it "returns a DataFrame whecn specifying numeric range" do
        sub_index = Daru::MultiIndex.from_tuples([
          [:a,:one,:bar],
          [:a,:one,:baz]
        ])

        expect(@df_mi.row[0..1]).to eq(Daru::DataFrame.new([
          [11,12],
          [1,2],
          [11,12],
          [1,2]
        ], order: @order_mi, index: sub_index, name: :numeric_range))
      end

      it "returns a Vector when specifying complete tuple" do
        expect(@df_mi.row[:c,:two,:foo]).to eq(Daru::Vector.new([13,3,13,3], index: @order_mi))
      end

      it "returns DataFrame when specifying first layer of MultiIndex" do
        sub_index = Daru::MultiIndex.from_tuples([
          [:one,:bar],
          [:one,:baz],
          [:two,:foo],
          [:two,:bar]
        ])
        expect(@df_mi.row[:c]).to eq(Daru::DataFrame.new([
          [11,12,13,14],
          [1,2,3,4],
          [11,12,13,14],
          [1,2,3,4]
          ], index: sub_index, order: @order_mi))
      end

      it "returns DataFrame when specifying first and second layer of MultiIndex" do
        sub_index = Daru::MultiIndex.from_tuples([
          [:bar],
          [:baz]
        ])
        expect(@df_mi.row[:c,:one]).to eq(Daru::DataFrame.new([
          [11,12],
          [1,2],
          [11,12],
          [1,2]
        ], index: sub_index, order: @order_mi))
      end
    end

    context Daru::CategoricalIndex do
      let(:idx) { Daru::CategoricalIndex.new [:a, 1, :a, 1, :c] }
      let(:df) do
        Daru::DataFrame.new({
          a: 'a'..'e',
          b: 1..5
        }, index: idx)
      end

      context "single category" do
        context "multiple instances" do
          subject { df.row[:a] }

          it { is_expected.to be_a Daru::DataFrame }
          its(:index) { is_expected.to eq Daru::CategoricalIndex.new [:a, :a] }
          its(:vectors) { is_expected.to eq Daru::Index.new [:a, :b] }
          its(:a) { Daru::Vector.new ['a', 'c'] }
          its(:b) { Daru::Vector.new [1, 3] }
        end

        context "single instance" do
          subject { df.row[:c] }

          it { is_expected.to be_a Daru::Vector }
          its(:index) { is_expected.to eq Daru::Index.new [:a, :b] }
          its(:to_a) { is_expected.to eq ['e', 5] }
        end
      end

      context "multiple categories" do
        subject { df.row[:a, 1] }

        it { is_expected.to be_a Daru::DataFrame }
        its(:index) { is_expected.to eq Daru::CategoricalIndex.new(
          [:a, 1, :a, 1 ]) }
        its(:vectors) { is_expected.to eq Daru::Index.new [:a, :b] }
        its(:a) { Daru::Vector.new ['a', 'c', 'b', 'd'] }
        its(:b) { Daru::Vector.new [1, 3, 2, 4] }
      end

      context "positional index" do
        subject { df.row[0] }

        it { is_expected.to be_a Daru::Vector }
        its(:index) { is_expected.to eq Daru::Index.new [:a, :b] }
        its(:to_a) { is_expected.to eq ['a', 1] }
      end

      context "invalid positional index" do
        it { expect { df.row[5] }.to raise_error IndexError }
      end

      context "invalid category" do
        it { expect { df.row[:d] }.to raise_error IndexError }
      end
    end
  end

  context "#add_row" do
    subject(:data_frame) {
      Daru::DataFrame.new({b: [11,12,13,14,15], a: [1,2,3,4,5],
        c: [11,22,33,44,55]}, order: [:a, :b, :c],
        index: [:one, :two, :three, :four, :five])
    }
    context 'named' do
      before {
        data_frame.add_row [100,200,300], :six
      }

      it { is_expected.to eq(Daru::DataFrame.new({
            a: [1,2,3,4,5,100],
            b: [11,12,13,14,15,200],
            c: [11,22,33,44,55,300]}, order: [:a, :b, :c],
            index: [:one, :two, :three, :four, :five, :six]))
      }
    end

    context 'unnamed' do
      before {
        data_frame.add_row [100,200,300]
      }

      it { is_expected.to eq(Daru::DataFrame.new({
            a: [1,2,3,4,5,100],
            b: [11,12,13,14,15,200],
            c: [11,22,33,44,55,300]}, order: [:a, :b, :c],
            index: [:one, :two, :three, :four, :five, 5]))
      }
    end

    context 'with mulitiindex DF' do
      subject(:data_frame) {
        Daru::DataFrame.new({b: [11,12,13], a: [1,2,3],
          c: [11,22,33]}, order: [:a, :b, :c],
          index: Daru::MultiIndex.from_tuples([[:one, :two], [:one, :three], [:two, :four]]))
      }

      before { data_frame.add_row [100,200,300], [:two, :five] }

      it { is_expected.to eq(Daru::DataFrame.new({
          b: [11,12,13,200], a: [1,2,3,100],
          c: [11,22,33,300]}, order: [:a, :b, :c],
          index: Daru::MultiIndex.from_tuples([[:one, :two], [:one, :three], [:two, :four], [:two, :five]])))
      }
    end

    it "allows adding rows after making empty DF by specfying only order" do
      df = Daru::DataFrame.new({}, order: [:a, :b, :c])
      df.add_row [1,2,3]
      df.add_row [5,6,7]

      expect(df[:a]).to eq(Daru::Vector.new([1,5]))
      expect(df[:b]).to eq(Daru::Vector.new([2,6]))
      expect(df[:c]).to eq(Daru::Vector.new([3,7]))
      expect(df.index).to eq(Daru::Index.new([0,1]))
    end
  end

  context "#first" do
    it 'works' do
      expect(@data_frame.first(2)).to eq(
        Daru::DataFrame.new({b: [11,12], a: [1,2], c: [11,22]},
        order: [:a, :b, :c],
        index: [:one, :two]))
    end

    it 'works with too large values' do
      expect(@data_frame.first(200)).to eq(@data_frame)
    end

    it 'has synonym' do
      expect(@data_frame.first(2)).to eq(@data_frame.head(2))
    end

    it 'works on DateTime indexes' do
      idx = Daru::DateTimeIndex.new(['2017-01-01', '2017-02-01', '2017-03-01'])
      df = Daru::DataFrame.new({col1: ['a', 'b', 'c']}, index: idx)
      first = Daru::DataFrame.new({col1: ['a']}, index: Daru::DateTimeIndex.new(['2017-01-01']))
      expect(df.head(1)).to eq(first)
    end
  end

  context "#last" do
    it 'works' do
      expect(@data_frame.last(2)).to eq(
        Daru::DataFrame.new({b: [14,15], a: [4,5], c: [44,55]},
        order: [:a, :b, :c],
        index: [:four, :five]))
    end

    it 'works with too large values' do
      expect(@data_frame.last(200)).to eq(@data_frame)
    end

    it 'has synonym' do
      expect(@data_frame.last(2)).to eq(@data_frame.tail(2))
    end
  end

  context "#==" do
    it "compares by vectors, index and values of a DataFrame (ignores name)" do
      a = Daru::DataFrame.new({b: [11,12,13,14,15], a: [1,2,3,4,5]},
        order: [:a, :b], index: [:one, :two, :three, :four, :five])

      b = Daru::DataFrame.new({b: [11,12,13,14,15], a: [1,2,3,4,5]},
        order: [:a, :b], index: [:one, :two, :three, :four, :five])

      expect(a).to eq(b)
    end
  end

  context '#rename' do
    subject { @data_frame.rename 'other' }

    it { is_expected.to be_a Daru::DataFrame }
    its(:name) { is_expected.to eq 'other' }
  end

  context "#dup" do
    context Daru::Index do
      it "dups every data structure inside DataFrame" do
        clo = @data_frame.dup

        expect(clo.object_id)        .not_to eq(@data_frame.object_id)
        expect(clo.vectors.object_id).not_to eq(@data_frame.vectors.object_id)
        expect(clo.index.object_id)  .not_to eq(@data_frame.index.object_id)

        @data_frame.each_vector_with_index do |vector, index|
          expect(vector.object_id).not_to eq(clo[index].object_id)
          expect(vector.to_a.object_id).not_to eq(clo[index].to_a.object_id)
        end
      end
    end

    context Daru::MultiIndex do
      it "duplicates with multi index" do
        clo = @df_mi.dup

        expect(clo)                  .to     eq(@df_mi)
        expect(clo.vectors.object_id).not_to eq(@df_mi.vectors.object_id)
        expect(clo.index.object_id)  .not_to eq(@df_mi.index.object_id)
      end
    end
  end

  context '#reject_values' do
    let(:df) do
      Daru::DataFrame.new({
        a: [1,    2,          3,   nil,        Float::NAN, nil, 1,   7],
        b: [:a,  :b,          nil, Float::NAN, nil,        3,   5,   8],
        c: ['a',  Float::NAN, 3,   4,          3,          5,   nil, 7]
      }, index: 11..18)
    end
    before { df.to_category :b }

    context 'remove nils only' do
      subject { df.reject_values nil }
      it { is_expected.to be_a Daru::DataFrame }
      its(:'b.type') { is_expected.to eq :category }
      its(:'a.to_a') { is_expected.to eq [1, 2, 7] }
      its(:'b.to_a') { is_expected.to eq [:a, :b, 8] }
      its(:'c.to_a') { is_expected.to eq ['a', Float::NAN, 7] }
      its(:'index.to_a') { is_expected.to eq [11, 12, 18] }
    end

    context 'remove Float::NAN only' do
      subject { df.reject_values Float::NAN }
      it { is_expected.to be_a Daru::DataFrame }
      its(:'b.type') { is_expected.to eq :category }
      its(:'a.to_a') { is_expected.to eq [1, 3, nil, 1, 7] }
      its(:'b.to_a') { is_expected.to eq [:a, nil, 3, 5, 8] }
      its(:'c.to_a') { is_expected.to eq ['a', 3, 5, nil, 7] }
      its(:'index.to_a') { is_expected.to eq [11, 13, 16, 17, 18] }
    end

    context 'remove both nil and Float::NAN' do
      subject { df.reject_values nil, Float::NAN }
      it { is_expected.to be_a Daru::DataFrame }
      its(:'b.type') { is_expected.to eq :category }
      its(:'a.to_a') { is_expected.to eq [1, 7] }
      its(:'b.to_a') { is_expected.to eq [:a, 8] }
      its(:'c.to_a') { is_expected.to eq ['a', 7] }
      its(:'index.to_a') { is_expected.to eq [11, 18] }
    end

    context 'any other values' do
      subject { df.reject_values 1, 5 }
      it { is_expected.to be_a Daru::DataFrame }
      its(:'b.type') { is_expected.to eq :category }
      its(:'a.to_a') { is_expected.to eq [2, 3, nil, Float::NAN, 7] }
      its(:'b.to_a') { is_expected.to eq [:b, nil, Float::NAN, nil, 8] }
      its(:'c.to_a') { is_expected.to eq [Float::NAN, 3, 4, 3, 7] }
      its(:'index.to_a') { is_expected.to eq [12, 13, 14, 15, 18] }
    end

    context 'when resultant dataframe has one row' do
      subject { df.reject_values 1, 2, 3, 4, 5, nil, Float::NAN }
      it { is_expected.to be_a Daru::DataFrame }
      its(:'b.type') { is_expected.to eq :category }
      its(:'a.to_a') { is_expected.to eq [7] }
      its(:'b.to_a') { is_expected.to eq [8] }
      its(:'c.to_a') { is_expected.to eq [7] }
      its(:'index.to_a') { is_expected.to eq [18] }
    end

    context 'when resultant dataframe is empty' do
      subject { df.reject_values 1, 2, 3, 4, 5, 6, 7, nil, Float::NAN }
      it { is_expected.to be_a Daru::DataFrame }
      its(:'b.type') { is_expected.to eq :category }
      its(:'a.to_a') { is_expected.to eq [] }
      its(:'b.to_a') { is_expected.to eq [] }
      its(:'c.to_a') { is_expected.to eq [] }
      its(:'index.to_a') { is_expected.to eq [] }
    end
  end

  context '#replace_values' do
    subject do
      Daru::DataFrame.new({
        a: [1,    2,          3,   nil,        Float::NAN, nil, 1,   7],
        b: [:a,  :b,          nil, Float::NAN, nil,        3,   5,   8],
        c: ['a',  Float::NAN, 3,   4,          3,          5,   nil, 7]
      })
    end
    before { subject.to_category :b }

    context 'replace nils only' do
      before { subject.replace_values nil, 10 }
      it { is_expected.to be_a Daru::DataFrame }
      its(:'b.type') { is_expected.to eq :category }
      its(:'a.to_a') { is_expected.to eq [1, 2, 3, 10, Float::NAN, 10, 1, 7] }
      its(:'b.to_a') { is_expected.to eq [:a,  :b, 10, Float::NAN, 10, 3, 5, 8] }
      its(:'c.to_a') { is_expected.to eq ['a', Float::NAN, 3, 4, 3, 5, 10, 7] }
    end

    context 'replace Float::NAN only' do
      before { subject.replace_values Float::NAN, 10 }
      it { is_expected.to be_a Daru::DataFrame }
      its(:'b.type') { is_expected.to eq :category }
      its(:'a.to_a') { is_expected.to eq [1, 2, 3, nil, 10, nil, 1, 7] }
      its(:'b.to_a') { is_expected.to eq [:a,  :b, nil, 10, nil, 3, 5, 8] }
      its(:'c.to_a') { is_expected.to eq ['a', 10, 3, 4, 3, 5, nil, 7] }
    end

    context 'replace both nil and Float::NAN' do
      before { subject.replace_values [nil, Float::NAN], 10 }
      it { is_expected.to be_a Daru::DataFrame }
      its(:'b.type') { is_expected.to eq :category }
      its(:'a.to_a') { is_expected.to eq [1, 2, 3, 10, 10, 10, 1, 7] }
      its(:'b.to_a') { is_expected.to eq [:a,  :b, 10, 10, 10, 3, 5, 8] }
      its(:'c.to_a') { is_expected.to eq ['a', 10, 3, 4, 3, 5, 10, 7] }
    end

    context 'replace other values' do
      before { subject.replace_values [1, 5], 10 }
      it { is_expected.to be_a Daru::DataFrame }
      its(:'b.type') { is_expected.to eq :category }
      its(:'a.to_a') { is_expected.to eq [10, 2, 3, nil, Float::NAN, nil, 10, 7] }
      its(:'b.to_a') { is_expected.to eq [:a,  :b, nil, Float::NAN, nil, 3, 10, 8] }
      its(:'c.to_a') { is_expected.to eq ['a', Float::NAN, 3, 4, 3, 10, nil, 7] }
    end
  end

  describe 'uniq' do
    let(:df) do
      Daru::DataFrame.from_csv 'spec/fixtures/duplicates.csv'
    end

    context 'with no args' do
      it do
        result = df.uniq
        expect(result.shape.first).to eq 30
      end
    end

    context 'given a vector' do
      it do
        result = df.uniq("color")
        expect(result.shape.first).to eq 2
      end
    end

    context 'given an array of vectors' do
      it do
        result = df.uniq("color", "director_name")
        expect(result.shape.first).to eq 29
      end
    end
  end

  context '#rolling_fillna!' do
    subject do
      Daru::DataFrame.new({
        a: [1,    2,          3,   nil,        Float::NAN, nil, 1,   7],
        b: [:a,  :b,          nil, Float::NAN, nil,        3,   5,   nil],
        c: ['a',  Float::NAN, 3,   4,          3,          5,   nil, 7]
      })
    end

    context 'rolling_fillna! forwards' do
      before { subject.rolling_fillna!(:forward) }
      it { expect(subject.rolling_fillna!(:forward)).to eq(subject) }
      its(:'a.to_a') { is_expected.to eq [1, 2, 3, 3, 3, 3, 1, 7] }
      its(:'b.to_a') { is_expected.to eq [:a,  :b, :b, :b, :b, 3, 5, 5] }
      its(:'c.to_a') { is_expected.to eq ['a', 'a', 3, 4, 3, 5, 5, 7] }
    end

    context 'rolling_fillna! backwards' do
      before { subject.rolling_fillna!(:backward) }
      it { expect(subject.rolling_fillna!(:backward)).to eq(subject) }
      its(:'a.to_a') { is_expected.to eq [1, 2, 3, 1, 1, 1, 1, 7] }
      its(:'b.to_a') { is_expected.to eq [:a, :b, 3, 3, 3, 3, 5, 0] }
      its(:'c.to_a') { is_expected.to eq ['a', 3, 3, 4, 3, 5, 7, 7] }
    end
  end

  context "#clone" do
    it "returns a view of the whole dataframe" do
      cloned = @data_frame.clone
      expect(@data_frame.object_id).to_not eq(cloned.object_id)
      expect(@data_frame[:a].object_id).to eq(cloned[:a].object_id)
      expect(@data_frame[:b].object_id).to eq(cloned[:b].object_id)
      expect(@data_frame[:c].object_id).to eq(cloned[:c].object_id)
    end

    it "returns a view of selected vectors" do
      cloned = @data_frame.clone(:a, :b)
      expect(cloned.object_id).to_not eq(@data_frame.object_id)
      expect(cloned[:a].object_id).to eq(@data_frame[:a].object_id)
      expect(cloned[:b].object_id).to eq(@data_frame[:b].object_id)
    end

    it "clones properly when supplied array" do
      cloned = @data_frame.clone([:a, :b])
      expect(cloned.object_id).to_not eq(@data_frame.object_id)
      expect(cloned[:a].object_id).to eq(@data_frame[:a].object_id)
      expect(cloned[:b].object_id).to eq(@data_frame[:b].object_id)
    end

    it "original dataframe remains unaffected when operations are applied
      on cloned data frame" do
      original = @data_frame.dup
      cloned = @data_frame.clone
      cloned.delete_vector :a

      expect(@data_frame).to eq(original)
    end

  end

  context "#clone_only_valid" do
    let(:df_with_missing) {
      Daru::DataFrame.new({
        a: [1  , 2, 3, nil, 4, nil, 5],
        b: [nil, 2, 3, nil, 4, nil, 5],
        c: [1,   2, 3, 43 , 4, nil, 5]
      })
    }

    let(:df_without_missing) {
      Daru::DataFrame.new({
        a: [2,3,4,5],
        c: [2,3,4,5]
      })
    }
    it 'does the most reasonable thing' do
      expect(df_with_missing.clone_only_valid).to eq(df_with_missing.reject_values(*Daru::MISSING_VALUES))
      expect(df_without_missing.clone_only_valid).to eq(df_without_missing.clone)
    end
  end

  context "#clone_structure" do
    it "clones only the index and vector structures of the data frame" do
      cs = @data_frame.clone_structure

      expect(cs.vectors).to eq(@data_frame.vectors)
      expect(cs.index).to eq(@data_frame.index)
      expect(cs[:a]).to eq(Daru::Vector.new([nil] * cs[:a].size, index: @data_frame.index))
    end
  end

  context "#each_index" do
    it "iterates over index" do
      idxs = []
      ret = @data_frame.each_index do |index|
        idxs << index
      end

      expect(idxs).to eq([:one, :two, :three, :four, :five])

      expect(ret).to eq(@data_frame)
    end
  end

  context "#each_vector_with_index" do
    it "iterates over vectors with index" do
      idxs = []
      ret = @data_frame.each_vector_with_index do |vector, index|
        idxs << index
        expect(vector.index).to eq([:one, :two, :three, :four, :five].to_index)
        expect(vector.class).to eq(Daru::Vector)
      end

      expect(idxs).to eq([:a, :b, :c])

      expect(ret).to eq(@data_frame)
    end
  end

  context "#each_row_with_index" do
    it "iterates over rows with indexes" do
      idxs = []
      ret = @data_frame.each_row_with_index do |row, idx|
        idxs << idx
        expect(row.index).to eq([:a, :b, :c].to_index)
        expect(row.class).to eq(Daru::Vector)
      end

      expect(idxs).to eq([:one, :two, :three, :four, :five])
      expect(ret) .to eq(@data_frame)
    end
  end

  context "#each" do
    it "iterates over rows" do
      ret = @data_frame.each(:row) do |row|
        expect(row.index).to eq([:a, :b, :c].to_index)
        expect(row.class).to eq(Daru::Vector)
      end

      expect(ret).to eq(@data_frame)
    end

    it "iterates over all vectors" do
      ret = @data_frame.each do |vector|
        expect(vector.index).to eq([:one, :two, :three, :four, :five].to_index)
        expect(vector.class).to eq(Daru::Vector)
      end

      expect(ret).to eq(@data_frame)
    end

    it "returns Enumerable if no block specified" do
      ret = @data_frame.each
      expect(ret.is_a?(Enumerator)).to eq(true)
    end

    it "raises on unknown axis" do
      expect { @data_frame.each(:kitten) }.to raise_error(ArgumentError, /axis/)
    end
  end

  context "#recode" do
    before do
      @ans_vector = Daru::DataFrame.new({b: [21,22,23,24,25], a: [11,12,13,14,15],
        c: [21,32,43,54,65]}, order: [:a, :b, :c],
        index: [:one, :two, :three, :four, :five])

      @ans_rows = Daru::DataFrame.new({b: [121, 144, 169, 196, 225], a: [1,4,9,16,25],
        c: [121, 484, 1089, 1936, 3025]}, order: [:a, :b, :c],
        index: [:one, :two, :three, :four, :five])

      @data_frame_date_time = @data_frame.dup
      @data_frame_date_time.index = Daru::DateTimeIndex.date_range(start:"2016-02-11", periods:5)

      @ans_vector_date_time = Daru::DataFrame.new({b: [21,22,23,24,25], a: [11,12,13,14,15],
        c: [21,32,43,54,65]}, order: [:a, :b, :c],
        index: Daru::DateTimeIndex.date_range(start:"2016-02-11", periods:5))

      @ans_rows_date_time = Daru::DataFrame.new({b: [121, 144, 169, 196, 225], a: [1,4,9,16,25],
        c: [121, 484, 1089, 1936, 3025]}, order: [:a, :b, :c],
        index: Daru::DateTimeIndex.date_range(start:"2016-02-11", periods:5))
    end

    it "maps over the vectors of a DataFrame and returns a DataFrame" do
      ret = @data_frame.recode do |vector|
        vector.map! { |e| e += 10}
      end

      expect(ret).to eq(@ans_vector)
    end

    it "maps over the rows of a DataFrame and returns a DataFrame" do
      ret = @data_frame.recode(:row) do |row|
        expect(row.class).to eq(Daru::Vector)
        row.map! { |e| e*e }
      end

      expect(ret).to eq(@ans_rows)
    end

    it "maps over the vectors of a DataFrame with DateTimeIndex and returns a DataFrame with DateTimeIndex" do
      ret = @data_frame_date_time.recode do |vector|
        vector.map! { |e| e += 10}
      end

      expect(ret).to eq(@ans_vector_date_time)
    end

    it "maps over the rows of a DataFrame with DateTimeIndex and returns a DataFrame with DateTimeIndex" do
      ret = @data_frame_date_time.recode(:row) do |row|
        expect(row.class).to eq(Daru::Vector)
        row.map! { |e| e*e }
      end

      expect(ret).to eq(@ans_rows_date_time)
    end

  end

  context "#collect" do
    before do
      @df = Daru::DataFrame.new({
        a: [1,2,3,4,5],
        b: [11,22,33,44,55],
        c: [1,2,3,4,5]
      })
    end

    it "collects calculation over rows and returns a Vector from the results" do
      expect(@df.collect(:row) { |row| (row[:a] + row[:c]) * row[:c] }).to eq(
        Daru::Vector.new([2,8,18,32,50])
        )
    end

    it "collects calculation over vectors and returns a Vector from the results" do
      expect(@df.collect { |v| v[0] * v[1] + v[4] }).to eq(
        Daru::Vector.new([7,297,7], index: [:a, :b, :c])
        )
    end
  end

  context "#map" do
    it "iterates over rows and returns an Array" do
      ret = @data_frame.map(:row) do |row|
        expect(row.class).to eq(Daru::Vector)
        row[:a] * row[:c]
      end

      expect(ret).to eq([11, 44, 99, 176, 275])
      expect(@data_frame.vectors.to_a).to eq([:a, :b, :c])
    end

    it "iterates over vectors and returns an Array" do
      ret = @data_frame.map do |vector|
        vector.mean
      end
      expect(ret).to eq([3.0, 13.0, 33.0])
    end
  end

  context "#map!" do
    before do
      @ans_vector = Daru::DataFrame.new({b: [21,22,23,24,25], a: [11,12,13,14,15],
        c: [21,32,43,54,65]}, order: [:a, :b, :c],
        index: [:one, :two, :three, :four, :five])

      @ans_row = Daru::DataFrame.new({b: [12,13,14,15,16], a: [2,3,4,5,6],
        c: [12,23,34,45,56]}, order: [:a, :b, :c],
        index: [:one, :two, :three, :four, :five])
    end

    it "destructively maps over the vectors and changes the DF" do
      @data_frame.map! do |vector|
        vector + 10
      end
      expect(@data_frame).to eq(@ans_vector)
    end

    it "destructively maps over the rows and changes the DF" do
      @data_frame.map!(:row) do |row|
        row + 1
      end

      expect(@data_frame).to eq(@ans_row)
    end
  end

  context "#map_vectors_with_index" do
    it "iterates over vectors with index and returns an Array" do
      idx = []
      ret = @data_frame.map_vectors_with_index do |vector, index|
        idx << index
        vector.recode { |e| e += 10}
      end

      expect(ret).to eq([
        Daru::Vector.new([11,12,13,14,15],index: [:one, :two, :three, :four, :five]),
        Daru::Vector.new([21,22,23,24,25],index: [:one, :two, :three, :four, :five]),
        Daru::Vector.new([21,32,43,54,65],index: [:one, :two, :three, :four, :five])])
      expect(idx).to eq([:a, :b, :c])
    end
  end

  # FIXME: collect_VECTORS_with_index, but map_VECTOR_with_index -- ??? -- zverok
  # (Not saying about unfortunate difference between them...)
  context "#collect_vector_with_index" do
    it "iterates over vectors with index and returns an Array" do
      idx = []
      ret = @data_frame.collect_vector_with_index do |vector, index|
        idx << index
        vector.sum
      end

      expect(ret).to eq(Daru::Vector.new([15, 65, 165], index: [:a, :b, :c]))
      expect(idx).to eq([:a, :b, :c])
    end
  end

  context "#map_rows_with_index" do
    it "iterates over rows with index and returns an Array" do
      idx = []
      ret = @data_frame.map_rows_with_index do |row, index|
        idx << index
        expect(row.class).to eq(Daru::Vector)
        row[:a] * row[:c]
      end

      expect(ret).to eq([11, 44, 99, 176, 275])
      expect(idx).to eq([:one, :two, :three, :four, :five])
    end
  end

  context '#collect_row_with_index' do
    it "iterates over rows with index and returns a Vector" do
      idx = []
      ret = @data_frame.collect_row_with_index do |row, index|
        idx << index
        expect(row.class).to eq(Daru::Vector)
        row[:a] * row[:c]
      end

      expected = Daru::Vector.new([11, 44, 99, 176, 275], index: @data_frame.index)
      expect(ret).to eq(expected)
      expect(idx).to eq([:one, :two, :three, :four, :five])
    end
  end

  context "#delete_vector" do
    context Daru::Index do
      it "deletes the specified vector" do
        @data_frame.delete_vector :a

        expect(@data_frame).to eq(Daru::DataFrame.new({b: [11,12,13,14,15],
                c: [11,22,33,44,55]}, order: [:b, :c],
                index: [:one, :two, :three, :four, :five]))
      end
    end
  end

  context "#delete_vectors" do
    context Daru::Index do
      it "deletes the specified vectors" do
        @data_frame.delete_vectors :a, :b

        expect(@data_frame).to eq(Daru::DataFrame.new({
                c: [11,22,33,44,55]}, order: [:c],
                index: [:one, :two, :three, :four, :five]))
      end
    end
  end

  context "#delete_row" do
    it "deletes the specified row" do
      @data_frame.delete_row :three

      expect(@data_frame).to eq(Daru::DataFrame.new({b: [11,12,14,15], a: [1,2,4,5],
      c: [11,22,44,55]}, order: [:a, :b, :c], index: [:one, :two, :four, :five]))
    end
  end

  context "#keep_row_if" do
    pending "changing row from under the iterator trips this"
    it "keeps row if block evaluates to true" do
      df = Daru::DataFrame.new({b: [10,12,20,23,30], a: [50,30,30,1,5],
        c: [10,20,30,40,50]}, order: [:a, :b, :c],
        index: [:one, :two, :three, :four, :five])

      df.keep_row_if do |row|
        row[:a] % 10 == 0
      end
      # TODO: write expectation
    end
  end

  context "#keep_vector_if" do
    it "keeps vector if block evaluates to true" do
      @data_frame.keep_vector_if do |vector|
        vector == [1,2,3,4,5].dv(nil, [:one, :two, :three, :four, :five])
      end

      expect(@data_frame).to eq(Daru::DataFrame.new({a: [1,2,3,4,5]}, order: [:a],
        index: [:one, :two, :three, :four, :five]))
    end
  end

  context "#filter_field" do
    before do
      @df = Daru::DataFrame.new({
        :id => Daru::Vector.new([1, 2, 3, 4, 5]),
        :name => Daru::Vector.new(%w(Alex Claude Peter Franz George)),
        :age => Daru::Vector.new([20, 23, 25, 27, 5]),
        :city => Daru::Vector.new(['New York', 'London', 'London', 'Paris', 'Tome']),
        :a1 => Daru::Vector.new(['a,b', 'b,c', 'a', nil, 'a,b,c']) },
        order: [:id, :name, :age, :city, :a1])
    end

    it "creates new vector with the data of a given field for which block returns true" do
      filtered = @df.filter_vector(:id) { |c| c[:id] == 2 or c[:id] == 4 }
      expect(filtered).to eq(Daru::Vector.new([2,4]))
    end
  end

  context "#filter_rows" do
    context Daru::Index do
      context "when specified no index" do
        it "filters rows" do
          df = Daru::DataFrame.new({a: [1,2,3], b: [2,3,4]})

          a = df.filter_rows do |row|
            row[:a] % 2 == 0
          end

          expect(a).to eq(Daru::DataFrame.new({a: [2], b: [3]}, order: [:a, :b], index: [1]))
        end
      end

      context "when specified numerical index" do
        it "filters rows" do
          df = Daru::DataFrame.new({a: [1,2,3], b: [2,3,4]}, index: [1,2,3])

          a = df.filter_rows do |row|
            row[:a] % 2 == 0
          end

          expect(a).to eq(Daru::DataFrame.new({a: [2], b: [3]}, order: [:a, :b], index: [2]))
        end
      end

      it "preserves names of vectors" do
        df = Daru::DataFrame.new a: 1..3, b: 4..6
        df1 = df.filter_rows { |r| r[:a] != 2 }

        expect(df1[:a].name).to eq(df[:a].name)
      end
    end
  end

  context "#filter_vectors" do
    context Daru::Index do
      it "filters vectors" do
        df = Daru::DataFrame.new({a: [1,2,3], b: [2,3,4]})

        a = df.filter_vectors do |vector|
          vector[0] == 1
        end

        expect(a).to eq(Daru::DataFrame.new({a: [1,2,3]}))
      end
    end
  end

  context "#filter" do
    let(:df) { Daru::DataFrame.new({a: [1,2,3], b: [2,3,4]}) }
    it "dispatches" do
      expect(df.filter(:row){|r| r[:a] % 2 == 0 }).to \
        eq df.filter_rows{|r| r[:a] % 2 == 0 }

      expect(df.filter(:vector){|v| v[0] == 1}).to \
        eq df.filter_vectors{|v| v[0] == 1}

      expect { df.filter(:kitten){} }.to raise_error ArgumentError, /axis/
    end
  end

  context "#to_a" do
    context Daru::Index do
      it "converts DataFrame into array of hashes" do
        arry = @data_frame.to_a

        expect(arry).to eq(
          [
            [
              {a: 1, b: 11, c: 11},
              {a: 2, b: 12, c: 22},
              {a: 3, b: 13, c: 33},
              {a: 4, b: 14, c: 44},
              {a: 5, b: 15, c: 55}
            ],
            [
              :one, :two, :three, :four, :five
            ]
          ])
      end
    end

    context Daru::MultiIndex do
      pending
    end
  end

  context "#to_h" do
    it "converts to a hash" do
      expect(@data_frame.to_h).to eq(
        {
          a: Daru::Vector.new([1,2,3,4,5],
            index: [:one, :two, :three, :four, :five]),
          b: Daru::Vector.new([11,12,13,14,15],
            index: [:one, :two, :three, :four, :five]),
          c: Daru::Vector.new([11,22,33,44,55],
            index: [:one, :two, :three, :four, :five])
        }
      )
    end
  end

  context "#recast" do
    it "recasts underlying vectors" do
      @data_frame.recast a: :nmatrix, c: :nmatrix

      expect(@data_frame.a.dtype).to eq(:nmatrix)
      expect(@data_frame.b.dtype).to eq(:array)
      expect(@data_frame.c.dtype).to eq(:nmatrix)
    end
  end

  context "#sort" do
    context Daru::Index do
      before :each do
        @df = Daru::DataFrame.new({a: [5,1,-6,7,5,5], b: [-2,-1,5,3,9,1], c: ['a','aa','aaa','aaaa','aaaaa','aaaaaa']})
      end

      it "sorts according to given vector order (bang)" do
        a_sorter = lambda { |a| a }
        ans = @df.sort([:a], by: { a: a_sorter })

        expect(ans).to eq(
          Daru::DataFrame.new({a: [-6,1,5,5,5,7], b: [5,-1,-2,9,1,3], c: ['aaa','aa','a','aaaaa','aaaaaa','aaaa']},
            index: [2,1,0,4,5,3])
          )
        expect(ans).to_not eq(@df)
      end

      it "sorts according to vector order using default lambdas (index re ordered according to the last vector) (bang)" do
        ans = @df.sort([:a, :b])
        expect(ans).to eq(
          Daru::DataFrame.new({a: [-6,1,5,5,5,7], b: [5,-1,-2,1,9,3], c: ['aaa','aa','a','aaaaaa','aaaaa','aaaa']},
            index: [2,1,0,5,4,3])
          )
        expect(ans).to_not eq(@df)
      end
    end

    context Daru::MultiIndex do
      pending
    end

    context Daru::CategoricalIndex do
      let(:idx) { Daru::CategoricalIndex.new [:a, 1, :a, 1, :c] }
      let(:df) do
        Daru::DataFrame.new({
          a: [2, -1, 3, 4, 5],
          b: ['x', 'y', 'x', 'a', 'y'],
          c: [nil, nil, -2, 2, 1]
        }, index: idx)
      end

      context "ascending order" do
        context "single vector" do
          subject { df.sort [:a] }

          its(:'index.to_a') { is_expected.to eq [1, :a, :a, 1, :c] }
          its(:'a.to_a') { is_expected.to eq [-1, 2, 3, 4, 5] }
          its(:'b.to_a') { is_expected.to eq ['y', 'x', 'x', 'a', 'y'] }
          its(:'c.to_a') { is_expected.to eq [nil, nil, -2, 2, 1] }
        end

        context "multiple vectors" do
          subject { df.sort [:c, :b] }

          its(:'index.to_a') { is_expected.to eq [:a, 1, :a, :c, 1] }
          its(:'a.to_a') { is_expected.to eq [2, -1, 3, 5, 4] }
          its(:'b.to_a') { is_expected.to eq ['x', 'y', 'x', 'y', 'a'] }
          its(:'c.to_a') { is_expected.to eq [nil, nil, -2, 1, 2] }
        end

        context "block" do
          context "automatic handle nils" do
            subject do
              df.sort [:c], by: {c: lambda { |a| a.abs } }, handle_nils: true
            end

            its(:'index.to_a') { is_expected.to eq [:a, 1, :c, :a, 1] }
            its(:'a.to_a') { is_expected.to eq [2, -1, 5, 3, 4] }
            its(:'b.to_a') { is_expected.to eq ['x', 'y', 'y', 'x', 'a'] }
            its(:'c.to_a') { is_expected.to eq [nil, nil, 1, -2, 2] }
          end

          context "manually handle nils" do
            subject do
              df.sort [:c], by: {c: lambda { |a| (a.nil?)?[1]:[0,a.abs] } }
            end

            its(:'index.to_a') { is_expected.to eq [:c, :a, 1, :a, 1] }
            its(:'a.to_a') { is_expected.to eq [5, 3, 4, 2, -1] }
            its(:'b.to_a') { is_expected.to eq ['y', 'x', 'a', 'x', 'y'] }
            its(:'c.to_a') { is_expected.to eq [1, -2, 2, nil, nil] }
          end
        end
      end

      context "descending order" do
        context "single vector" do
          subject { df.sort [:a], ascending: false }

          its(:'index.to_a') { is_expected.to eq [:c, 1, :a, :a, 1] }
          its(:'a.to_a') { is_expected.to eq [5, 4, 3, 2, -1] }
          its(:'b.to_a') { is_expected.to eq ['y', 'a', 'x', 'x', 'y'] }
          its(:'c.to_a') { is_expected.to eq [1, 2, -2, nil, nil] }
        end

        context "multiple vectors" do
          subject { df.sort [:c, :b], ascending: false }

          its(:'index.to_a') { is_expected.to eq [1, :a, 1, :c, :a] }
          its(:'a.to_a') { is_expected.to eq [-1, 2, 4, 5, 3] }
          its(:'b.to_a') { is_expected.to eq ['y', 'x', 'a', 'y', 'x'] }
          its(:'c.to_a') { is_expected.to eq [nil, nil, 2, 1, -2] }
        end

        context "block" do
          context "automatic handle nils" do
            subject do
              df.sort [:c],
                by: {c: lambda { |a| a.abs } },
                handle_nils: true,
                ascending: false
            end

            its(:'index.to_a') { is_expected.to eq [:a, 1, :a, 1, :c] }
            its(:'a.to_a') { is_expected.to eq [2, -1, 3, 4, 5] }
            its(:'b.to_a') { is_expected.to eq ['x', 'y', 'x', 'a', 'y'] }
            its(:'c.to_a') { is_expected.to eq [nil, nil, -2, 2, 1] }
          end

          context "manually handle nils" do
            subject do
              df.sort [:c],
                by: {c: lambda { |a| (a.nil?)?[1]:[0,a.abs] } },
                ascending: false
            end

            its(:'index.to_a') { is_expected.to eq [:a, 1, :a, 1, :c] }
            its(:'a.to_a') { is_expected.to eq [2, -1, 3, 4, 5] }
            its(:'b.to_a') { is_expected.to eq ['x', 'y', 'x', 'a', 'y'] }
            its(:'c.to_a') { is_expected.to eq [nil, nil, -2, 2, 1] }
          end
        end
      end
    end
  end

  context "#sort!" do
    context Daru::Index do
      before :each do
        @df = Daru::DataFrame.new({a: [5,1,-6,7,5,5], b: [-2,-1,5,3,9,1],
          c: ['a','aa','aaa','aaaa','aaaaa','aaaaaa']})
      end

      it "sorts according to given vector order (bang)" do
        a_sorter = lambda { |a| a }

        expect(@df.sort!([:a], by: { a: a_sorter })).to eq(
          Daru::DataFrame.new({a: [-6,1,5,5,5,7], b: [5,-1,-2,9,1,3],
            c: ['aaa','aa','a','aaaaa','aaaaaa','aaaa']}, index: [2,1,0,4,5,3])
          )
      end

      it "sorts according to vector order using default lambdas (index re ordered according to the last vector) (bang)" do
        expect(@df.sort!([:a, :b])).to eq(
          Daru::DataFrame.new({a: [-6,1,5,5,5,7], b: [5,-1,-2,1,9,3], c: ['aaa','aa','a','aaaaaa','aaaaa','aaaa']},
            index: [2,1,0,5,4,3])
          )
      end

      it "sorts both vectors in descending order" do
        expect(@df.sort!([:a,:b], ascending: [false, false])).to eq(
          Daru::DataFrame.new({a: [7,5,5,5,1,-6], b: [3,9,1,-2,-1,5], c: ['aaaa','aaaaa','aaaaaa', 'a','aa', 'aaa'] },
            index: [3,4,5,0,1,2])
          )
      end

      it "sorts one vector in desc and other is asc" do
        expect(@df.sort!([:a, :b], ascending: [false, true])).to eq(
          Daru::DataFrame.new({a: [7,5,5,5,1,-6], b: [3,-2,1,9,-1,5], c: ['aaaa','a','aaaaaa','aaaaa','aa','aaa']},
            index: [3,0,5,4,1,2])
          )
      end

      it "sorts many vectors" do
        d = Daru::DataFrame.new({a: [1,1,1,222,44,5,5,544], b: [44,44,333,222,111,554,22,3], c: [3,2,5,3,3,1,5,5]})

        expect(d.sort!([:a, :b, :c], ascending: [false, true, false])).to eq(
          Daru::DataFrame.new({a: [544,222,44,5,5,1,1,1], b: [3,222,111,22,554,44,44,333], c: [5,3,3,5,1,3,2,5]},
            index: [7,3,4,6,5,0,1,2])
          )
      end

      it "places nils at the beginning when sorting ascedingly" do
        d = Daru::DataFrame.new({a: [1,1,1,nil,44,5,5,nil], b: [44,44,333,222,111,554,22,3], c: [3,2,5,3,3,1,5,5]})

        expect(d.sort!([:a, :b, :c], ascending: [true, true, false])).to eq(
          Daru::DataFrame.new({a: [nil,nil,1,1,1,5,5,44], b: [3,222,44,44,333,22,554,111], c: [5,3,3,2,5,5,1,3]},
            index: [7,3,0,1,2,6,5,4])
          )
      end

      it "places nils at the beginning when sorting decendingly" do
        d = Daru::DataFrame.new({a: [1,1,1,nil,44,5,5,nil], b: [44,44,333,222,111,554,22,3], c: [3,2,5,3,3,1,5,5]})

        expect(d.sort!([:a, :b, :c], ascending: [false, true, false])).to eq(
          Daru::DataFrame.new({a: [nil,nil,44,5,5,1,1,1], b: [3,222,111,22,554,44,44,333], c: [5,3,3,5,1,3,2,5]},
            index: [7,3,4,6,5,0,1,2])
          )
      end

      it "sorts vectors of non-numeric types with nils in ascending order" do
        non_numeric = Daru::DataFrame.new({a: [5,1,-6,7,5,5], b: [nil,-1,1,nil,-1,1],
          c: ['aaa','aaa',nil,'baaa','xxx',nil]})

        expect(non_numeric.sort!([:c], ascending: [true])).to eq(
          Daru::DataFrame.new({a: [-6, 5, 5, 1, 7, 5], b: [1, 1, nil, -1, nil, -1],
            c: [nil, nil, "aaa", "aaa", "baaa", "xxx"]},
            index: [2, 5, 0, 1, 3, 4])
          )
      end

      it "sorts vectors of non-numeric types with nils in descending order" do
        non_numeric = Daru::DataFrame.new({a: [5,1,-6,7,5,5], b: [nil,-1,1,nil,-1,1],
          c: ['aaa','aaa',nil,'baaa','xxx',nil]})

        expect(non_numeric.sort!([:c], ascending: [false])).to eq(
          Daru::DataFrame.new({a: [-6, 5, 5, 7, 5, 1], b: [1, 1, -1, nil, nil, -1],
            c: [nil, nil, "xxx", "baaa", "aaa", "aaa"]},
            index: [2, 5, 4, 3, 0, 1])
          )
      end

      it "sorts vectors with block provided and handle nils automatically" do
        non_numeric = Daru::DataFrame.new({a: [5,1,-6,7,5,5], b: [nil,-1,1,nil,-1,1],
          c: ['aaa','aaa',nil,'baaa','xxx',nil]})

        expect(non_numeric.sort!([:b], by: {b: lambda { |a| a.abs } }, handle_nils: true)).to eq(
          Daru::DataFrame.new({a: [5, 7, 1, -6, 5, 5], b: [nil, nil, -1, 1, -1, 1],
            c: ["aaa", "baaa", "aaa", nil, "xxx", nil]},
            index: [0, 3, 1, 2, 4, 5])
          )
      end

      it "sorts vectors with block provided and nils handled manually" do
        non_numeric = Daru::DataFrame.new({a: [5,1,-6,7,5,5], b: [nil,-1,1,nil,-1,1],
          c: ['aaa','aaa',nil,'baaa','xxx',nil]})

      expect(non_numeric.sort!([:b], by: {b: lambda { |a| (a.nil?)?[1]:[0, a.abs]} }, handle_nils: false)).to eq(
        Daru::DataFrame.new({a: [1, -6, 5, 5, 5, 7], b: [-1, 1, -1, 1, nil, nil],
          c: ["aaa", nil, "xxx", nil, "aaa", "baaa"]},
          index: [1, 2, 4, 5, 0, 3])
        )
      end
    end

    context Daru::MultiIndex do
      pending
      it "sorts the DataFrame when specified full tuple" do
        @df_mi.sort([[:a,:one,:bar]])
      end
    end
  end

  context "#index=" do
    before :each do
      @df = Daru::DataFrame.new({
        a: [1,2,3,4,5],
        b: [11,22,33,44,55],
        c: %w(a b c d e)
      })
    end

    it "simply reassigns the index" do
      @df.index = Daru::Index.new(['4','foo', :bar, 0, 23])
      expect(@df.row['foo']).to eq(Daru::Vector.new([2,22,'b'], index: [:a,:b,:c]))
    end

    it "raises error for improper length index" do
      expect {
        @df.index = Daru::Index.new([1,2])
      }.to raise_error(ArgumentError)
    end

    it "is able to accept array" do
      @df.index = (1..5).to_a
      expect(@df.index).to eq Daru::Index.new (1..5).to_a
    end
  end

  context '#order=' do
    let(:df) do
      Daru::DataFrame.new({
        a: [1, 2, 3],
        b: [4, 5, 6]
      }, order: [:a, :b])
    end

    context 'correct order' do
      before { df.order = [:b, :a] }
      subject { df }

      its(:'vectors.to_a') { is_expected.to eq [:b, :a] }
      its(:'b.to_a') { is_expected.to eq [4, 5, 6] }
      its(:'a.to_a') { is_expected.to eq [1, 2, 3] }
    end

    context 'insufficient vectors' do
      it { expect { df.order = [:a] }.to raise_error }
    end

    context 'wrong vectors' do
      it { expect { df.order = [:a, :b, 'b'] }.to raise_error }
    end
  end

  context "#vectors=" do
    before :each do
      @df = Daru::DataFrame.new({
        a: [1,2,3,4,5],
        b: [11,22,33,44,55],
        c: %w(a b c d e)
      })
    end

    it "simply reassigns vectors" do
      @df.vectors = Daru::Index.new(['b',0,'m'])

      expect(@df.vectors).to eq(Daru::Index.new(['b',0,'m']))
      expect(@df['b']).to eq(Daru::Vector.new([1,2,3,4,5]))
      expect(@df[0]).to eq(Daru::Vector.new([11,22,33,44,55]))
      expect(@df['m']).to eq(Daru::Vector.new(%w(a b c d e)))
    end

    it "raises error for improper length index" do
      expect {
        @df.vectors = Daru::Index.new([1,2,'3',4,'5'])
      }.to raise_error(ArgumentError)
    end

    it "change name of vectors in @data" do
      new_index_array = [:k, :l, :m]
      @df.vectors = Daru::Index.new(new_index_array)

      expect(@df.data.map { |vector| vector.name }).to eq(new_index_array)
    end
  end

  context "#rename_vectors" do
    before do
      @df = Daru::DataFrame.new({
        a: [1,2,3,4,5],
        b: [11,22,33,44,55],
        c: %w(a b c d e)
      })
    end

    it "renames vectors using a hash map" do
      @df.rename_vectors :a => :alpha, :c => :gamma
      expect(@df.vectors.to_a).to eq([:alpha, :b, :gamma])
    end

    it "overwrites vectors if the new name already exists" do
      saved_vector = @df[:a].dup

      @df.rename_vectors :a => :b
      expect(@df.vectors.to_a).to eq([:b, :c])
      expect(@df[:b]).to eq saved_vector
    end

    it "makes no changes if the old and new names are the same" do
      saved_vector = @df[:a].dup

      @df.rename_vectors :a => :a
      expect(@df.vectors.to_a).to eq([:a, :b, :c])
      expect(@df[:a]).to eq saved_vector
    end
  end

  context "#reindex" do
    it "re indexes and aligns accordingly" do
      df = Daru::DataFrame.new({
        a: [1,2,3,4,5],
        b: [11,22,33,44,55],
        c: %w(a b c d e)
      })

      ans = df.reindex(Daru::Index.new([1,3,0,8,2]))
      expect(ans).to eq(Daru::DataFrame.new({
        a: [2,4,1,nil,3],
        b: [22,44,11,nil,33],
        c: ['b','d','a',nil,'c']
        }, index: Daru::Index.new([1,3,0,8,2])))
      expect(ans).to_not eq(df)
    end
  end

  context "#reindex_vectors" do
    it "re indexes vectors and aligns accordingly" do
      df = Daru::DataFrame.new({
        a: [1,2,3,4,5],
        b: [11,22,33,44,55],
        c: %w(a b c d e)
      })

      ans = df.reindex_vectors(Daru::Index.new([:b, 'a', :a]))
      expect(ans).to eq(Daru::DataFrame.new({
        :b  => [11,22,33,44,55],
        'a' => [nil, nil, nil, nil, nil],
        :a  => [1,2,3,4,5]
      }, order: [:b, 'a', :a]))
    end
  end

  context "#to_matrix" do
    before do
      @df = Daru::DataFrame.new({b: [11,12,13,14,15], a: [1,2,3,4,5],
        c: [11,22,33,44,55], d: [5,4,nil,2,1], e: ['this', 'has', 'string','data','too']},
        order: [:a, :b, :c,:d,:e],
        index: [:one, :two, :three, :four, :five])
    end

    it "concats numeric non-nil vectors to Matrix" do
      expect(@df.to_matrix).to eq(Matrix[
        [1,11,11,5],
        [2,12,22,4],
        [3,13,33,nil],
        [4,14,44,2],
        [5,15,55,1]
      ])
    end
  end

  context "#to_nmatrix" do
    before do
      @df = Daru::DataFrame.new({b: [11,12,13,14,15], a: [1,2,3,4,5],
        c: [11,22,33,44,55], d: [5,4,nil,2,1], e: ['this', 'has', 'string','data','too']},
        order: [:a, :b, :c,:d,:e],
        index: [:one, :two, :three, :four, :five])
    end

    it "concats numeric non-nil vectors to NMatrix" do
      expect(@df.to_nmatrix).to eq(NMatrix.new([5,3],
        [1,11,11,
         2,12,22,
         3,13,33,
         4,14,44,
         5,15,55]
      ))
    end
  end

  context "#transpose" do
    context Daru::Index do
      it "transposes a DataFrame including row and column indexing" do
        expect(@data_frame.transpose).to eq(Daru::DataFrame.new({
          one: [1,11,11],
          two: [2,12,22],
          three: [3,13,33],
          four: [4,14,44],
          five: [5,15,55]
          }, index: [:a, :b, :c],
          order: [:one, :two, :three, :four, :five])
        )
      end
    end

    context Daru::MultiIndex do
      it "transposes a DataFrame including row and column indexing" do
        expect(@df_mi.transpose).to eq(Daru::DataFrame.new([
          @vector_arry1,
          @vector_arry2,
          @vector_arry1,
          @vector_arry2].transpose, index: @order_mi, order: @multi_index))
      end
    end
  end

  context "#pivot_table" do
    before do
      @df = Daru::DataFrame.new({
        a: ['foo'  ,  'foo',  'foo',  'foo',  'foo',  'bar',  'bar',  'bar',  'bar'],
        b: ['one'  ,  'one',  'one',  'two',  'two',  'one',  'one',  'two',  'two'],
        c: ['small','large','large','small','small','large','small','large','small'],
        d: [1,2,2,3,3,4,5,6,7],
        e: [2,4,4,6,6,8,10,12,14]
      })
    end

    it "creates row index as per (single) index argument and default aggregates to mean" do
      expect(@df.pivot_table(index: [:a])).to eq(Daru::DataFrame.new({
        d: [5.5,2.2],
        e: [11.0,4.4]
      }, index: ['bar', 'foo']))
    end

    it "creates row index as per (double) index argument and default aggregates to mean" do
      agg_mi = Daru::MultiIndex.from_tuples(
        [
          ['bar', 'large'],
          ['bar', 'small'],
          ['foo', 'large'],
          ['foo', 'small']
        ]
      )
      expect(@df.pivot_table(index: [:a, :c]).round(2)).to eq(Daru::DataFrame.new({
        d: [5.0 ,  6.0, 2.0, 2.33],
        e: [10.0, 12.0, 4.0, 4.67]
      }, index: agg_mi))
    end

    it "creates row and vector index as per (single) index and (single) vectors args" do
      agg_vectors = Daru::MultiIndex.from_tuples([
        [:d, 'one'],
        [:d, 'two'],
        [:e, 'one'],
        [:e, 'two']
      ])
      agg_index = Daru::MultiIndex.from_tuples(
        [
          ['bar'],
          ['foo']
        ]
      )

      expect(@df.pivot_table(index: [:a], vectors: [:b]).round(2)).to eq(
        Daru::DataFrame.new(
          [
            [4.5, 1.67],
            [6.5,  3.0],
            [9.0, 3.33],
            [13,     6]
          ], order: agg_vectors, index: agg_index)
      )
    end

    it "creates row and vector index as per (single) index and (double) vector args" do
      agg_vectors = Daru::MultiIndex.from_tuples(
        [
          [:d, 'one', 'large'],
          [:d, 'one', 'small'],
          [:d, 'two', 'large'],
          [:d, 'two', 'small'],
          [:e, 'one', 'large'],
          [:e, 'one', 'small'],
          [:e, 'two', 'large'],
          [:e, 'two', 'small']
        ]
      )

      agg_index = Daru::MultiIndex.from_tuples(
        [
          ['bar'],
          ['foo']
        ]
      )

      expect(@df.pivot_table(index: [:a], vectors: [:b, :c])).to eq(Daru::DataFrame.new(
        [
          [4.0,2.0],
          [5.0,1.0],
          [6.0,nil],
          [7.0,3.0],
          [8.0,4.0],
          [10.0,2.0],
          [12.0,nil],
          [14.0,6.0]
        ], order: agg_vectors, index: agg_index
      ))
    end

    it "creates row and vector index with (double) index and (double) vector args" do
      agg_index = Daru::MultiIndex.from_tuples([
        ['bar', 4],
        ['bar', 5],
        ['bar', 6],
        ['bar', 7],
        ['foo', 1],
        ['foo', 2],
        ['foo', 3]
      ])

      agg_vectors = Daru::MultiIndex.from_tuples([
        [:e, 'one', 'large'],
        [:e, 'one', 'small'],
        [:e, 'two', 'large'],
        [:e, 'two', 'small']
      ])

      expect(@df.pivot_table(index: [:a, :d], vectors: [:b, :c])).to eq(
        Daru::DataFrame.new(
          [
            [8  ,nil,nil,nil,nil,  4,nil],
            [nil, 10,nil,nil,  2,nil,nil],
            [nil,nil, 12,nil,nil,nil,nil],
            [nil,nil,nil, 14,nil,nil,  6],
          ], index: agg_index, order: agg_vectors)
      )
    end

    it "only aggregates over the vector specified in the values argument" do
      agg_vectors = Daru::MultiIndex.from_tuples(
        [
          [:e, 'one', 'large'],
          [:e, 'one', 'small'],
          [:e, 'two', 'large'],
          [:e, 'two', 'small']
        ]
      )
      agg_index = Daru::MultiIndex.from_tuples(
        [
          ['bar'],
          ['foo']
        ]
      )
      expect(@df.pivot_table(index: [:a], vectors: [:b, :c], values: :e)).to eq(
        Daru::DataFrame.new(
          [
            [8,   4],
            [10,  2],
            [12,nil],
            [14,  6]
          ], order: agg_vectors, index: agg_index
        )
      )

      agg_vectors = Daru::MultiIndex.from_tuples(
        [
          [:d, 'one'],
          [:d, 'two'],
          [:e, 'one'],
          [:e, 'two']
        ]
      )
      expect(@df.pivot_table(index: [:a], vectors: [:b], values: [:d, :e])).to eq(
        Daru::DataFrame.new(
          [
            [4.5,  5.0/3],
            [6.5,    3.0],
            [9.0, 10.0/3],
            [13.0,   6.0]
          ], order: agg_vectors, index: agg_index
        )
      )
    end

    it "overrides default aggregate function to aggregate over sum" do
      agg_vectors = Daru::MultiIndex.from_tuples(
        [
          [:e, 'one', 'large'],
          [:e, 'one', 'small'],
          [:e, 'two', 'large'],
          [:e, 'two', 'small']
        ]
      )
      agg_index = Daru::MultiIndex.from_tuples(
        [
          ['bar'],
          ['foo']
        ]
      )
      expect(@df.pivot_table(index: [:a], vectors: [:b, :c], values: :e, agg: :sum)).to eq(
        Daru::DataFrame.new(
          [
            [8,   8],
            [10,  2],
            [12,nil],
            [14, 12]
          ], order: agg_vectors, index: agg_index
        )
      )
    end

    it "raises error if no non-numeric vectors are present" do
      df = Daru::DataFrame.new({a: ['a', 'b', 'c'], b: ['b', 'e', 'd']})
      expect {
        df.pivot_table(index: [:a])
      }.to raise_error
    end

    it "raises error if atleast a row index is not specified" do
      expect {
        @df.pivot_table
      }.to raise_error
    end

    it "aggregates when nils are present in value vector" do
      df = Daru::DataFrame.new({
        a: ['foo'  ,  'foo',  'foo',  'foo',  'foo',  'bar',  'bar',  'bar',  'ice'],
        b: ['one'  ,  'one',  'one',  'two',  'two',  'one',  'one',  'two',  'two'],
        c: ['small','large','large','small','small','large','small','large','small'],
        d: [1,2,2,3,3,4,5,6,7],
        e: [2,nil,4,6,6,8,10,12,nil]
      })

      expect(df.pivot_table index: [:a]).to eq(
        Daru::DataFrame.new({
          d:  [5.0, 2.2, 7],
          e:  [10.0, 4.5, nil]
        }, index: Daru::Index.new(['bar', 'foo', 'ice'])))
    end

    it "works when nils are present in value vector" do
      df = Daru::DataFrame.new({
        a: ['foo'  ,  'foo',  'foo',  'foo',  'foo',  'bar',  'bar',  'bar',  'ice'],
        b: ['one'  ,  'one',  'one',  'two',  'two',  'one',  'one',  'two',  'two'],
        c: ['small','large','large','small','small','large','small','large','small'],
        d: [1,2,2,3,3,4,5,6,7],
        e: [2,nil,4,6,6,8,10,12,nil]
      })

      agg_vectors = Daru::MultiIndex.from_tuples(
        [
          [:e, 'one'],
          [:e, 'two']
        ]
      )

      agg_index = Daru::MultiIndex.from_tuples(
        [
          ['bar'],
          ['foo'],
          ['ice']
        ]
      )

      expect(df.pivot_table index: [:a], vectors: [:b], values: :e).to eq(
        Daru::DataFrame.new(
          [
            [9, 3,  nil],
            [12, 6, nil]
          ], order: agg_vectors, index: agg_index
        )
      )
    end

    it 'performs date pivoting' do
      categories = %i[jan feb mar apr may jun jul aug sep oct nov dec]
      df = Daru::DataFrame.rows([
        [2014, 2, 1600.0, 20.0],
        [2014, 3, 1680.0, 21.0],
        [2016, 2, 1600.0, 20.0],
        [2016, 4, 1520.0, 19.0],
      ], order: [:year, :month, :visitors, :days])
      df[:averages] = df[:visitors] / df[:days]
      df[:month] = df[:month].map{|i| categories[i - 1]}
      actual = df.pivot_table(index: :month, vectors: [:year], values: :averages)

      # NB: As you can see, there are some "illogical" parts:
      #     months are sorted lexicographically, then made into multi-index
      #     with one-element-per-tuple, then order of columns is dependent
      #     on which month is lexicographically first (its apr, so, apr-2016
      #     is first row to gather, so 2016 is first column).
      #
      #     All of it is descendance of our group_by implementation (which
      #     always sorts results & always make array keys). I hope that fixing
      #     group_by, even to the extend described at https://github.com/v0dro/daru/issues/152,
      #     will be fix this case also.
      expected =
        Daru::DataFrame.new(
          [
            [80.0, 80.0, nil],
            [nil, 80.0, 80.0],
          ], index: Daru::MultiIndex.from_tuples([[:apr], [:feb], [:mar]]),
          order: Daru::MultiIndex.from_tuples([[:averages, 2016], [:averages, 2014]])
        )
      # Comparing their parts previous to full comparison allows to
      # find complicated differences.
      expect(actual.vectors).to eq expected.vectors
      expect(actual.index).to eq expected.index
      expect(actual).to eq expected
    end
  end

  context "#shape" do
    it "returns an array containing number of rows and columns" do
      expect(@data_frame.shape).to eq([5,3])
    end
  end

  context "#nest" do
    it "nests in a hash" do
      df = Daru::DataFrame.new({
        :a => Daru::Vector.new(%w(a a a b b b)),
        :b => Daru::Vector.new(%w(c c d d e e)),
        :c => Daru::Vector.new(%w(f g h i j k))
      })
      nest = df.nest :a, :b
      expect(nest['a']['c']).to eq([{ :c => 'f' }, { :c => 'g' }])
      expect(nest['a']['d']).to eq([{ :c => 'h' }])
      expect(nest['b']['e']).to eq([{ :c => 'j' }, { :c => 'k' }])
    end
  end

  context "#summary" do
    subject { df.summary }

    context "DataFrame" do
      let(:df) { Daru::DataFrame.new({a: [1,2,5], b: [1,2,"string"]}, order: [:a, :b], index: [:one, :two, :three], name: 'frame') }
      it { is_expected.to eq %Q{
            |= frame
            |  Number of rows: 3
            |  Element:[a]
            |  == a
            |    n :3
            |    non-missing:3
            |    median: 2
            |    mean: 2.6667
            |    std.dev.: 2.0817
            |    std.err.: 1.2019
            |    skew: 0.2874
            |    kurtosis: -2.3333
            |  Element:[b]
            |  == b
            |    n :3
            |    non-missing:3
            |    factors: 1,2,string
            |    mode: 1,2,string
            |    Distribution
            |                 1       1 100.00%
            |                 2       1 100.00%
            |            string       1 100.00%
        }.unindent }
    end
  end

  context '#to_df' do
    it 'returns the dataframe' do
      @data_frame.to_df == @data_frame
    end
  end

  context "#to_gsl" do
    it "converts to GSL::Matrix" do
      rows = [[1,2,3,4,5],[11,12,13,14,15],[11,22,33,44,55]].transpose
      mat = GSL::Matrix.alloc *rows
      expect(@data_frame.to_gsl).to eq(mat)
    end
  end

  context "#merge" do
    it "merges one dataframe with another" do
      a = Daru::Vector.new [1, 2, 3]
      b = Daru::Vector.new [3, 4, 5]
      c = Daru::Vector.new [4, 5, 6]
      d = Daru::Vector.new [7, 8, 9]
      e = Daru::Vector.new [10, 20, 30]
      ds1 = Daru::DataFrame.new({ :a => a, :b => b })
      ds2 = Daru::DataFrame.new({ :c => c, :d => d })
      exp = Daru::DataFrame.new({ :a => a, :b => b, :c => c, :d => d })

      expect(ds1.merge(ds2)).to eq(exp)
      expect(ds2.merge(ds1)).to eq(
        Daru::DataFrame.new({c: c, d: d, a: a, b: b}, order: [:c, :d, :a, :b]))

      ds3 = Daru::DataFrame.new({ :a => e })
      exp = Daru::DataFrame.new({ :a_1 => a, :a_2 => e, :b => b },
        order: [:a_1, :b, :a_2])

      expect(ds1.merge(ds3)).to eq(exp)
    end

    context "preserves type of vector names" do
      let(:df1) { Daru::DataFrame.new({'a'=> [1, 2, 3]}) }
      let(:df2) { Daru::DataFrame.new({:b=> [4, 5, 6]}) }
      subject { df1.merge df2 }

      it { is_expected.to be_a Daru::DataFrame }
      it { expect(subject['a'].to_a).to eq [1, 2, 3] }
      it { expect(subject[:b].to_a).to eq [4, 5, 6] }
    end

    context "preserves indices for dataframes with same index" do
      let(:index) { ['one','two','three'] }
      let(:df1) { Daru::DataFrame.new({ 'a' => [1, 2, 3], 'b' => [3, 4, 5] }, index: index) }
      let(:df2) { Daru::DataFrame.new({ 'c' => [4, 5, 6], 'd' => [7, 8, 9] }, index: index) }
      subject { df1.merge df2 }

      its(:index) { is_expected.to eq Daru::Index.new(index) }
    end
  end

  context "#vector_by_calculation" do
    it "DSL for returning vector of each calculation" do
      a1 = Daru::Vector.new([1, 2, 3, 4, 5, 6, 7])
      a2 = Daru::Vector.new([10, 20, 30, 40, 50, 60, 70])
      a3 = Daru::Vector.new([100, 200, 300, 400, 500, 600, 700])
      ds = Daru::DataFrame.new({ :a => a1, :b => a2, :c => a3 })
      total = ds.vector_by_calculation { a + b + c }
      expected = Daru::Vector.new([111, 222, 333, 444, 555, 666, 777])
      expect(total).to eq(expected)
    end
  end

  context "group_by" do
    context "on a single row DataFrame" do
      let(:df){ Daru::DataFrame.new(city: %w[Kyiv], year: [2015], value: [1]) }
      it "returns a groupby object" do
        expect(df.group_by([:city])).to be_a(Daru::Core::GroupBy)
      end
      it "has the correct index" do
        expect(df.group_by([:city]).groups).to eq({["Kyiv"]=>[0]})
      end
    end
  end

  context "#vector_sum" do
    before do
      a1 = Daru::Vector.new [1, 2, 3, 4, 5, nil, nil]
      a2 = Daru::Vector.new [10, 10, 20, 20, 20, 30, nil]
      b1 = Daru::Vector.new [nil, 1, 1, 1, 1, 2, nil]
      b2 = Daru::Vector.new [2, 2, 2, nil, 2, 3, nil]
      @df = Daru::DataFrame.new({ :a1 => a1, :a2 => a2, :b1 => b1, :b2 => b2 })
    end

    it "calculates complete vector sum" do
      expect(@df.vector_sum).to eq(Daru::Vector.new [nil, 15, 26, nil, 28, nil, nil])
    end

    it "ignores nils if skipnil is true" do
      expect(@df.vector_sum skipnil: true).to eq(Daru::Vector.new [13, 15, 26, 25, 28, 35, 0])
    end

    it "calculates partial vector sum" do
      a = @df.vector_sum([:a1, :a2])
      b = @df.vector_sum([:b1, :b2])

      expect(a).to eq(Daru::Vector.new [11, 12, 23, 24, 25, nil, nil])
      expect(b).to eq(Daru::Vector.new [nil, 3, 3, nil, 3, 5, nil])
    end
  end

  context "#missing_values_rows" do
    it "returns number of missing values in each row" do
      a1 = Daru::Vector.new [1, nil, 3, 4, 5, nil]
      a2 = Daru::Vector.new [10, nil, 20, 20, 20, 30]
      b1 = Daru::Vector.new [nil, nil, 1, 1, 1, 2]
      b2 = Daru::Vector.new [2, 2, 2, nil, 2, 3]
      c  = Daru::Vector.new [nil, 2, 4, 2, 2, 2]
      df = Daru::DataFrame.new({
        :a1 => a1, :a2 => a2, :b1 => b1, :b2 => b2, :c => c })

      expect(df.missing_values_rows).to eq(Daru::Vector.new [2, 3, 0, 1, 0, 1])
    end
  end

  context "#vector_count_characters" do
    it "" do
      a1  = Daru::Vector.new( [1, 'abcde', 3, 4, 5, nil])
      a2  = Daru::Vector.new( [10, 20.3, 20, 20, 20, 30])
      b1  = Daru::Vector.new( [nil, '343434', 1, 1, 1, 2])
      b2  = Daru::Vector.new( [2, 2, 2, nil, 2, 3])
      c   = Daru::Vector.new([nil, 2, 'This is a nice example', 2, 2, 2])
      ds  = Daru::DataFrame.new({ :a1 => a1, :a2 => a2, :b1 => b1, :b2 => b2, :c => c })

      expect(ds.vector_count_characters).to eq(Daru::Vector.new([4, 17, 27, 5, 6, 5]))
    end
  end

  context '#include_values?' do
    let(:df) do
      Daru::DataFrame.new({
        a: [1,   2,  3,   4,          Float::NAN, 6, 1],
        b: [:a,  :b, nil, Float::NAN, nil,        3, 5],
        c: ['a', 6,  3,   4,          3,          5, 3],
        d: [1,   2,  3,   5,          1,          2, 5]
      })
    end
    before { df.to_category :b }

    context 'true' do
      it { expect(df.include_values? nil).to eq true }
      it { expect(df.include_values? Float::NAN).to eq true }
      it { expect(df.include_values? nil, Float::NAN).to eq true }
      it { expect(df.include_values? 1, 30).to eq true }
    end

    context 'false' do
      it { expect(df[:a, :c].include_values? nil).to eq false }
      it { expect(df[:c, :d].include_values? Float::NAN).to eq false }
      it { expect(df[:c, :d].include_values? nil, Float::NAN).to eq false }
      it { expect(df.include_values? 10, 20).to eq false }
    end
  end

  context "#vector_mean" do
    before do
      a1 = Daru::Vector.new [1, 2, 3, 4, 5, nil]
      a2 = Daru::Vector.new [10, 10, 20, 20, 20, 30]
      b1 = Daru::Vector.new [nil, 1, 1, 1, 1, 2]
      b2 = Daru::Vector.new [2, 2, 2, nil, 2, 3]
      c  = Daru::Vector.new [nil, 2, 4, 2, 2, 2]
      @df = Daru::DataFrame.new({
        :a1 => a1, :a2 => a2, :b1 => b1, :b2 => b2, :c => c })
    end

    it "calculates complete vector mean" do
      expect(@df.vector_mean).to eq(
        Daru::Vector.new [nil, 3.4, 6, nil, 6.0, nil])
    end
  end

  context "#add_vectors_by_split_recode" do
    before do
      @ds = Daru::DataFrame.new({
        :id   => Daru::Vector.new([1, 2, 3, 4, 5]),
        :name => Daru::Vector.new(%w(Alex Claude Peter Franz George)),
        :age  => Daru::Vector.new([20, 23, 25, 27, 5]),
        :city => Daru::Vector.new(['New York', 'London', 'London', 'Paris', 'Tome']),
        :a1   => Daru::Vector.new(['a,b', 'b,c', 'a', nil, 'a,b,c']) },
        order: [:id, :name, :age, :city, :a1])
    end

    it "" do
      @ds.add_vectors_by_split_recode(:a1, '_')
      expect(@ds.vectors.to_a)    .to eq([:id, :name, :age, :city ,:a1, :a1_1, :a1_2, :a1_3])
      expect(@ds[:a1_1].to_a).to eq([1, 0, 1, nil, 1])
      expect(@ds[:a1_2].to_a).to eq([1, 1, 0, nil, 1])
      expect(@ds[:a1_3].to_a).to eq([0, 1, 0, nil, 1])
    end
  end

  context "#add_vectors_by_split" do
    before do
      @ds = Daru::DataFrame.new({
        :id   => Daru::Vector.new([1, 2, 3, 4, 5]),
        :name => Daru::Vector.new(%w(Alex Claude Peter Franz George)),
        :age  => Daru::Vector.new([20, 23, 25, 27, 5]),
        :city => Daru::Vector.new(['New York', 'London', 'London', 'Paris', 'Tome']),
        :a1   => Daru::Vector.new(['a,b', 'b,c', 'a', nil, 'a,b,c'])
        }, order: [:id, :name, :age, :city, :a1])
    end

    it "" do
      @ds.add_vectors_by_split(:a1, '_')
      expect(@ds.vectors.to_a).to eq([:id, :name, :age, :city, :a1, :a1_a, :a1_b, :a1_c])
      expect(@ds[:a1_a].to_a).to eq([1, 0, 1, nil, 1])
      expect(@ds[:a1_b].to_a).to eq([1, 1, 0, nil, 1])
      expect(@ds[:a1_c].to_a).to eq([0, 1, 0, nil, 1])
    end
  end

  context "#verify" do
    def create_test(*args, &_proc)
      description = args.shift
      fields = args
      [description, fields, Proc.new]
    end

    before do
      name = Daru::Vector.new %w(r1 r2 r3 r4)
      v1   = Daru::Vector.new [1, 2, 3, 4]
      v2   = Daru::Vector.new [4, 3, 2, 1]
      v3   = Daru::Vector.new [10, 20, 30, 40]
      v4   = Daru::Vector.new %w(a b a b)
      @df = Daru::DataFrame.new({
        :v1 => v1, :v2 => v2, :v3 => v3, :v4 => v4, :id => name
        }, order: [:v1, :v2, :v3, :v4, :id])
    end

    it "correctly verifies data as per the block" do
      # Correct
      t1 = create_test('If v4=a, v1 odd') do |r|
        r[:v4] == 'b' or (r[:v4] == 'a' and r[:v1].odd?)
      end
      t2 = create_test('v3=v1*10')  { |r| r[:v3] == r[:v1] * 10 }
      # Fail!
      t3 = create_test("v4='b'") { |r| r[:v4] == 'b' }
      exp1 = ["1 [1]: v4='b'", "3 [3]: v4='b'"]
      exp2 = ["1 [r1]: v4='b'", "3 [r3]: v4='b'"]

      dataf = @df.verify(t3, t1, t2)
      expect(dataf).to eq(exp1)
    end

    it "uses additional fields to extend error messages" do
      t = create_test("v4='b'", :v2, :v3) { |r| r[:v4] == 'b' }

      dataf = @df.verify(:id, t)
      expect(dataf).to eq(["1 [r1]: v4='b' (v2=4, v3=10)", "3 [r3]: v4='b' (v2=2, v3=30)"])
    end
  end

  context "#compute" do
    it "performs a computation when supplied in a string" do
      v1       = Daru::Vector.new [1, 2, 3, 4]
      v2       = Daru::Vector.new [4, 3, 2, 1]
      v3       = Daru::Vector.new [10, 20, 30, 40]
      vnumeric = Daru::Vector.new [0, 0, 1, 4]
      vsum     = Daru::Vector.new [1 + 4 + 10.0, 2 + 3 + 20.0, 3 + 2 + 30.0, 4 + 1 + 40.0]
      vmult    = Daru::Vector.new [1 * 4, 2 * 3, 3 * 2, 4 * 1]

      df = Daru::DataFrame.new({:v1 => v1, :v2 => v2, :v3 => v3})

      expect(df.compute("v1/v2")).to eq(vnumeric)
      expect(df.compute("v1+v2+v3")).to eq(vsum)
      expect(df.compute("v1*v2")).to eq(vmult)
    end
  end

  context ".crosstab_by_assignation" do
    it "" do
      v1 = Daru::Vector.new %w(a a a b b b c c c)
      v2 = Daru::Vector.new %w(a b c a b c a b c)
      v3 = Daru::Vector.new [0, 1, 0, 0, 1, 1, 0, 0, 1]
      df = Daru::DataFrame.crosstab_by_assignation(v1, v2, v3)

      expect(df[:_id].type).to eq(:object)
      expect(df['a'].type).to eq(:numeric)
      expect(df['b'].type).to eq(:numeric)

      ev_id = Daru::Vector.new %w(a b c)
      ev_a  = Daru::Vector.new [0, 0, 0]
      ev_b  = Daru::Vector.new [1, 1, 0]
      ev_c  = Daru::Vector.new [0, 1, 1]
      df2 = Daru::DataFrame.new({
        :_id => ev_id, 'a' => ev_a, 'b' => ev_b, 'c' => ev_c },
        order: ['a', 'b', 'c', :_id])

      expect(df2).to eq(df)
    end
  end

  context "#one_to_many" do
    it "" do
      rows = [
        ['1', 'george', 'red', 10, 'blue', 20, nil, nil],
        ['2', 'fred', 'green', 15, 'orange', 30, 'white', 20],
        ['3', 'alfred', nil, nil, nil, nil, nil, nil]
      ]

      df = Daru::DataFrame.rows(rows,
        order: ['id', 'name', 'car_color1', 'car_value1', 'car_color2',
          'car_value2', 'car_color3', 'car_value3'])

      ids     = Daru::Vector.new %w(1 1 2 2 2)
      colors  = Daru::Vector.new %w(red blue green orange white)
      values  = Daru::Vector.new [10, 20, 15, 30, 20]
      col_ids = Daru::Vector.new [1, 2, 1, 2, 3]

      df_expected = Daru::DataFrame.new({
        'id' => ids, '_col_id' => col_ids, 'color' => colors, 'value' => values
        }, order: ['id', '_col_id', 'color', 'value'])

      expect(df.one_to_many(['id'], 'car_%v%n')).to eq(df_expected)
    end
  end

  context "#any?" do
    before do
      @df = Daru::DataFrame.new({
        a: [1,2,3,4,5],
        b: [10,20,30,40,50],
        c: [11,22,33,44,55]})
    end

    it "returns true if any one of the vectors satisfy condition" do
      expect(@df.any? { |v| v[0] == 1 }).to eq(true)
    end

    it "returns false if none of the vectors satisfy the condition" do
      expect(@df.any? { |v| v.mean > 100 }).to eq(false)
    end

    it "returns true if any one of the rows satisfy condition" do
      expect(@df.any?(:row) { |r| r[:a] == 1 and r[:c] == 11 }).to eq(true)
    end

    it "returns false if none of the rows satisfy the condition" do
      expect(@df.any?(:row) { |r| r.mean > 100 }).to eq(false)
    end

    it 'fails on unknown axis' do
      expect { @df.any?(:kitten) { |r| r.mean > 100 } }.to raise_error ArgumentError, /axis/
    end
  end

  context "#all?" do
    before do
      @df = Daru::DataFrame.new({
        a: [1,2,3,4,5],
        b: [10,20,30,40,50],
        c: [11,22,33,44,55]})
    end

    it "returns true if all of the vectors satisfy condition" do
      expect(@df.all? { |v| v.mean < 40 }).to eq(true)
    end

    it "returns false if any one of the vectors does not satisfy condition" do
      expect(@df.all? { |v| v.mean == 30 }).to eq(false)
    end

    it "returns true if all of the rows satisfy condition" do
      expect(@df.all?(:row) { |r| r.mean < 70 }).to eq(true)
    end

    it "returns false if any one of the rows does not satisfy condition" do
      expect(@df.all?(:row) { |r| r.mean == 30 }).to eq(false)
    end

    it 'fails on unknown axis' do
      expect { @df.all?(:kitten) { |r| r.mean > 100 } }.to raise_error ArgumentError, /axis/
    end
  end

  context "#only_numerics" do
    before do
      @v1 = Daru::Vector.new([1,2,3,4,5])
      @v2 = Daru::Vector.new(%w(one two three four five))
      @v3 = Daru::Vector.new([11,22,33,44,55])
      @df = Daru::DataFrame.new({
        a: @v1, b: @v2, c: @v3 }, clone: false)
    end

    it "returns a view of only the numeric vectors" do
      dfon = @df.only_numerics(clone: false)

      expect(dfon).to eq(
        Daru::DataFrame.new({ a: @v1, c: @v3 }, clone: false))
      expect(dfon[:a].object_id).to eq(@v1.object_id)
    end

    it "returns a clone of numeric vectors" do
      dfon = @df.only_numerics

      expect(dfon).to eq(
        Daru::DataFrame.new({ a: @v1, c: @v3}, clone: false)
      )
      expect(dfon[:a].object_id).to_not eq(@v1.object_id)
    end

    context Daru::MultiIndex do
      before do
        agg_vectors = Daru::MultiIndex.from_tuples(
          [
            [:d, :one, :large],
            [:d, :one, :small],
            [:d, :two, :large],
            [:d, :two, :small],
            [:e, :one, :large],
            [:e, :one, :small],
            [:e, :two, :large],
            [:e, :two, :small]
          ]
        )

        agg_index = Daru::MultiIndex.from_tuples(
          [
            [:bar],
            [:foo]
          ]
        )
        @df = Daru::DataFrame.new(
          [
            [4.112,2.234],
            %w(a b),
            [6.342,nil],
            [7.2344,3.23214],
            [8.234,4.533],
            [10.342,2.3432],
            [12.0,nil],
            %w(a b)
          ], order: agg_vectors, index: agg_index
        )
      end

      it "returns numeric vectors" do
        vectors = Daru::MultiIndex.from_tuples(
          [
            [:d, :one, :large],
            [:d, :two, :large],
            [:d, :two, :small],
            [:e, :one, :large],
            [:e, :one, :small],
            [:e, :two, :large]
          ]
        )

        index = Daru::MultiIndex.from_tuples(
          [
            [:bar],
            [:foo]
          ]
        )
        answer = Daru::DataFrame.new(
          [
            [4.112,2.234],
            [6.342,nil],
            [7.2344,3.23214],
            [8.234,4.533],
            [10.342,2.3432],
            [12.0,nil],
          ], order: vectors, index: index
        )

        expect(@df.only_numerics).to eq(answer)
      end
    end
  end

  context "#set_index" do
    before(:each) do
      @df = Daru::DataFrame.new({
        a: [1,2,3,4,5],
        b: ['a','b','c','d','e'],
        c: [11,22,33,44,55]
        })
    end

    it "sets a particular column as the index and deletes that column" do
      @df.set_index(:b)
      expect(@df).to eq(
        Daru::DataFrame.new({
          a: [1,2,3,4,5],
          c: [11,22,33,44,55]
          }, index: ['a','b','c','d','e'])
        )
    end

    it "sets a particular column as index but keeps that column" do
      expect(@df.set_index(:c, keep: true)).to eq(
        Daru::DataFrame.new({
          a: [1,2,3,4,5],
          b: ['a','b','c','d','e'],
          c: [11,22,33,44,55]
          }, index: [11,22,33,44,55]))
      expect(@df[:c]).to eq(@df[:c])
    end

    it "raises error if all elements in the column aren't unique" do
      jholu = Daru::DataFrame.new({
        a: ['a','b','a'],
        b: [1,2,4]
        })

      expect {
        jholu.set_index(:a)
      }.to raise_error(ArgumentError)
    end
  end

  context "#concat" do
    before do
      @df1 = Daru::DataFrame.new({
        a: [1, 2, 3],
        b: [1, 2, 3]
      })

      @df2 = Daru::DataFrame.new({
        a: [4, 5, 6],
        c: [4, 5, 6]
      })
    end

    it 'does not modify the original dataframes' do
      df1_a = @df1[:a].to_a.dup
      df2_a = @df2[:a].to_a.dup

      df_concat = @df1.concat @df2
      expect(@df1[:a].to_a).to eq df1_a
      expect(@df2[:a].to_a).to eq df2_a
    end

    it 'creates a new dataframe that is a concatenation of the two dataframe arguments' do
      df1_a = @df1[:a].to_a.dup
      df2_a = @df2[:a].to_a.dup

      df_concat = @df1.concat @df2
      expect(df_concat[:a].to_a).to eq df1_a + df2_a
    end

    it 'fills in missing vectors with nils' do
      df1_b = @df1[:b].to_a.dup
      df2_c = @df2[:c].to_a.dup

      df_concat = @df1.concat @df2
      expect(df_concat[:b].to_a).to eq df1_b + [nil] * @df2.size
      expect(df_concat[:c].to_a).to eq [nil] * @df1.size + df2_c
    end

  end

  context "#union" do
    before do
      @df1 = Daru::DataFrame.new({
        a: [1, 2, 3],
        b: [1, 2, 3]},
        index: [1,3,5] )

      @df2 = Daru::DataFrame.new({
        a: [4, 5, 6],
        c: [4, 5, 6]},
        index: [7,9,11])

      @df3 = Daru::DataFrame.new({
        a: [4, 5, 6],
        c: [4, 5, 6]},
        index: [5,7,9])
    end

    it 'does not modify the original dataframes' do
      df1_a = @df1[:a].to_a.dup
      df2_a = @df2[:a].to_a.dup

      _ = @df1.union @df2
      expect(@df1[:a].to_a).to eq df1_a
      expect(@df2[:a].to_a).to eq df2_a
    end

    it 'creates a new dataframe that is a concatenation of the two dataframe arguments' do
      df1_a = @df1[:a].to_a.dup
      df2_a = @df2[:a].to_a.dup

      df_union = @df1.union @df2
      expect(df_union[:a].to_a).to eq df1_a + df2_a
    end

    it 'fills in missing vectors with nils' do
      df1_b = @df1[:b].to_a.dup
      df2_c = @df2[:c].to_a.dup

      df_union = @df1.union @df2
      expect(df_union[:b].to_a).to eq df1_b + [nil] * @df2.size
      expect(df_union[:c].to_a).to eq [nil] * @df1.size + df2_c
    end

    it 'overwrites part of the first dataframe if there are double indices' do
      vec = Daru::Vector.new({a: 4, b: nil, c: 4})
      expect(@df1.union(@df3).row[5]).to eq vec
    end

    it 'concats the indices' do
      v1 = @df1.index.to_a
      v2 = @df2.index.to_a

      df_union = @df1.union @df2
      expect(df_union.index.to_a).to eq v1 + v2
    end
  end

  context '#inspect' do
    subject { df.inspect }

    context 'empty' do
      let(:df) { Daru::DataFrame.new({}, order: %w[a b c])}
      it { is_expected.to eq %Q{
        |#<Daru::DataFrame(0x3)>
        |   a   b   c
      }.unindent}
    end

    context 'simple' do
      let(:df) { Daru::DataFrame.new({a: [1,2,3], b: [3,4,5], c: [6,7,8]}, name: 'test')}
      it { should == %Q{
        |#<Daru::DataFrame: test (3x3)>
        |       a   b   c
        |   0   1   3   6
        |   1   2   4   7
        |   2   3   5   8
       }.unindent}
    end

    context 'if index name is set' do
      context 'single index with name' do
        let(:df) { Daru::DataFrame.new({a: [1,2,3], b: [3,4,5], c: [6,7,8]},
        name: 'test')}
        before { df.index.name = 'index_name' }
        it { should == %Q{
          |#<Daru::DataFrame: test (3x3)>
          | index_name          a          b          c
          |          0          1          3          6
          |          1          2          4          7
          |          2          3          5          8
         }.unindent}
      end

      context 'MultiIndex with name' do
        let(:mi) { Daru::MultiIndex.new(
                levels: [[:a,:b,:c], [:one, :two]],
                labels: [[0,0,1,1,2,2], [0,1,0,1,0,1]], name: ['s1', 's2']) }
        let(:df) { Daru::DataFrame.new({
          a: [11, 12, 13, 14, 15, 16], b: [21, 22, 23, 24, 25, 26]},
            name: 'test', index: mi)}
        it { should == %Q{
          |#<Daru::DataFrame: test (6x2)>
          |  s1  s2   a   b
          |   a one  11  21
          |     two  12  22
          |   b one  13  23
          |     two  14  24
          |   c one  15  25
          |     two  16  26
         }.unindent}
      end

    end

    context 'no name' do
      let(:df) { Daru::DataFrame.new({a: [1,2,3], b: [3,4,5], c: [6,7,8]})}
      it { should == %Q{
        |#<Daru::DataFrame(3x3)>
        |       a   b   c
        |   0   1   3   6
        |   1   2   4   7
        |   2   3   5   8
       }.unindent}
    end

    context 'with nils' do
      let(:df) { Daru::DataFrame.new({a: [1,nil,3], b: [3,4,5], c: [6,7,nil]}, name: 'test')}
      it { is_expected.to eq %Q{
        |#<Daru::DataFrame: test (3x3)>
        |       a   b   c
        |   0   1   3   6
        |   1 nil   4   7
        |   2   3   5 nil
       }.unindent}
    end

    context 'very long' do
      let(:df) { Daru::DataFrame.new({a: [1,1,1]*20, b: [1,1,1]*20, c: [1,1,1]*20}, name: 'test')}
      it { is_expected.to eq %Q{
        |#<Daru::DataFrame: test (60x3)>
        |       a   b   c
        |   0   1   1   1
        |   1   1   1   1
        |   2   1   1   1
        |   3   1   1   1
        |   4   1   1   1
        |   5   1   1   1
        |   6   1   1   1
        |   7   1   1   1
        |   8   1   1   1
        |   9   1   1   1
        |  10   1   1   1
        |  11   1   1   1
        |  12   1   1   1
        |  13   1   1   1
        |  14   1   1   1
        | ... ... ... ...
       }.unindent}
    end

    context 'long data lines' do
      let(:df) { Daru::DataFrame.new({a: [1,2,3], b: [4,5,6], c: ['this is ridiculously long',nil,nil]}, name: 'test')}
      it { is_expected.to eq %Q{
        |#<Daru::DataFrame: test (3x3)>
        |                     a          b          c
        |          0          1          4 this is ri
        |          1          2          5        nil
        |          2          3          6        nil
       }.unindent}
    end

    context 'index is a MultiIndex' do
      let(:df) {
        Daru::DataFrame.new(
          {
            a:   [1,2,3,4,5,6,7],
            b: %w[a b c d e f g]
          }, index: Daru::MultiIndex.from_tuples([
                %w[foo one],
                %w[foo two],
                %w[foo three],
                %w[bar one],
                %w[bar two],
                %w[bar three],
                %w[baz one],
             ]),
             name: 'test'
        )
      }

      it { is_expected.to eq %Q{
        |#<Daru::DataFrame: test (7x2)>
        |                 a     b
        |   foo   one     1     a
        |         two     2     b
        |       three     3     c
        |   bar   one     4     d
        |         two     5     e
        |       three     6     f
        |   baz   one     7     g
      }.unindent}
    end

    context 'vectors is a MultiIndex' do
    end

    context 'spacing and threshold settings' do
    end
  end

  context '#to_s' do
    it 'produces a class, size description' do
      expect(@data_frame.to_s).to eq "#<Daru::DataFrame(5x3)>"
    end

    it 'produces a class, name, size description' do
      @data_frame.name = "Test"
      expect(@data_frame.to_s).to eq "#<Daru::DataFrame: Test(5x3)>"
    end

    it 'produces a class, name, size description when the name is a symbol' do
      @data_frame.name = :Test
      expect(@data_frame.to_s).to eq "#<Daru::DataFrame: Test(5x3)>"
    end
  end

  context '#to_json' do
    let(:df) { Daru::DataFrame.new({a: [1,2,3], b: [3,4,5], c: [6,7,8]}, index: [:one, :two, :three], name: 'test')}
    subject { JSON.parse(json) }

    context 'with index' do
      let(:json) { df.to_json(false) }
      # FIXME: is it most reasonable we can do?.. -- zverok
      # For me, more resonable thing would be something like
      #
      # [
      #   {"index" => "one"  , "a"=>1, "b"=>3, "c"=>6},
      #   {"index" => "two"  , "a"=>2, "b"=>4, "c"=>7},
      #   {"index" => "three", "a"=>3, "b"=>5, "c"=>8}
      # ]
      #
      # Or maybe
      #
      # [
      #   ["one"  , {"a"=>1, "b"=>3, "c"=>6}],
      #   ["two"  , {"a"=>2, "b"=>4, "c"=>7}],
      #   ["three", {"a"=>3, "b"=>5, "c"=>8}]
      # ]
      #
      # Or even
      #
      # {
      #   "one"   => {"a"=>1, "b"=>3, "c"=>6},
      #   "two"   => {"a"=>2, "b"=>4, "c"=>7},
      #   "three" => {"a"=>3, "b"=>5, "c"=>8}
      # }
      #
      it { is_expected.to eq(
        [
          [
            {"a"=>1, "b"=>3, "c"=>6},
            {"a"=>2, "b"=>4, "c"=>7},
            {"a"=>3, "b"=>5, "c"=>8}
          ],
          ["one", "two", "three"]
        ]
      )}
    end

    context 'without index' do
      let(:json) { df.to_json(true) }
      it { is_expected.to eq(
        [
          {"a"=>1, "b"=>3, "c"=>6},
          {"a"=>2, "b"=>4, "c"=>7},
          {"a"=>3, "b"=>5, "c"=>8}
        ]
      )}
    end
  end

  context '#aggregate' do
    let(:cat_idx) { Daru::CategoricalIndex.new [:a, :b, :a, :a, :c] }
    let(:df) { Daru::DataFrame.new(num: [52,12,07,17,01], cat_index: cat_idx) }
    let(:df_cat_idx) {
      Daru::DataFrame.new({num: [52,12,07,17,01]}, index: cat_idx) }

    it 'lambda function on particular column' do
      expect(df.aggregate(num_100_times: ->(df) { df.num*100 })).to eq(
          Daru::DataFrame.new(num_100_times: [5200, 1200, 700, 1700, 100])
        )
    end
    it 'aggregate sum on particular column' do
      expect(df_cat_idx.aggregate(num: :sum)).to eq(
          Daru::DataFrame.new({num: [76, 12, 1]}, index: [:a, :b, :c])
        )
    end
  end

  context '#create_sql' do
    let(:df) { Daru::DataFrame.new({
        a: [1,2,3],
        b: ['test', 'me', 'please'],
        c: ['2015-06-01', '2015-06-02', '2015-06-03']
      },
      name: 'test'
    )}
    subject { df.create_sql('foo') }
    it { is_expected.to eq %Q{
      |CREATE TABLE foo (a INTEGER,
      | b VARCHAR (255),
      | c DATE) CHARACTER SET=UTF8;
    }.unindent}
  end

  context "#by_single_key" do
    let(:df) { Daru::DataFrame.new(a: [1, 2, 3], b: [4, 5, 6] ) }

    it 'raise error when vector is missing from dataframe' do
      expect { df[:c] }.to raise_error(IndexError, /Specified vector c does not exist/)
    end
  end
end if mri?
