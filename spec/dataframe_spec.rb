require 'spec_helper.rb'

describe Daru::DataFrame do
  before :each do
    @data_frame = Daru::DataFrame.new({b: [11,12,13,14,15], a: [1,2,3,4,5], 
      c: [11,22,33,44,55]}, [:a, :b, :c], [:one, :two, :three, :four, :five])
  end

  context "#initialize" do
    it "initializes an empty DataFrame" do
      df = Daru::DataFrame.new({}, [:a, :b])

      expect(df.vectors).to eq(Daru::Index.new [:a, :b])
      expect(df.a.class).to eq(Daru::Vector)
      expect(df.a)      .to eq([].dv(:a)) 
    end

    it "initializes from a Hash" do
      df = Daru::DataFrame.new({b: [11,12,13,14,15], a: [1,2,3,4,5]}, [:a, :b],
        [:one, :two, :three, :four, :five])

      expect(df.index)  .to eq(Daru::Index.new [:one, :two, :three, :four, :five])
      expect(df.vectors).to eq(Daru::Index.new [:a, :b])
      expect(df.a.class).to eq(Daru::Vector)
      expect(df.a)      .to eq([1,2,3,4,5].dv(:a, df.index)) 
    end

    it "initializes from a Hash of Vectors", :focus => true do
      df = Daru::DataFrame.new({b: [11,12,13,14,15].dv(:b, [:one, :two, :three, :four, :five]), 
        a: [1,2,3,4,5].dv(:a, [:one, :two, :three, :four, :five])}, [:a, :b],
        [:one, :two, :three, :four, :five])

      expect(df.index)  .to eq(Daru::Index.new [:one, :two, :three, :four, :five])
      expect(df.vectors).to eq(Daru::Index.new [:a, :b])
      expect(df.a.class).to eq(Daru::Vector)
      expect(df.a)      .to eq([1,2,3,4,5].dv(:a, [:one, :two, :three, :four, :five])) 
    end

    it "initializes from an Array of Hashes" do
      df = Daru::DataFrame.new([{a: 1, b: 11}, {a: 2, b: 12}, {a: 3, b: 13},
        {a: 4, b: 14}, {a: 5, b: 15}], [:b, :a], [:one, :two, :three, :four, :five])

      expect(df.index)  .to eq(Daru::Index.new [:one, :two, :three, :four, :five])
      expect(df.vectors).to eq(Daru::Index.new [:b, :a])
      expect(df.a.class).to eq(Daru::Vector)
      expect(df.a)      .to eq([1,2,3,4,5].dv(:a,[:one, :two, :three, :four, :five])) 
    end

    it "accepts Index objects for row/col" do
      rows = Daru::Index.new [:one, :two, :three, :four, :five]
      cols = Daru::Index.new [:a, :b]

      df  = Daru::DataFrame.new({b: [11,12,13,14,15], a: [1,2,3,4,5]}, cols, rows)

      expect(df.a)      .to eq(Daru::Vector.new(:a, [1,2,3,4,5]     , rows))
      expect(df.b)      .to eq(Daru::Vector.new(:b, [11,12,13,14,15], rows))
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
          [:a, :b]
        )

      expect(df).to eq(Daru::DataFrame.new({
          b: [14,13,12,15,11].dv(:b, [:five, :four, :one, :three, :two]), 
          a:      [5,4,2,3,1].dv(:a, [:five, :four, :one, :three, :two])
        }, [:a, :b])
      )
    end

    it "adds nil values for missing indexes and aligns by index" do
      df = Daru::DataFrame.new({
               b: [11,12,13,14,15].dv(:b, [:two, :one, :four, :five, :three]), 
               a: [1,2,3]         .dv(:a, [:two,:one,:three])
             }, 
             [:a, :b]
           )

      expect(df).to eq(Daru::DataFrame.new({
          b: [14,13,12,15,11].dv(:b, [:five, :four, :one, :three, :two]), 
          a:  [nil,nil,2,3,1].dv(:a, [:five, :four, :one, :three, :two])
        }, 
        [:a, :b])
      )
    end

    it "adds nils in first vector when other vectors have many extra indexes" do
      df = Daru::DataFrame.new({
          b: [11]                .dv(nil, [:one]), 
          a: [1,2,3]             .dv(nil, [:one, :two, :three]), 
          c: [11,22,33,44,55]    .dv(nil, [:one, :two, :three, :four, :five]),
          d: [49,69,89,99,108,44].dv(nil, [:one, :two, :three, :four, :five, :six])
        }, [:a, :b, :c, :d], [:one, :two, :three, :four, :five, :six])

      expect(df).to eq(Daru::DataFrame.new({
          b: [11,nil,nil,nil,nil,nil].dv(nil, [:one, :two, :three, :four, :five, :six]), 
          a: [1,2,3,nil,nil,nil]     .dv(nil, [:one, :two, :three, :four, :five, :six]), 
          c: [11,22,33,44,55,nil]    .dv(nil, [:one, :two, :three, :four, :five, :six]),
          d: [49,69,89,99,108,44]    .dv(nil, [:one, :two, :three, :four, :five, :six])
        }, [:a, :b, :c, :d], [:one, :two, :three, :four, :five, :six])
      )
    end

    it "correctly matches the supplied DataFrame index with the individual vector indexes" do
      df = Daru::DataFrame.new({
          b: [11,12,13] .dv(nil, [:one, :bleh, :blah]), 
          a: [1,2,3,4,5].dv(nil, [:one, :two, :booh, :baah, :three]), 
          c: [11,22,33,44,55].dv(nil, [0,1,3,:three, :two])
        }, [:a, :b, :c], [:one, :two, :three])

      expect(df).to eq(Daru::DataFrame.new({
          b: [11,nil,nil].dv(nil, [:one, :two, :three]),
          a: [1,2,5]     .dv(nil, [:one, :two, :three]),
          c: [nil,55,44] .dv(nil, [:one, :two, :three]),
        },  
        [:a, :b, :c], [:one, :two, :three]
        )
      )
    end

    it "completes incomplete vectors" do
      df = Daru::DataFrame.new({b: [11,12,13,14,15], a: [1,2,3,4,5], 
        c: [11,22,33,44,55]}, [:a, :c])

      expect(df.vectors).to eq([:a,:c,:b].to_index)
    end

    it "raises error for incomplete DataFrame index" do
      expect {
        df = Daru::DataFrame.new({b: [11,12,13,14,15], a: [1,2,3,4,5], 
          c: [11,22,33,44,55]}, [:a, :b, :c], [:one, :two, :three])
      }.to raise_error
    end

    it "raises error for unequal sized vectors/arrays" do
      expect {
        df = Daru::DataFrame.new({b: [11,12,13], a: [1,2,3,4,5], 
          c: [11,22,33,44,55]}, [:a, :b, :c], [:one, :two, :three])
      }.to raise_error
    end
  end

  context "#[:vector]" do
    before :each do
      @df = Daru::DataFrame.new({b: [11,12,13,14,15], a: [1,2,3,4,5], 
        c: [11,22,33,44,55]}, [:a, :b, :c], [:one, :two, :three, :four, :five])
    end

    it "returns a Vector" do
      expect(@df[:a, :vector]).to eq([1,2,3,4,5].dv(:a, [:one, :two, :three, :four, :five]))
    end

    it "returns a DataFrame" do
      temp = Daru::DataFrame.new({b: [11,12,13,14,15], a: [1,2,3,4,5]}, 
        [:a, :b], [:one, :two, :three, :four, :five])

      expect(@df[:a, :b, :vector]).to eq(temp)
    end

    it "accesses vector with Integer index" do
      expect(@df[0, :vector]).to eq([1,2,3,4,5].dv(:a, [:one, :two, :three, :four, :five]))
    end
  end

  context "#[:row]" do
    before :each do
      @df = Daru::DataFrame.new({b: [11,12,13,14,15], a: [1,2,3,4,5], 
        c: [11,22,33,44,55]}, [:a, :b, :c], [:one, :two, :three, :four, :five])
    end

    it "returns a row with the given index" do
      expect(@df[:one, :row]).to eq([1,11,11].dv(:one, [:a, :b, :c]))
    end

    it "returns a row with given Integer index" do
      expect(@df[0, :row]).to eq([1,11,11].dv(:one, [:a, :b, :c]))
    end

    it "returns a row with given Integer index for default index-less DataFrame" do
      df = Daru::DataFrame.new({b: [11,12,13,14,15], a: [1,2,3,4,5], 
        c: [11,22,33,44,55]}, [:a, :b, :c])

      expect(df[0, :row]).to eq([1,11,11].dv(nil, [:a, :b, :c]))
    end
  end

  context "#[:vector]=" do
    before :each do
      @df = Daru::DataFrame.new({b: [11,12,13,14,15], a: [1,2,3,4,5], 
        c: [11,22,33,44,55]}, [:a, :b, :c], [:one, :two, :three, :four, :five])
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
      pending "Implement after initialize with array of arrays is done with."

      # Rudimentary example. Yet to think this out.

      @df[:woo, :boo, :vector] = [[69,99,108,85,49].dv(nil, [:one, :two, :three, :four, :five]), 
                         [69,99,108,85,49].dv(nil, [:one, :two, :three, :four, :five])]
    end
  end

  context "#[:row]=" do
    before :each do
      @df = Daru::DataFrame.new({b: [11,12,13,14,15], a: [1,2,3,4,5], 
        c: [11,22,33,44,55]}, [:a, :b, :c], [:one, :two, :three, :four, :five])
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

    it "returns a DataFrame when mutiple indexes specified" do
      pending "Next release"

      raise
    end
  end

  context "#row" do
    before :each do
      @df = Daru::DataFrame.new({b: [11,12,13,14,15], a: [1,2,3,4,5], 
        c: [11,22,33,44,55]}, [:a, :b, :c], [:one, :two, :three, :four, :five])
    end

    it "creates an index for assignment if not already specified" do
      @df.row[:one] = [49, 99, 59]

      expect(@df[:one, :row])      .to eq([49, 99, 59].dv(:one, [:a, :b, :c]))
      expect(@df[:one, :row].index).to eq([:a, :b, :c].to_index)
      expect(@df[:one, :row].name) .to eq(:one)
    end
  end

  context "#vector" do
    it "appends an Array as a Daru::Vector" do
      @data_frame[:d, :vector] = [69,99,108,85,49]

      expect(@data_frame.d.class).to eq(Daru::Vector)
    end
  end

  context "#==" do
    it "compares by vectors, index and values of a DataFrame (ignores name)" do
      a = Daru::DataFrame.new({b: [11,12,13,14,15], a: [1,2,3,4,5]}, 
        [:a, :b], [:one, :two, :three, :four, :five])

      b = Daru::DataFrame.new({b: [11,12,13,14,15], a: [1,2,3,4,5]}, 
        [:a, :b], [:one, :two, :three, :four, :five])

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
    it "iterates over all vectors" do
      ret = @data_frame.each_vector do |vector|
        expect(vector.index).to eq([:one, :two, :three, :four, :five].to_index)
        expect(vector.class).to eq(Daru::Vector) 
      end

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
      c: [21,32,43,54,65]}, [:a, :b, :c], [:one, :two, :three, :four, :five])

      ret = @data_frame.map_vectors do |vector|
        vector = vector.map { |e| e += 10}
      end

      expect(ret).to eq(ans)
      expect(ret == @data_frame).to eq(false)
    end
  end

  context "#map_vectors_with_index" do
    it "iterates over vectors with index and returns a modified DataFrame" do
      ans = Daru::DataFrame.new({b: [21,22,23,24,25], a: [11,12,13,14,15], 
      c: [21,32,43,54,65]}, [:a, :b, :c], [:one, :two, :three, :four, :five])

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
        c: [121, 484, 1089, 1936, 3025]}, [:a, :b, :c], [:one, :two, :three, :four, :five])

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
        c: [121, 484, 1089, 1936, 3025]}, [:a, :b, :c], [:one, :two, :three, :four, :five])

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
    it "deletes the specified vector" do
      @data_frame.delete_vector :a

      expect(@data_frame).to eq(Daru::DataFrame.new({b: [11,12,13,14,15], 
              c: [11,22,33,44,55]}, [:b, :c], [:one, :two, :three, :four, :five]))    
    end
  end

  context "#delete_row" do
    it "deletes the specified row" do
      @data_frame.delete_row :one

      expect(@data_frame).to eq(Daru::DataFrame.new({b: [12,13,14,15], a: [2,3,4,5], 
      c: [22,33,44,55]}, [:a, :b, :c], [:two, :three, :four, :five]))
    end
  end

  context "#keep_row_if", :focus => true do
    it "keeps row if block evaluates to true" do
      df = Daru::DataFrame.new({b: [10,12,20,23,30], a: [50,30,30,1,5], 
        c: [10,20,30,40,50]}, [:a, :b, :c], [:one, :two, :three, :four, :five])

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

      expect(@data_frame).to eq(Daru::DataFrame.new({a: [1,2,3,4,5]}, [:a], 
        [:one, :two, :three, :four, :five]))
    end
  end

  context "#filter_rows" do
    it "filters rows" do
      df = Daru::DataFrame.new({a: [1,2,3], b: [2,3,4]})

      a = df.filter_rows do |row|
        row[:a] % 2 == 0
      end

      expect(a).to eq(Daru::DataFrame.new({a: [2], b: [3]}, [:a, :b], [1]))
    end
  end

  context "#filter_vectors" do
    it "filters vectors" do
      df = Daru::DataFrame.new({a: [1,2,3], b: [2,3,4]})

      a = df.filter_vectors do |vector|
        vector[0] == 1
      end

      expect(a).to eq(Daru::DataFrame.new({a: [1,2,3]}))
    end
  end

  context "#to_a" do
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
end if mri?