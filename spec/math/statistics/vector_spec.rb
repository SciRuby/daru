require 'spec_helper.rb'

describe Daru::Vector do
  [NMatrix, Array].each do |dtype|
    describe dtype do
      before :each do
        @dv = Daru::Vector.new [323, 11, 555, 666, 234, 21, 666, 343, 1, 2], dtype: dtype
      end

      context "#mean" do
        it "calculates mean" do
          expect(@dv.mean).to eq(282.2)
        end
      end

      context "#sum_of_squares" do
        it "calcs sum of squares" do

        end
      end

      context "#standard_deviation_sample" do
        it "calcs standard deviation sample" do

        end
      end

      context "#variance_sample" do
        it "calculates sample variance" do

        end
      end

      context "#standard_deviation_population" do
        it "calculates standard deviation population" do

        end
      end

      context "#variance_population" do
        it "calculates population variance" do
          expect(@dv.variance_population).to eq(67606.95999999999)
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
          @dv.product
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
          @dv.frequencies
        end
      end

      context "#average_deviation_population" do
        it "calculates average_deviation_population" do
          @dv.average_deviation_population
        end
      end

      context "#proportion" do

      end

      context "#proportions" do
        it "calculates proportions" do
          @dv.proportions
        end
      end

      context "#ranked" do
        it "curates by rank" do
          @dv.ranked
        end
      end

      context "#count" do

      end

      context "#coefficient_of_variation" do
        it "calculates coefficient_of_variation" do
          @dv.coefficient_of_variation
        end
      end
    end
  end
end