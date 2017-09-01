describe Daru::IO do
  describe Daru::DataFrame do
    context "Marshalling" do
      it "" do
        vector = Daru::Vector.new (0..100).collect { |_n| rand(100) }
        dataframe = Daru::Vector.new({a: vector, b: vector, c: vector})
        expect(Marshal.load(Marshal.dump(dataframe))).to eq(dataframe)
      end
    end

    context "#save" do
      before do
        @data_frame = Daru::DataFrame.new({b: [11,12,13,14,15], a: [1,2,3,4,5],
          c: [11,22,33,44,55]},
          order: [:a, :b, :c],
          index: [:one, :two, :three, :four, :five])
      end

      it "saves df to a file" do
        outfile = Tempfile.new('dataframe.df')
        @data_frame.save(outfile.path)
        a = Daru::IO.load(outfile.path)
        expect(a).to eq(@data_frame)
      end
    end
  end

  describe Daru::Vector do
    context "Marshalling" do
      it "" do
        vector = Daru::Vector.new (0..100).collect { |_n| rand(100) }
        expect(Marshal.load(Marshal.dump(vector))).to eq(vector)
      end
    end

    context "#save" do
      ALL_DTYPES.each do |dtype|
        it "saves to a file and returns the same Vector of type #{dtype}" do
          vector = Daru::Vector.new(
              [5, 5, 5, 5, 5, 6, 6, 7, 8, 9, 10, 1, 2, 3, 4, 11, -99, -99],
              dtype: dtype)
          outfile = Tempfile.new('vector.vec')
          vector.save(outfile.path)
          expect(Daru::IO.load(outfile.path)).to eq(vector)
        end
      end
    end
  end

  describe Daru::Index do
    context "Marshalling" do
      it "" do
        i = Daru::Index.new([:a, :b, :c, :d, :e])
        expect(Marshal.load(Marshal.dump(i))).to eq(i)
      end
    end
  end
end
