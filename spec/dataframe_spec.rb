require 'spec_helper.rb'

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
    @multi_index = Daru::MultiIndex.new(tuples)
    @vector_arry1 = [11,12,13,14,11,12,13,14,11,12,13,14]
    @vector_arry2 = [1,2,3,4,1,2,3,4,1,2,3,4]
    @order_mi = Daru::MultiIndex.new([
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
        expect(df.vector[:a]) .to eq(Daru::Vector.new [1,1,1,1])
      end

      it "creates a DataFrame from Vector rows" do
        rows = @rows.map { |r| Daru::Vector.new r, index: [:a,:b,:c,:d,:e] }

        df = Daru::DataFrame.rows rows, order: [:a,:b,:c,:d,:e]

        expect(df.index)      .to eq(Daru::Index.new [0,1,2,3])
        expect(df.vectors)    .to eq(Daru::Index.new [:a,:b,:c,:d,:e])
        expect(df.vector[:a]) .to eq(Daru::Vector.new [1,1,1,1])
      end
    end

    context Daru::MultiIndex do
      it "creates a DataFrame from rows" do
        df = Daru::DataFrame.new(@rows*3, index: @multi_index, order: [:a,:b,:c,:d,:e])

        expect(df.index).to eq(@multi_index)
        expect(df.vectors).to eq(Daru::Index.new([:a,:b,:c,:d,:e]))
        expect(df.vector[:a]).to eq(Daru::Vector.new([1]*12, index: @multi_index))
      end

      it "creates a DataFrame from Vector rows" do
        rows = @rows*3
        rows.map! { |r| Daru::Vector.new(r, index: @multi_index) }

        df = Daru::DataFrame.rows rows, order: @multi_index

        expect(df.index).to eq(Daru::Index.new(Array.new(rows.size) { |i| i }))
        expect(df.vectors).to eq(@multi_index)
        expect(df.vector[:a,:one,:bar]).to eq(Daru::Vector.new([1]*12))
      end
    end
  end

  context "#initialize" do
    context Daru::Index do
      it "initializes an empty DataFrame" do
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

      it "initializes from a Hash of Vectors" do
        df = Daru::DataFrame.new({b: [11,12,13,14,15].dv(:b, [:one, :two, :three, :four, :five]), 
          a: [1,2,3,4,5].dv(:a, [:one, :two, :three, :four, :five])}, order: [:a, :b],
          index: [:one, :two, :three, :four, :five])

        expect(df.index)  .to eq(Daru::Index.new [:one, :two, :three, :four, :five])
        expect(df.vectors).to eq(Daru::Index.new [:a, :b])
        expect(df.a.class).to eq(Daru::Vector)
        expect(df.a)      .to eq([1,2,3,4,5].dv(:a, [:one, :two, :three, :four, :five])) 
      end

      it "initializes from an Array of Hashes" do
        df = Daru::DataFrame.new([{a: 1, b: 11}, {a: 2, b: 12}, {a: 3, b: 13},
          {a: 4, b: 14}, {a: 5, b: 15}], order: [:b, :a], 
          index: [:one, :two, :three, :four, :five])

        expect(df.index)  .to eq(Daru::Index.new [:one, :two, :three, :four, :five])
        expect(df.vectors).to eq(Daru::Index.new [:b, :a])
        expect(df.a.class).to eq(Daru::Vector)
        expect(df.a)      .to eq([1,2,3,4,5].dv(:a,[:one, :two, :three, :four, :five])) 
      end

      it "initializes from Array of Arrays" do
        df = Daru::DataFrame.new([[1]*5, [2]*5, [3]*5], order: [:b, :a, :c])

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
        expect(df.vectors).to eq(Daru::Index.new [:a, :b])
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
        expect(df.vector[:a, :one, :bar]).to eq(Daru::Vector.new([]))
      end

      it "creates from Hash", focus: true do
        df = Daru::DataFrame.new({
          [:a,:one,:bar] => @vector_arry1, 
          [:a,:two,:baz] => @vector_arry2, 
          [:b,:one,:foo] => @vector_arry1, 
          [:b,:two,:foo] => @vector_arry2
          }, order: @order_mi, index: @multi_index)

        expect(df.index)               .to eq(@multi_index)
        expect(df.vectors)             .to eq(@order_mi)
        expect(df.vector[:a,:one,:bar]).to eq(Daru::Vector.new(@vector_arry1, 
          index: @multi_index))
      end

      it "creates from Array of Hashes" do
        pending
      end

      it "creates from Array of Arrays" do
        df = Daru::DataFrame.new([@vector_arry1, @vector_arry2, @vector_arry1, 
          @vector_arry2], index: @multi_index, order: @order_mi)

        expect(df.index)  .to eq(@multi_index)
        expect(df.vectors).to eq(@order_mi)
        expect(df.vector[:a, :one, :bar]).to eq(Daru::Vector.new(@vector_arry1, 
          index: @multi_index))
      end

      it "raises error for order MultiIndex of different size than supplied Array" do
        expect {
          df = Daru::DataFrame.new([@vector_arry1, @vector_arry2], order: @order_mi,
            index: @multi_index)
        }.to raise_error
      end

      it "aligns MultiIndexes properly" do
        mi_a = @order_mi
        mi_b = Daru::MultiIndex.new([
          [:b,:one,:foo],
          [:a,:one,:bar],
          [:b,:two,:foo],
          [:a,:one,:baz]
        ])
        mi_sorted = Daru::MultiIndex.new([
          [:a, :one, :bar], 
          [:a, :one, :baz], 
          [:b, :one, :foo], 
          [:b, :two, :foo]
        ])
        order = Daru::MultiIndex.new([
          [:pee, :que],
          [:pee, :poo]
        ])
        a  = Daru::Vector.new([1,2,3,4], index: mi_a)
        b  = Daru::Vector.new([11,12,13,14], index: mi_b)
        df = Daru::DataFrame.new({b: b, a: a}, order: order)

        expect(df).to eq(Daru::DataFrame.new({
          [:pee, :que] => Daru::Vector.new([1,2,4,3], index: mi_sorted),
          [:pee, :poo] => Daru::Vector.new([12,14,11,13], index: mi_sorted)
          }, order: order_mi))
      end

      it "adds nils in case of missing values" do
        pending
      end

      it "matches individual vector indexing with supplied DataFrame index" do
        pending
      end
    end
  end

  context "#[:vector]" do
    context Daru::Index do
      before :each do
        @df = Daru::DataFrame.new({b: [11,12,13,14,15], a: [1,2,3,4,5], 
          c: [11,22,33,44,55]}, order: [:a, :b, :c], 
          index: [:one, :two, :three, :four, :five])
      end

      it "returns a Vector" do
        expect(@df[:a, :vector]).to eq([1,2,3,4,5].dv(:a, [:one, :two, :three, :four, :five]))
      end

      it "returns a DataFrame" do
        temp = Daru::DataFrame.new({b: [11,12,13,14,15], a: [1,2,3,4,5]}, 
          order: [:a, :b], index: [:one, :two, :three, :four, :five])

        expect(@df[:a, :b, :vector]).to eq(temp)
      end

      it "accesses vector with Integer index" do
        expect(@df[0, :vector]).to eq([1,2,3,4,5].dv(:a, [:one, :two, :three, :four, :five]))
      end
    end

    context Daru::MultiIndex do
      # See #vector
    end
  end

  context "#[:row]" do
    context Daru::Index do
      before :each do
        @df = Daru::DataFrame.new({b: [11,12,13,14,15], a: [1,2,3,4,5], 
          c: [11,22,33,44,55]}, 
          order: [:a, :b, :c], 
          index: [:one, :two, :three, :four, :five])
      end

      it "returns a row with the given index" do
        expect(@df[:one, :row]).to eq([1,11,11].dv(:one, [:a, :b, :c]))
      end

      it "returns a row with given Integer index" do
        expect(@df[0, :row]).to eq([1,11,11].dv(:one, [:a, :b, :c]))
      end

      it "returns a row with given Integer index for default index-less DataFrame" do
        df = Daru::DataFrame.new({b: [11,12,13,14,15], a: [1,2,3,4,5], 
          c: [11,22,33,44,55]}, order: [:a, :b, :c])

        expect(df[0, :row]).to eq([1,11,11].dv(nil, [:a, :b, :c]))
      end
    end

    context Daru::MultiIndex do
      # See #row
    end
  end

  context "#[:vector]=" do
    context Daru::Index do
      before :each do
        @df = Daru::DataFrame.new({b: [11,12,13,14,15], a: [1,2,3,4,5], 
          c: [11,22,33,44,55]}, order: [:a, :b, :c], 
          index: [:one, :two, :three, :four, :five])
      end

      it "appends an Array as a Daru::Vector" do
        @df[:d, :vector] = [69,99,108,85,49]

        expect(@df.d.class).to eq(Daru::Vector)
      end

      it "replaces an already present vector" do
        @df[:a, :vector] = [69,99,108,85,49].dv(nil, [:one, :two, :three, :four, :five])

        expect(@df.a).to eq([69,99,108,85,49].dv(nil, [:one, :two, :three, :four, :five]))
      end

      it "appends a new vector to the DataFrame" do
        @df[:woo, :vector] = [69,99,108,85,49].dv(nil, [:one, :two, :three, :four, :five])

        expect(@df.vectors).to eq([:a, :b, :c, :woo].to_index)
      end

      it "creates an index for the new vector if not specified" do
        @df[:woo, :vector] = [69,99,108,85,49]

        expect(@df.woo.index).to eq([:one, :two, :three, :four, :five].to_index)
      end   

      it "matches index of vector to be inserted with the DataFrame index" do
        @df[:shankar, :vector] = [69,99,108,85,49].dv(:shankar, [:two, :one, :three, :five, :four])

        expect(@df.shankar).to eq([99,69,108,49,85].dv(:shankar, 
          [:one, :two, :three, :four, :five]))
      end

      it "matches index of vector to be inserted, inserting nils where no match found" do
        @df.vector[:shankar] = [1,2,3].dv(:shankar, [:one, :james, :hetfield])

        expect(@df.shankar).to eq([1,nil,nil,nil,nil].dv(:shankar, [:one, :two, :three, :four, :five]))
      end

      it "raises error for Array assignment of wrong length" do
        expect{
          @df.vector[:shiva] = [1,2,3]
          }.to raise_error
      end

      it "appends multiple vectors at a time" do
        pending
      end
    end
    
    context Daru::MultiIndex do
      pending
    end
  end

  context "#[:row]=" do
    context Daru::Index do
      before :each do
        @df = Daru::DataFrame.new({b: [11,12,13,14,15], a: [1,2,3,4,5], 
          c: [11,22,33,44,55]}, order: [:a, :b, :c], 
          index: [:one, :two, :three, :four, :five])
      end

      it "assigns specified row when Array" do
        @df.row[:one] = [49, 99, 59]

        expect(@df[:one, :row])      .to eq([49, 99, 59].dv(:one, [:a, :b, :c]))
        expect(@df[:one, :row].index).to eq([:a, :b, :c].to_index)
        expect(@df[:one, :row].name) .to eq(:one)
      end

      it "assigns specified row when DV" do
        @df[:one, :row] = [49, 99, 59].dv(nil, [:a, :b, :c])

        expect(@df[:one, :row]).to eq([49, 99, 59].dv(:one, [:a, :b, :c]))
      end

      it "creates a new row from an Array" do
        @df.row[:patekar] = [9,2,11]

        expect(@df[:patekar, :row]).to eq([9,2,11].dv(:patekar, [:a, :b, :c]))
      end

      it "creates a new row from a DV" do
        @df.row[:patekar] = [9,2,11].dv(nil, [:a, :b, :c])

        expect(@df[:patekar, :row]).to eq([9,2,11].dv(:patekar, [:a, :b, :c]))
      end

      it "creates a new row from numeric row index and named DV" do
        @df.row[2] = [9,2,11].dv(nil, [:a, :b, :c])

        expect(@df[2, :row]).to eq([9,2,11].dv(nil, [:a, :b, :c]))
      end

      it "correctly aligns assigned DV by index" do
        @df.row[:two] = [9,2,11].dv(nil, [:b, :a, :c])
        
        expect(@df.row[:two]).to eq([2,9,11].dv(:two, [:a, :b, :c]))
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
    end
  end

  context "#row" do
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
    end

    context Daru::MultiIndex do
      it "returns a Vector when specifying integer index" do
        expect(@df_mi.row[0]).to eq(Daru::Vector.new([11,1,11,1], index: @order_mi))
      end

      it "returns a DataFrame when specifying numeric range" do
        sub_index = Daru::MultiIndex.new([
          [:a,:one,:bar],
          [:a,:one,:baz],
          [:a,:two,:bar],
          [:a,:two,:baz],
          [:b,:one,:bar],
          [:b,:two,:bar],
          [:b,:two,:baz],
          [:b,:one,:foo]
        ])

        expect(@df_mi.row[0..1]).to eq(Daru::DataFrame.new([
          [11,12,13,14,11,12,13,14],
          [1,2,3,4,1,2,3,4],
          [11,12,13,14,11,12,13,14],
          [1,2,3,4,1,2,3,4]
        ], order: @order_mi, index: sub_index, name: :numeric_range))
      end

      it "returns a Vector when specifying complete tuple" do
        expect(@df_mi.row[:c,:two,:foo]).to eq(Daru::Vector.new([13,3,13,3], index: @order_mi))
      end

      it "returns DataFrame when specifying first layer of MultiIndex" do
        sub_index = Daru::MultiIndex.new([
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

      it "returns DataFrame when specifying first and layer of MultiIndex" do
        sub_index = Daru::MultiIndex.new([
          [:bar],
          [:baz]
        ])
        expect(@df_mi.row[:c,:one]).to eq(Daru::DataFrame.new([
          [11,12,13,14],
          [1,2,3,4]
        ], index: sub_index, order: @order_mi))
      end
    end
  end

  context "#vector" do
    context Daru::Index do
      it "appends an Array as a Daru::Vector" do
        @data_frame[:d, :vector] = [69,99,108,85,49]

        expect(@data_frame.d.class).to eq(Daru::Vector)
      end
    end

    context Daru::MultiIndex do
      it "accesses vector with an integer index" do
        expect(@df_mi.vector[0]).to eq(Daru::Vector.new(@vector_arry1,
          index: @multi_index))
      end

      it "returns a vector when specifying full tuple" do
        expect(@df_mi.vector[:a, :one, :bar]).to eq(Daru::Vector.new(@vector_arry1,
          index: @multi_index))
      end

      it "returns DataFrame when specified first layer of MultiIndex" do
        sub_order = Daru::MultiIndex.new([
          [:one, :bar],
          [:two, :baz]
          ])
        expect(@df_mi.vector[:a]).to eq(Daru::DataFrame.new([
          @vector_arry1,
          @vector_arry2
        ], index: @multi_index, order: sub_order))
      end

      it "returns DataFrame when specified first and second layer of MultiIndex" do
        sub_order = Daru::MultiIndex.new([
          [:bar]
        ])
        expect(@df_mi.vector[:a, :one]).to eq(Daru::DataFrame.new([
          @vector_arry1
        ], index: @multi_index, order: sub_order))
      end
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

  context "#dup" do
    it "dups every data structure inside DataFrame" do
      clo = @data_frame.dup

      expect(clo.object_id)        .not_to eq(@data_frame.object_id)
      expect(clo.vectors.object_id).not_to eq(@data_frame.object_id)
      expect(clo.index.object_id)  .not_to eq(@data_frame.object_id)

      @data_frame.each_vector_with_index do |vector, index|
        expect(vector.object_id).not_to eq(clo.vector[index].object_id)
      end
    end
  end

  context "#each_vector" do
    context Daru::Index do
      it "iterates over all vectors" do
        ret = @data_frame.each_vector do |vector|
          expect(vector.index).to eq([:one, :two, :three, :four, :five].to_index)
          expect(vector.class).to eq(Daru::Vector) 
        end

        expect(ret).to eq(@data_frame)
      end
    end

    context Daru::MultiIndex do

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

  context "#each_row" do
    it "iterates over rows" do
      ret = @data_frame.each_row do |row|
        expect(row.index).to eq([:a, :b, :c].to_index)
        expect(row.class).to eq(Daru::Vector)
      end

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

  context "#map_vectors" do
    it "iterates over vectors and returns a modified DataFrame" do
      ans = Daru::DataFrame.new({b: [21,22,23,24,25], a: [11,12,13,14,15], 
      c: [21,32,43,54,65]}, order: [:a, :b, :c], 
      index: [:one, :two, :three, :four, :five])

      ret = @data_frame.map_vectors do |vector|
        vector = vector.map { |e| e += 10}
      end

      expect(ret).to eq(ans)
      expect(ret == @data_frame).to eq(false)
    end
  end

  context "#map_vectors!" do
    it "maps vectors (bang)" do
      ans = Daru::DataFrame.new({b: [21,22,23,24,25], a: [11,12,13,14,15], 
        c: [21,32,43,54,65]}, order: [:a, :b, :c], 
        index: [:one, :two, :three, :four, :five])

      @data_frame.map_vectors! do |vector|
        vector.map! { |e| e += 10}
      end

      expect(@data_frame).to eq(ans)
    end
  end

  context "#map_vectors_with_index" do
    it "iterates over vectors with index and returns a modified DataFrame" do
      ans = Daru::DataFrame.new({b: [21,22,23,24,25], a: [11,12,13,14,15], 
      c: [21,32,43,54,65]}, order: [:a, :b, :c], 
      index: [:one, :two, :three, :four, :five])

      idx = []
      ret = @data_frame.map_vectors_with_index do |vector, index|
        idx << index
        vector = vector.map { |e| e += 10}
      end

      expect(ret).to eq(ans)
      expect(idx).to eq([:a, :b, :c])
    end
  end

  context "#map_rows" do
    it "iterates over rows and returns a modified DataFrame" do
      ans = Daru::DataFrame.new({b: [121, 144, 169, 196, 225], a: [1,4,9,16,25], 
        c: [121, 484, 1089, 1936, 3025]}, order: [:a, :b, :c], 
        index: [:one, :two, :three, :four, :five])

      ret = @data_frame.map_rows do |row|
        expect(row.class).to eq(Daru::Vector)
        row = row.map { |e| e*e }
      end

      expect(ret).to eq(ans)
    end
  end

  context "#map_rows_with_index" do
    it "iterates over rows with index and returns a modified DataFrame" do
      ans = Daru::DataFrame.new({b: [121, 144, 169, 196, 225], a: [1,4,9,16,25], 
        c: [121, 484, 1089, 1936, 3025]},order: [:a, :b, :c], 
        index: [:one, :two, :three, :four, :five])

      idx = []
      ret = @data_frame.map_rows_with_index do |row, index|
        idx << index
        expect(row.class).to eq(Daru::Vector)
        row = row.map { |e| e*e }
      end

      expect(ret).to eq(ans)
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

    context Daru::MultiIndex do
      pending
    end
  end

  context "#delete_row" do
    it "deletes the specified row" do
      @data_frame.delete_row :one

      expect(@data_frame).to eq(Daru::DataFrame.new({b: [12,13,14,15], a: [2,3,4,5], 
      c: [22,33,44,55]}, order: [:a, :b, :c], index: [:two, :three, :four, :five]))
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

  context "#filter_rows" do
    context Daru::Index do
      it "filters rows" do
        df = Daru::DataFrame.new({a: [1,2,3], b: [2,3,4]})

        a = df.filter_rows do |row|
          row[:a] % 2 == 0
        end

        expect(a).to eq(Daru::DataFrame.new({a: [2], b: [3]}, order: [:a, :b], index: [1]))
      end
    end

    context Daru::MultiIndex do
      pending
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

    context Daru::MultiIndex do
      pending
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
        a_sorter = lambda { |a,b| a <=> b }
        ans = @df.sort([:a], by: { a: a_sorter })

        expect(ans).to eq(
          Daru::DataFrame.new({a: [-6,1,5,5,5,7], b: [5,-1,9,1,-2,3], c: ['aaa','aa','aaaaa','aaaaaa','a','aaaa']}, 
            index: [2,1,4,5,0,3])
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
  end

  context "#sort!" do
    context Daru::Index do
      before :each do
        @df = Daru::DataFrame.new({a: [5,1,-6,7,5,5], b: [-2,-1,5,3,9,1], c: ['a','aa','aaa','aaaa','aaaaa','aaaaaa']})
      end

      it "sorts according to given vector order (bang)" do
        a_sorter = lambda { |a,b| a <=> b }

        expect(@df.sort!([:a], by: { a: a_sorter })).to eq(
          Daru::DataFrame.new({a: [-6,1,5,5,5,7], b: [5,-1,9,1,-2,3], c: ['aaa','aa','aaaaa','aaaaaa','a','aaaa']}, 
            index: [2,1,4,5,0,3])
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
    end
    
    context Daru::MultiIndex do
      pending "do this ASAP"
    end
  end 

  context "#reindex" do
    it "sets a new sequential index for DF and its underlying vectors" do
      a = @data_frame.reindex(:seq)

      expect(a).to eq(Daru::DataFrame.new({b: [11,12,13,14,15], 
        a: [1,2,3,4,5], c: [11,22,33,44,55]}, order: [:a, :b, :c]))
      expect(a).to_not eq(@data_frame)

      expect(a.a.index).to eq(Daru::Index.new(5))
      expect(a.b.index).to eq(Daru::Index.new(5))
      expect(a.c.index).to eq(Daru::Index.new(5))
    end

    it "sets a new index for the data frame and its underlying vectors" do
      a = @data_frame.reindex([:a,:b,:c,:d,:e])

      expect(a).to eq(Daru::DataFrame.new(
        {b: [11,12,13,14,15], a: [1,2,3,4,5], c: [11,22,33,44,55]}, 
        order: [:a, :b, :c], index: [:a,:b,:c,:d,:e]))
      expect(a).to_not eq(@data_frame)

      expect(a.a.index).to eq(Daru::Index.new([:a,:b,:c,:d,:e]))
      expect(a.b.index).to eq(Daru::Index.new([:a,:b,:c,:d,:e]))
      expect(a.c.index).to eq(Daru::Index.new([:a,:b,:c,:d,:e]))
    end
  end

  context "#reindex!" do
    context Daru::Index do
      it "sets a new sequential index for DF and its underlying vectors" do
        expect(@data_frame.reindex!(:seq)).to eq(Daru::DataFrame.new({b: [11,12,13,14,15], 
          a: [1,2,3,4,5], c: [11,22,33,44,55]}, order: [:a, :b, :c]))
        expect(@data_frame.a.index).to eq(Daru::Index.new(5))
        expect(@data_frame.b.index).to eq(Daru::Index.new(5))
        expect(@data_frame.c.index).to eq(Daru::Index.new(5))
      end

      it "sets a new index for the data frame and its underlying vectors" do
        expect(@data_frame.reindex!([:a,:b,:c,:d,:e])).to eq(Daru::DataFrame.new(
          {b: [11,12,13,14,15], a: [1,2,3,4,5], c: [11,22,33,44,55]}, 
          order: [:a, :b, :c], index: [:a,:b,:c,:d,:e]))
        expect(@data_frame.a.index).to eq(Daru::Index.new([:a,:b,:c,:d,:e]))
        expect(@data_frame.b.index).to eq(Daru::Index.new([:a,:b,:c,:d,:e]))
        expect(@data_frame.c.index).to eq(Daru::Index.new([:a,:b,:c,:d,:e]))
      end  
    end

    context Daru::MultiIndex do
      pending "do this ASAP"
    end  
  end
end if mri?