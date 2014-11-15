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

      end

      context "#max" do

      end

      context "#min" do

      end

      context "#sum" do

      end

      context "#product" do

      end

      context "#median" do

      end

      context "#mode" do

      end

      context "#kurtosis" do
        it "calculates kurtosis" do
          
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
          
        end
      end

      context "#average_deviation_population" do
      end

      context "#proportion" do

      end

      context "#proportions" do
        
      end

      context "#ranked" do
        it "curates by rank" do
          @dv.ranked
        end
      end
    end
  end
end