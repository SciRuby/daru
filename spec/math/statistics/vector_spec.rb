require 'spec_helper.rb'

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
          expect(@dv_with_nils.mean).to eq(282.2)
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
          @dv.max
        end
      end

      context "#min" do
        it "returns the min value" do
          @dv.min
        end
      end 

      context "#sum" do
        it "returns the sum" do
          @dv.sum
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
        it "returns the mode" do
          @dv.mode
        end
      end

      context "#kurtosis" do
        it "calculates kurtosis" do
          @dv.kurtosis
        end
      end

      context "#count" do
        it "counts specified element" do
          @dv.count(323)
        end

        it "counts total number of elements" do
          expect(@dv.count).to eq(10)
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
      end

      context "#average_deviation_population" do
        it "calculates average_deviation_population" do
          @dv.average_deviation_population
        end
      end

      context "#proportion" do
        it "calculates proportion" do
          expect(@dv.proportion(dtype == :gsl ? 1.0 : 1)).to eq(0.1)
        end
      end

      context "#proportions" do
        it "calculates proportions" do
          @dv.proportions
        end
      end

      context "#standard_error" do
        it "calculates standard error" do
          @dv.standard_error
        end
      end

      context "#vector_standarized_compute" do
        it "calculates vector_standarized_compute" do
          @dv.vector_standarized_compute(@dv.mean, @dv.sd)
          @dv_with_nils.vector_standarized_compute(@dv.mean, @dv.sd)
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
    it "calculates frequencies" do
      vector = Daru::Vector.new([5,5,5,5,5,6,6,7,8,9,10,1,2,3,4,nil,-99,-99])
      expect(vector.frequencies).to eq({ 
        1=>1, 2=>1, 3=>1, 4=>1, 5=>5, 
        6=>2, 7=>1, 8=>1, 9=>1,10=>1, -99=>2
      })
    end
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
        vec.only_valid.to_a.sort)
      expect {
        vec.sample_without_replacement(20)
      }.to raise_error(ArgumentError)

      srand(1)
      expect(vec.sample_without_replacement(17).sort).to eq(
        vec.only_valid.to_a.sort)
    end
  end
end