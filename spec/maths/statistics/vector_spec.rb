describe Daru::Vector do
  [:array, :gsl].each do |dtype| #nmatrix still unstable
    describe dtype do
      before do
        @dv = Daru::Vector.new [323, 11, 555, 666, 234, 21, 666, 343, 1, 2], dtype: dtype
        @dv_with_nils = Daru::Vector.new [323, 11, 555, nil, 666, 234, 21, 666, 343, nil, 1, 2]
      end

      context "#mean" do
        it "calculates mean" do
          expect(@dv.mean).to eq(282.2)
        end
      end

      let(:dv) { dv = Daru::Vector.new (["Tyrion", "Daenerys", nil, "Jon Starkgaryen"]), index: Daru::Index.new([:t, :d, :n, :j]) }

      context "#max" do
        it "returns max value" do
          expect(dv.max).to eq("Tyrion")
        end
        it "returns N max values" do
          expect(dv.max(2)).to eq(["Tyrion","Jon Starkgaryen"])
        end
        it "returns max value, sorted by comparitive block input" do
          expect(dv.max { |a,b| a.size <=> b.size }).to eq("Jon Starkgaryen")
        end
        it "returns N max values, sorted by comparitive block input" do
          expect(dv.max(2) {|a,b| a.size <=> b.size}).to eq(["Jon Starkgaryen","Daenerys"])
        end
      end

      context "#max_by" do
        it "raises error without object block" do
          expect { dv.max_by }.to raise_error(ArgumentError)
        end
        it "raises error without object block when N is given" do
          expect { dv.max_by(2) }.to raise_error(ArgumentError)
        end
        it "returns max value, sorted by object block input" do
          expect(dv.max_by { |x| x.size }).to eq("Jon Starkgaryen")
        end
        it "returns N max values, sorted by object block input" do
          expect(dv.max_by(2) {|x| x.size }).to eq(["Jon Starkgaryen","Daenerys"])
        end
      end

      context "#index_of_max" do
        it "returns index_of_max value" do
          expect(dv.index_of_max).to eq(:t)
        end
        it "returns N index_of_max values" do
          expect(dv.index_of_max(2)).to eq([:t, :j])
        end
        it "returns index_of_max value, sorted by comparitive block input" do
          expect(dv.index_of_max { |a,b| a.size <=> b.size }).to eq(:j)
        end
        it "returns N index_of_max values, sorted by comparitive block input" do
          expect(dv.index_of_max(2) {|a,b| a.size <=> b.size}).to eq([:j, :d])
        end
      end

      context "#index_of_max_by" do
        it "raises error without object block" do
          expect { dv.index_of_max_by }.to raise_error(ArgumentError)
        end
        it "raises error without object block when N is given" do
          expect { dv.index_of_max_by(2) }.to raise_error(ArgumentError)
        end
        it "returns index_of_max value, sorted by object block input" do
          expect(dv.index_of_max_by { |x| x.size }).to eq(:j)
        end
        it "returns N index_of_max values, sorted by object block input" do
          expect(dv.index_of_max_by(2) {|x| x.size }).to eq([:j, :d])
        end
      end

      context "#min" do
        it "returns min value" do
          expect(dv.min).to eq("Daenerys")
        end
        it "returns N min values" do
          expect(dv.min(2)).to eq(["Daenerys","Jon Starkgaryen"])
        end
        it "returns min value, sorted by comparitive block input" do
          expect(dv.min { |a,b| a.size <=> b.size }).to eq("Tyrion")
        end
        it "returns N min values, sorted by comparitive block input" do
          expect(dv.min(2) {|a,b| a.size <=> b.size}).to eq(["Tyrion","Daenerys"])
        end
      end

      context "#min_by" do
        it "raises error without object block" do
          expect { dv.min_by }.to raise_error(ArgumentError)
        end
        it "raises error without object block when N is given" do
          expect { dv.min_by(2) }.to raise_error(ArgumentError)
        end
        it "returns min value, sorted by object block input" do
          expect(dv.min_by { |x| x.size }).to eq("Tyrion")
        end
        it "returns N min values, sorted by object block input" do
          expect(dv.min_by(2) {|x| x.size }).to eq(["Tyrion","Daenerys"])
        end
      end

      context "#index_of_min" do
        it "returns index of min value" do
          expect(dv.index_of_min).to eq(:d)
        end
        it "returns N index of min values" do
          expect(dv.index_of_min(2)).to eq([:d, :j])
        end
        it "returns index of min value, sorted by comparitive block input" do
          expect(dv.index_of_min { |a,b| a.size <=> b.size }).to eq(:t)
        end
        it "returns N index of min values, sorted by comparitive block input" do
          expect(dv.index_of_min(2) {|a,b| a.size <=> b.size}).to eq([:t, :d])
        end
      end

      context "#index_of_min_by" do
        it "raises error without object block" do
          expect { dv.index_of_min_by }.to raise_error(ArgumentError)
        end
        it "raises error without object block when N is given" do
          expect { dv.index_of_min_by(2) }.to raise_error(ArgumentError)
        end
        it "returns index of min value, sorted by object block input" do
          expect(dv.index_of_min_by { |x| x.size }).to eq(:t)
        end
        it "returns N index of min values, sorted by object block input" do
          expect(dv.index_of_min_by(2) {|x| x.size }).to eq([:t, :d])
        end
      end

      context "#sum_of_squares" do
        it "calcs sum of squares, omits nil values" do
          v = Daru::Vector.new [1,2,3,4,5,6], dtype: dtype
          expect(v.sum_of_squares).to eq(17.5)
        end
      end

      context "#standard_deviation_sample" do
        it "calcs standard deviation sample" do
          @dv_with_nils.standard_deviation_sample
        end
      end

      context "#variance_sample" do
        it "calculates sample variance" do
          expect(@dv.variance).to be_within(0.01).of(75118.84)
        end
      end

      context "#standard_deviation_population" do
        it "calculates standard deviation population" do
          @dv.standard_deviation_population
        end
      end

      context "#variance_population" do
        it "calculates population variance" do
          expect(@dv.variance_population).to be_within(0.001).of(67606.95999999999)
        end
      end

      context "#covariance_sample" do
        it "calculates sample covariance" do
          @dv_1 = Daru::Vector.new [323, 11, 555, 666, 234, 21, 666, 343, 1, 2]
          @dv_2 = Daru::Vector.new [123, 22, 444, 555, 324, 21, 666, 434, 5, 8]
          expect(@dv_1.covariance @dv_2).to be_within(0.00001).of(65603.62222)
        end
      end

      context "#covariance_population" do
        it "calculates population covariance" do
          @dv_1 = Daru::Vector.new [323, 11, 555, 666, 234, 21, 666, 343, 1, 2]
          @dv_2 = Daru::Vector.new [123, 22, 444, 555, 324, 21, 666, 434, 5, 8]
          expect(@dv_1.covariance_population @dv_2).to be_within(0.01).of(59043.26)
        end
      end

      context "#sum_of_squared_deviation" do
        it "calculates sum of squared deviation" do
          expect(@dv.sum_of_squared_deviation).to eq(676069.6)
        end
      end

      context "#skew" do
        it "calculates skewness" do
          @dv.skew
        end
      end

      context "#max" do
        it "returns the max value" do
          expect(@dv.max).to eq(666)
        end
      end

      context "#min" do
        it "returns the min value" do
          expect(@dv.min).to eq(1)
        end
      end

      context "#sum" do
        it "returns the sum" do
          expect(@dv.sum).to eq(2822)
        end
      end

      context "#product" do
        it "returns the product" do
          v = Daru::Vector.new [1, 2, 3, 4, 5], dtype: dtype
          expect(v.product).to eq(120)
        end
      end

      context "#median" do
        it "returns the median" do
          @dv.median
        end
      end

      context "#mode" do
        it "returns the single modal value as a numeric" do
          mode_test_example = Daru::Vector.new [1,2,3,2,4,4,4,4], dtype: dtype
          expect(mode_test_example.mode).to eq(4)
        end

        it "returns multiple modal values as a vector" do
          mode_test_example = Daru::Vector.new [1,2,2,2,3,2,4,4,4,4], dtype: dtype
          expect(mode_test_example.mode).to eq(Daru::Vector.new [2,4], dtype: dtype)
        end
      end

      context "#describe" do
        it "generates count, mean, std, min and max of vectors in one shot" do
          expect(@dv.describe.round(2)).to eq(Daru::Vector.new([10.00, 282.20, 274.08, 1.00, 666.00],
            index: [:count, :mean, :std, :min, :max],
            name:  :statistics
          ))
        end
      end

      context "#kurtosis" do
        it "calculates kurtosis" do
          @dv.kurtosis
        end
      end

      context "#count" do
        it "counts specified element" do
          expect(@dv.count(323)).to eq(1)
        end

        it "counts total number of elements" do
          expect(@dv.count).to eq(10)
        end

        it "counts by block provided" do
          expect(@dv.count{|e| e.to_i.even? }).to eq(4)
        end
      end

      context "#value_counts" do
        it "counts number of unique values in the Vector" do
          vector = Daru::Vector.new(
            ["America","America","America","America","America",
              "India","India", "China", "India", "China"])
          expect(vector.value_counts).to eq(
            Daru::Vector.new([5,3,2], index: ["America", "India", "China"]))
        end
      end

      context "#coefficient_of_variation" do
        it "calculates coefficient_of_variation" do
          @dv.coefficient_of_variation
        end
      end

      context "#percentile" do
        it "calculates mid point percentile" do
          expect(@dv.percentile(50)).to eq(278.5)
        end

        it "calculates linear percentile" do
          # FIXME: Not enough testing?..
          expect(@dv.percentile(50, :linear)).to eq(278.5)
        end

        it "fails on unknown strategy" do
          expect { @dv.percentile(50, :killemall) }.to raise_error(ArgumentError, /strategy/)
        end
      end

      context "#average_deviation_population" do
        it "calculates average_deviation_population" do
          a = Daru::Vector.new([1, 2, 3, 4, 5, 6, 7, 8, 9], dtype: dtype)
          expect(a.average_deviation_population).to eq(20.quo(9).to_f)
        end
      end

      context "#proportion" do
        it "calculates proportion" do
          expect(@dv.proportion(dtype == :gsl ? 1.0 : 1)).to eq(0.1)
        end
      end

      context "#proportions" do
        it "calculates proportions" do
          actual_proportions = {
            array: {323=>0.1,11=>0.1,555=>0.1,666=>0.2,234=>0.1,21=>0.1,343=>0.1,1=>0.1,2=>0.1},
            gsl: {323.0=>0.1, 11.0=>0.1, 555.0=>0.1, 666.0=>0.2, 234.0=>0.1, 21.0=>0.1, 343.0=>0.1, 1.0=>0.1, 2.0=>0.1}
          }
          expect(@dv.proportions).to eq(actual_proportions[dtype])
        end
      end

      context "#standard_error" do
        it "calculates standard error" do
          @dv.standard_error
        end
      end

      context "#vector_standardized_compute" do
        it "calculates vector_standardized_compute" do
          @dv.vector_standardized_compute(@dv.mean, @dv.sd)
          @dv_with_nils.vector_standardized_compute(@dv.mean, @dv.sd)
        end
      end

      context "#vector_centered_compute" do
        it "calculates vector_centered_compute" do
          @dv.vector_centered_compute(@dv.mean)
          @dv_with_nils.vector_centered_compute(@dv.mean)
        end
      end
    end
  end # ALL DTYPE tests

  # Only Array tests
  context "#percentile" do
    it "tests linear percentile strategy" do
      values = Daru::Vector.new [102, 104, 105, 107, 108, 109, 110, 112, 115, 116].shuffle
      expect(values.percentil(0, :linear)).to eq(102)
      expect(values.percentil(25, :linear)).to eq(104.75)
      expect(values.percentil(50, :linear)).to eq(108.5)
      expect(values.percentil(75, :linear)).to eq(112.75)
      expect(values.percentil(100, :linear)).to eq(116)

      values = Daru::Vector.new [102, 104, 105, 107, 108, 109, 110, 112, 115, 116, 118].shuffle
      expect(values.percentil(0, :linear)).to eq(102)
      expect(values.percentil(25, :linear)).to eq(105)
      expect(values.percentil(50, :linear)).to eq(109)
      expect(values.percentil(75, :linear)).to eq(115)
      expect(values.percentil(100, :linear)).to eq(118)
    end
  end

  context "#frequencies" do
    let(:vector) { Daru::Vector.new([5,5,5,5,5,6,6,7,8,9,10,1,2,3,4,nil,-99,-99]) }
    subject { vector.frequencies }
    it { is_expected.to eq Daru::Vector.new(
      [5,2,1,1,1,1,1,1,1,1,2],
      index: [5,6,7,8,9,10,1,2,3,4,-99]
    )}
  end

  context "#ranked" do
    it "curates by rank" do
      vector = Daru::Vector.new([nil, 0.8, 1.2, 1.2, 2.3, 18, nil])
      expect(vector.ranked).to eq(Daru::Vector.new([nil,1,2.5,2.5,4,5,nil]))

      v = Daru::Vector.new [0.8, 1.2, 1.2, 2.3, 18]
      expect(v.ranked).to eq(Daru::Vector.new [1, 2.5, 2.5, 4, 5])
    end

    it "tests paired ties" do
      a = Daru::Vector.new [0, 0, 0, 1, 1, 2, 3, 3, 4, 4, 4]
      expected = Daru::Vector.new [2, 2, 2, 4.5, 4.5, 6, 7.5, 7.5, 10, 10, 10]
      expect(a.ranked).to eq(expected)
    end
  end

  context "#dichotomize" do
    it "dichotomizes" do
      a = Daru::Vector.new [0, 0, 0, 1, 2, 3, nil]
      exp = Daru::Vector.new [0, 0, 0, 1, 1, 1, nil]
      expect(a.dichotomize).to eq(exp)

      a = Daru::Vector.new [1, 1, 1, 2, 2, 2, 3]
      exp = Daru::Vector.new [0, 0, 0, 1, 1, 1, 1]
      expect(a.dichotomize).to eq(exp)

      a = Daru::Vector.new [0, 0, 0, 1, 2, 3, nil]
      exp = Daru::Vector.new [0, 0, 0, 0, 1, 1, nil]
      expect(a.dichotomize(1)).to eq(exp)

      a = Daru::Vector.new %w(a a a b c d)
      exp = Daru::Vector.new [0, 0, 0, 1, 1, 1]
      expect(a.dichotomize).to eq(exp)
    end
  end

  context "#median_absolute_deviation" do
    it "calculates median_absolute_deviation" do
      a = Daru::Vector.new [1, 1, 2, 2, 4, 6, 9]
      expect(a.median_absolute_deviation).to eq(1)
    end
  end

  context "#round" do
    it "rounds non-nil values" do
      vector = Daru::Vector.new([1.44,55.32,nil,4])
      expect(vector.round(1)).to eq(Daru::Vector.new([1.4,55.3,nil,4]))
    end
  end

  context "#center" do
    it "centers" do
      mean = rand
      samples = 11
      centered = Daru::Vector.new(samples.times.map { |i| i - ((samples / 2).floor).to_i })
      not_centered = centered.recode { |v| v + mean }
      obs = not_centered.center
      centered.each_with_index do |v, i|
        expect(v).to be_within(0.0001).of(obs[i])
      end
    end
  end

  context "#standardize" do
    it "returns a standardized vector" do
      vector = Daru::Vector.new([11,55,33,25,nil,22])
      expect(vector.standardize.round(2)).to eq(
        Daru::Vector.new([-1.11, 1.57, 0.23, -0.26,nil, -0.44])
        )
    end

    it "tests for vector standardized with zero variance" do
      v1 = Daru::Vector.new 100.times.map { |_i| 1 }
      exp = Daru::Vector.new 100.times.map { nil }
      expect(v1.standardize).to eq(exp)
    end
  end

  context "#vector_percentile" do
    it "replaces each non-nil value with its percentile value" do
      vector = Daru::Vector.new([1,nil,nil,2,2,3,4,nil,nil,5,5,5,6,10])
      expect(vector.vector_percentile).to eq(Daru::Vector.new(
        [10,nil,nil,25,25,40,50,nil,nil,70,70,70,90,100])
      )
    end
  end

  context "#sample_with_replacement" do
    it "calculates sample_with_replacement" do
      vec =  Daru::Vector.new(
        [5, 5, 5, 5, 5, 6, 6, 7, 8, 9, 10, 1, 2, 3, 4, nil, -99, -99],
        name: :common_all_dtypes)
      srand(1)
      expect(vec.sample_with_replacement(100).size).to eq(100)

      srand(1)
      expect(vec.sample_with_replacement(100).size).to eq(100)
    end
  end

  context "#sample_without_replacement" do
    it "calculates sample_without_replacement" do
      vec =  Daru::Vector.new(
        [5, 5, 5, 5, 5, 6, 6, 7, 8, 9, 10, 1, 2, 3, 4, nil, -99, -99],
        name: :common_all_dtypes)

      srand(1)
      expect(vec.sample_without_replacement(17).sort).to eq(
        vec.reject_values(*Daru::MISSING_VALUES).to_a.sort)
      expect {
        vec.sample_without_replacement(20)
      }.to raise_error(ArgumentError)

      srand(1)
      expect(vec.sample_without_replacement(17).sort).to eq(
        vec.reject_values(*Daru::MISSING_VALUES).to_a.sort)
    end
  end

  context "#jackknife" do
    it "jack knife correctly with named method" do
      a = Daru::Vector.new [1, 2, 3, 4]
      df = a.jackknife(:mean)
      expect(df[:mean].mean).to eq (a.mean)

      df = a.jackknife([:mean, :sd])
      expect(df[:mean].mean).to eq(a.mean)
      expect(df[:mean].sd).to eq(a.sd)
    end

    it "jack knife correctly with custom method" do
      a   = Daru::Vector.new [17.23, 18.71, 13.93, 18.81, 15.78, 11.29, 14.91, 13.39, 18.21, 11.57, 14.28, 10.94, 18.83, 15.52, 13.45, 15.25]
      ds  = a.jackknife(log_s2: ->(v) {  Math.log(v.variance) })
      exp = Daru::Vector.new [1.605, 2.972, 1.151, 3.097, 0.998, 3.308, 0.942, 1.393, 2.416, 2.951, 1.043, 3.806, 3.122, 0.958, 1.362, 0.937]

      expect_correct_vector_in_delta ds[:log_s2], exp, 0.001
      # expect(ds[:log_s2]).to be_within(0.001).of(exp)
      expect(ds[:log_s2].mean).to be_within(0.00001).of(2.00389)
      expect(ds[:log_s2].variance).to be_within(0.001).of(1.091)
    end

    it "jack knife correctly with k > 1" do
      rng = Distribution::Normal.rng(0,1)
      a   = Daru::Vector.new_with_size(6) { rng.call}

      ds = a.jackknife(:mean, 2)
      mean = a.mean
      exp = Daru::Vector.new [3 * mean - 2 * (a[2] + a[3] + a[4] + a[5]) / 4, 3 * mean - 2 * (a[0] + a[1] + a[4] + a[5]) / 4, 3 * mean - 2 * (a[0] + a[1] + a[2] + a[3]) / 4]
      expect_correct_vector_in_delta(exp, ds[:mean], 1e-13)
    end
  end

  before do
    # daily closes of iShares XIU on the TSX
    @shares = Daru::Vector.new([17.28, 17.45, 17.84, 17.74, 17.82, 17.85, 17.36, 17.3, 17.56, 17.49, 17.46, 17.4, 17.03, 17.01,16.86, 16.86, 16.56, 16.36, 16.66, 16.77])
  end

  context "#acf" do
    it "calculates autocorrelation co-efficients" do
      acf = @shares.acf

      expect(acf.length).to eq(14)

      # test the first few autocorrelations
      expect(acf[0]).to be_within(0.0001).of(1.0)
      expect(acf[1]).to be_within(0.001) .of(0.852)
      expect(acf[2]).to be_within(0.001) .of(0.669)
      expect(acf[3]).to be_within(0.001) .of(0.486)
    end
  end

  context "#percent_change" do
    it "calculates percent change" do
      vector = Daru::Vector.new([4,6,6,8,10],index: ['a','f','t','i','k'])
      expect(vector.percent_change).to eq(
      Daru::Vector.new([nil, 0.5, 0.0, 0.3333333333333333, 0.25], index: ['a','f','t','i','k']))
    end

    it "tests for numerical vectors with nils" do
      vector2 = Daru::Vector.new([nil,6,nil,8,10],index: ['a','f','t','i','k'])
      expect(vector2.percent_change).to eq(
      Daru::Vector.new([nil, nil, nil, 0.3333333333333333, 0.25], index: ['a','f','t','i','k']))
    end
  end

  context "#diff" do
    it "performs the difference of the series" do
      diff = @shares.diff

      expect(diff.class).to eq(Daru::Vector)
      expect(diff[@shares.size - 1]).to be_within(0.001).of( 0.11)
      expect(diff[@shares.size - 2]).to be_within(0.001).of( 0.30)
      expect(diff[@shares.size - 3]).to be_within(0.001).of(-0.20)
    end
  end

  context "#rolling" do
    it "calculates rolling mean" do
      ma10 = @shares.rolling_mean

      expect(ma10[-1]) .to be_within(0.001).of(16.897)
      expect(ma10[-5]) .to be_within(0.001).of(17.233)
      expect(ma10[-10]).to be_within(0.001).of(17.587)

      # test with a different lookback period
      ma5 = @shares.rolling :mean, 5

      expect(ma5[-1]).to be_within(0.001).of(16.642)
      expect(ma5[-10]).to be_within(0.001).of(17.434)
      expect(ma5[-15]).to be_within(0.001).of(17.74)
    end

    it "calculates rolling median" do
      me10 = @shares.rolling_median.round(2)
      expect(me10).to eq(Daru::Vector.new([nil,nil,nil,nil,nil,nil,nil,nil,nil,17.525,17.525,17.525,17.475,17.430,17.380,17.330,17.165,17.020,16.94,16.860]).round(2))

      me5 = @shares.rolling(:median, 5).round(2)
      expect(me5).to eq(Daru::Vector.new([nil,nil,nil,nil,17.74,17.82,17.82,17.74,17.56,17.49,17.46,17.46,17.46,17.40,17.03,17.01,16.86,16.86,16.66,16.66]))
    end

    it "calculates rolling max" do
      max10 = @shares.rolling_max.round(2)
      expect(max10).to eq(Daru::Vector.new([nil,nil,nil,nil,nil,nil,nil,nil,nil,17.85,17.85,17.85,17.85,17.85,17.85,17.56,17.56,17.56,17.49,17.46]))

      max5 = @shares.rolling(:max, 5).round(2)
      expect(max5).to eq(Daru::Vector.new([nil,  nil,  nil,  nil,17.84,17.85,17.85,17.85,17.85,17.85,17.56,17.56,17.56,17.49,17.46,17.40,17.03,17.01,16.86,16.86]))
    end

    it "calculates rolling min" do
      min10 = @shares.rolling_min.round(2)
      expect(min10).to eq(Daru::Vector.new([nil,nil,nil,nil,nil,nil,nil,nil,nil,17.28,17.30,17.30,17.03,17.01,16.86,16.86,16.56,16.36,16.36,16.36]))

      min5 = @shares.rolling(:min, 5).round(2)
      expect(min5).to eq(Daru::Vector.new([nil,nil,nil,nil,17.28,17.45,17.36,17.30,17.30,17.30,17.30,17.30,17.03,17.01,16.86,16.86,16.56,16.36,16.36,16.36]))
    end

    it "calculates rolling sum" do
      sum10 = @shares.rolling_sum.round(2)
      expect(sum10).to eq(Daru::Vector.new([nil,nil,nil,nil,nil,nil,nil,nil,nil,175.69,175.87,175.82,175.01,174.28,173.32,172.33,171.53,170.59,169.69,168.97]))

      sum5 = @shares.rolling(:sum, 5).round(2)
      expect(sum5).to eq(Daru::Vector.new([nil,nil,nil,nil,88.13,88.70,88.61,88.07,87.89,87.56,87.17,87.21,86.94,86.39,85.76,85.16,84.32,83.65,83.30,83.21]))
    end

    it "calculates rolling std" do
      std10 = @shares.rolling_std.round(2)
      expect(std10).to eq(Daru::Vector.new([nil,nil,nil,nil,nil,nil,nil,nil,nil,0.227227,0.208116,0.212331,0.253485,0.280666,0.295477,0.267127,0.335826,0.412834,0.388886,0.345995]).round(2))

      std5 = @shares.rolling(:std, 5).round(2)
      expect(std5).to eq(Daru::Vector.new([nil,nil,nil,nil,0.248556,0.167780,0.206930,0.263211,0.253811,0.215105,0.103827,0.098082,0.208255,0.237844,0.263002,0.220839,0.187963,0.263629,0.212132,0.193959]).round(2))
    end

    it "calculates rolling variance" do
      var10 = @shares.rolling_variance.round(2)
      expect(var10).to eq(Daru::Vector.new([nil,nil,nil,nil,nil,nil,nil,nil,nil,0.051632,0.043312,0.045084,0.064254,0.078773,0.087307,0.071357,0.112779,0.170432,0.151232,0.119712]).round(2))

      var5 = @shares.rolling(:variance, 5).round(2)
      expect(var5).to eq(Daru::Vector.new([nil,nil,nil,nil,0.06178,0.02815,0.04282,0.06928,0.06442,0.04627,0.01078,0.00962,0.04337,0.05657,0.06917,0.04877,0.03533,0.06950,0.04500,0.03762]).round(2))
    end

    it "calculates rolling non-nil count" do
      @shares.rolling_count
    end
  end

  context "#ema" do
    it "calculates exponential moving average" do
      # test default
      ema10 = @shares.ema

      expect(ema10[-1]) .to be_within(0.00001).of( 16.87187)
      expect(ema10[-5]) .to be_within(0.00001).of( 17.19187)
      expect(ema10[-10]).to be_within(0.00001).of( 17.54918)

      # test with a different loopback period
      ema5 = @shares.ema 5

      expect(ema5[-1]) .to be_within( 0.00001).of(16.71299)
      expect(ema5[-10]).to be_within( 0.00001).of(17.49079)
      expect(ema5[-15]).to be_within( 0.00001).of(17.70067)

      # test with a different smoother
      ema_w = @shares.ema 10, true

      expect(ema_w[-1]) .to be_within(0.00001).of(17.08044)
      expect(ema_w[-5]) .to be_within(0.00001).of(17.33219)
      expect(ema_w[-10]).to be_within(0.00001).of(17.55810)
    end
  end

  context "#emv" do
    it "calculates exponential moving variance" do
      # test default
      emv10 = @shares.emv

      expect(emv10[-1]) .to be_within(0.00001).of(0.14441)
      expect(emv10[-5]) .to be_within(0.00001).of(0.10797)
      expect(emv10[-10]).to be_within(0.00001).of(0.03979)

      # test with a different loopback period
      emv5 = @shares.emv 5

      expect(emv5[-1]) .to be_within(0.00001).of(0.05172)
      expect(emv5[-10]).to be_within(0.00001).of(0.01736)
      expect(emv5[-15]).to be_within(0.00001).of(0.04410)

      # test with a different smoother
      emv_w = @shares.emv 10, true

      expect(emv_w[-1]) .to be_within(0.00001).of(0.20318)
      expect(emv_w[-5]) .to be_within(0.00001).of(0.11319)
      expect(emv_w[-10]).to be_within(0.00001).of(0.04289)
    end
  end

  context "#emsd" do
    it "calculates exponential moving standard deviation" do
      # test default
      emsd10 = @shares.emsd

      expect(emsd10[-1]) .to be_within(0.00001).of(0.38002)
      expect(emsd10[-5]) .to be_within(0.00001).of(0.32859)
      expect(emsd10[-10]).to be_within(0.00001).of(0.19947)

      # test with a different loopback period
      emsd5 = @shares.emsd 5

      expect(emsd5[-1]) .to be_within(0.00001).of(0.22742)
      expect(emsd5[-10]).to be_within(0.00001).of(0.13174)
      expect(emsd5[-15]).to be_within(0.00001).of(0.21000)

      # test with a different smoother
      emsd_w = @shares.emsd 10, true

      expect(emsd_w[-1]) .to be_within(0.00001).of(0.45076)
      expect(emsd_w[-5]) .to be_within(0.00001).of(0.33644)
      expect(emsd_w[-10]).to be_within(0.00001).of(0.20710)
    end
  end

  RSpec.shared_examples 'correct macd' do |*args|
    let(:source) { Daru::DataFrame.from_csv('spec/fixtures/macd_data.csv') }

    # skip initial records during compare as ema is sensitive to
    # period used.
    # http://ta-lib.org/d_api/ta_setunstableperiod.html
    let(:stability_offset) { 90 }
    let(:delta) { 0.001 }
    let(:desc) { args.empty? ? '12_26_9' : args.join('_') }

    subject { source['price'].macd(*args) }

    %w[ macd macdsig macdhist ].each_with_index do |field, i|
      it do
        act = subject[i][stability_offset..-1]
        exp = source["#{field}_#{desc}"][stability_offset..-1]
        expect(act).to be_all_within(delta).of(exp)
      end
    end
  end

  describe '#macd' do
    context 'by default' do
      it_should_behave_like 'correct macd'
    end

    context 'custom values for fast, slow, signal' do
      it_should_behave_like 'correct macd', 6, 13, 4
    end

  end

  context "#cumsum" do
    it "calculates cumulative sum" do
      vector = Daru::Vector.new([1,2,3,4,5,6,7,8,9,10])
      expect(vector.cumsum).to eq(
        Daru::Vector.new([1,3,6,10,15,21,28,36,45,55]))
    end

    it "works with missing values" do
      vector = Daru::Vector.new([1,2,nil,3,nil,4,5])
      expect(vector.cumsum).to eq(
        Daru::Vector.new([1,3,nil,6,nil,10,15]))
    end
  end
end
