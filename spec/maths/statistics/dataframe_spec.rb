describe Daru::DataFrame do
  before do
    @df = Daru::DataFrame.new({
      a: ['foo'  ,  'foo',  'foo',  'foo',  'foo',  'bar',  'bar',  'bar',  'bar'],
      b: ['one'  ,  'one',  'one',  'two',  'two',  'one',  'one',  'two',  'two'],
      c: ['small','large','large','small','small','large','small','large','small'],
      d: [1,2,2,3,3,4,5,6,7],
      e: [2,4,4,6,6,8,10,12,14],
      f: [10,20,20,30,30,40,50,60,70]
    })
  end

  context "#mean" do
    it "calculates mean of single level numeric only vectors and returns values in a Vector" do
      expect(@df.mean.round(2)).to eq(Daru::Vector.new([3.67, 7.33, 36.67],
        index: [:d, :e, :f]
      ))
    end

    it "calculates mean of multi level numeric only vectors and returns values in a DataFrame" do
      # TODO - pending
    end
  end

  context "#variance_sample" do
    it "calculates variance of single level numeric only vectors and returns values in a Vector" do
      expect(@df.variance_sample).to eq(Daru::Vector.new([4.0, 16.0, 400.0], index: [:d, :e, :f]))
    end
  end

  context "#std" do
    it "calculates standard deviation of single level numeric only vectors and returns values in a Vector" do
      expect(@df.std).to eq(Daru::Vector.new([2, 4, 20], index: [:d, :e, :f]))
    end
  end

  context "#sum" do
    it "calculates sum of single level numeric only vectors and returns values in a Vector" do
      expect(@df.sum).to eq(Daru::Vector.new([33, 66, 330], index: [:d, :e, :f]))
    end
  end

  context "#count" do
    it "counts number of non-nil single level numeric only vectors and returns values in a Vector" do
      expect(@df.count).to eq(Daru::Vector.new([9, 9, 9], index: [:d, :e, :f]))
    end
  end

  context "#mode" do
    it "calculates mode of single level numeric only vectors and returns values in a Vector" do
      expect(@df.mode).to eq(Daru::Vector.new([Daru::Vector.new([2,3]), Daru::Vector.new([4,6]), Daru::Vector.new([20,30])], index: [:d, :e, :f]))
    end
  end

  context "#median" do
    it "calculates median of single level numeric only vectors and returns values in a Vector" do
      expect(@df.median).to eq(Daru::Vector.new([3, 6, 30], index: [:d, :e, :f]))
    end
  end

  context "#max" do
    it "returns the row that has max" do
      df = Daru::DataFrame.new({
        a: [1,2,3,4,5],
        b: ['aa','aaa','a','','dfffdf'],
        c: [11,22,33,44,55]
      })
      expect(df.max(vector: :b)).to eq(
        Daru::Vector.new([5,'dfffdf',55], index: [:a, :b, :c]))
    end
  end

  context "#min" do
    it "calculates mininum of single level numeric only vectors and returns values in a Vector" do
      expect(@df.min).to eq(Daru::Vector.new([1, 2, 10], index: [:d, :e, :f]))
    end
  end

  context "#range" do
    it "calculates range of single level numeric only vectors and returns values in a Vector" do
      expect(@df.range).to eq(Daru::Vector.new([6, 12, 60], index: [:d, :e, :f]))
    end
  end

  context "#product" do
    it "calculates product of single level numeric only vectors and returns values in a Vector" do
      expect(@df.product).to eq(Daru::Vector.new([30240, 15482880, 30240000000000], index: [:d, :e, :f]))
    end
  end

  context "#describe" do
    it "generates mean, std, max, min and count of numeric vectors in one shot" do
      expect(@df.describe.round(2)).to eq(Daru::DataFrame.new({
        d: [9.00, 3.67 ,2.00 , 1.00,  7.00],
        e: [9.00, 7.33 ,4.00 , 2.00, 14.00],
        f: [9.00, 36.67,20.00,10.00, 70.00]
        }, index: [:count, :mean, :std, :min, :max]
      ))
    end
  end

  context "percent_change" do
    it "calculates percent change of numeric vectors" do
      expect(@df.percent_change.round(2)).to eq(Daru::DataFrame.new({
        d: [nil, 1.0, 0.0, 0.5, 0.0, 0.33, 0.25, 0.2, 0.17],
        e: [nil, 1.0, 0.0, 0.5, 0.0, 0.33, 0.25, 0.2, 0.17],
        f: [nil, 1.0, 0.0, 0.5, 0.0, 0.33, 0.25, 0.2, 0.17] }
      ))
    end
  end

  context "#cov" do
    it "calculates the variance covariance of the numeric vectors of DataFrame" do
      expect(@df.cov).to eq(Daru::DataFrame.new({
        d: [4,8,40],
        e: [8,16,80],
        f: [40,80,400]
        }, index: [:d, :e, :f]
      ))

      test = Daru::DataFrame.rows([
        [0.3543,0.4535,0.2424],
        [0.123,0.53323,0.544],
        [0.4345,0.4552,0.425]
      ], order: [:a, :b, :c])
      ans = Daru::DataFrame.new({
        a: [0.0261607, -0.0071019, -0.0153640],
        b: [-0.0071019, 0.0020747, 0.0056071],
        c: [-0.0153640, 0.0056071, 0.0230777]
      })

      test.cov.each_vector_with_index do |v, i|
        expect_correct_vector_in_delta v, ans[i], 0.01
      end
    end
  end

  context "#corr" do
    it "calculates the correlation between the numeric vectors of DataFrame" do
      expect(@df.corr).to eq(Daru::DataFrame.new({
        d: [1,1,1],
        e: [1,1,1],
        f: [1,1,1]
        }, index: [:d, :e, :f]
      ))
    end
  end

  context "#cumsum" do
    it "calculates cumulative sum of numeric vectors" do
      answer = Daru::DataFrame.new({
        d: [1,3,5,8,11,15,20,26,33],
        e: [2,6,10,16,22,30,40,52,66],
        f: [10,30,50,80,110,150,200,260,330]
        })
      expect(@df.cumsum).to eq(answer)
    end
  end

  context "#rolling_mean" do
    it "calculates rolling mean" do
      v = Daru::Vector.new([17.28, 17.45, 17.84, 17.74, 17.82, 17.85, 17.36, 17.3, 17.56, 17.49, 17.46, 17.4, 17.03, 17.01,16.86, 16.86, 16.56, 16.36, 16.66, 16.77])
      df = Daru::DataFrame.new({ a: v, b: v, c: v })
      answer = df.rolling_mean

      expect(answer[:a][-1]) .to be_within(0.001).of(16.897)
      expect(answer[:b][-5]) .to be_within(0.001).of(17.233)
      expect(answer[:c][-10]).to be_within(0.001).of(17.587)
    end
  end

  context "#standardize" do
    it "standardizes" do
      # TODO: Write this test.
      @df.standardize
    end
  end
end
