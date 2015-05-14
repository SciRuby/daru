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
          @dv.sum_of_squares
          @dv_with_nils.sum_of_squares
        end
      end

      context "#standard_deviation_sample" do
        it "calcs standard deviation sample" do
          @dv_with_nils.standard_deviation_sample
        end
      end

      context "#variance_sample" do
        it "calculates sample variance" do
          @dv.variance_sample
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

      context "#percentile" do
        it "calculates percentile" do
          expect(@dv.percentile(50)).to eq(333.0)
        end
      end

      context "#recode" do

      end

      context "#recode!" do

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

      context "#ranked" do
        it "curates by rank" do
          vector = Daru::Vector.new([nil, 0.8, 1.2, 1.2, 2.3, 18, nil])
          expect(vector.ranked).to eq(Daru::Vector.new([nil,1,2.5,2.5,4,5,nil]))
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

      context "#factor" do

      end

      context "#median_absolute_deviation" do
        it "calculates median_absolute_deviation" do
          a = Daru::Vector.new [1, 1, 2, 2, 4, 6, 9]
          expect(a.median_absolute_deviation).to eq(1)
        end
      end

      context "#standard_error" do
        it "calculates standard error" do
          @dv.standard_error
        end
      end
      
      context "#round" do
        it "rounds non-nil values" do
          vector = Daru::Vector.new([1.44,55.32,nil,4])
          expect(vector.round(1)).to eq(Daru::Vector.new([1.4,55.3,nil,4]))
        end
      end

      context "#center" do
        it "returns a centered vector" do
          vector = Daru::Vector.new([11,55,33,25,22,nil])
          expect(vector.center.round(1)).to eq(
            Daru::Vector.new([-18.2, 25.8, 3.8, -4.2, -7.2, nil])
            )
        end
      end

      context "#standardize" do
        it "returns a standardized vector" do
          vector = Daru::Vector.new([11,55,33,25,nil,22])
          expect(vector.standardize.round(2)).to eq(
            Daru::Vector.new([-1.11, 1.57, 0.23, -0.26,nil, -0.44])
            )
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
      
      context "#sample_with_replacement" do
        it "calculates sample_with_replacement" do
          @dv.sample_with_replacement
          @dv_with_nils.sample_with_replacement
        end
      end

      context "#sample_without_replacement" do
        it "calculates sample_without_replacement" do
          @dv.sample_without_replacement
          @dv_with_nils.sample_without_replacement
        end
      end
    end
  end
end