require 'spec_helper'

describe "Arel-like syntax" do
  describe "comparison operators" do
    describe Daru::Vector do
      before do
        @vector = Daru::Vector.new([23,51,1214,352,32,11])
        @comparator = Daru::Vector.new([45,22,1214,55,32,9])
      end

      context "#eq" do
        it "accepts scalar value" do
          expect(@vector.eq(352)).to eq([false,false,false,true,false,false])
        end

        it "accepts vector and compares corrensponding elements" do
          expect(@vector.eq(@comparator)).to eq([false,false,true,false,true,false])
        end
      end

      context "#not_eq" do
        it "accepts scalar value" do
          expect(@vector.not_eq(51)).to eq([true, false, true, true, true, true])
        end

        it "accepts vector and compares corrensponding elements" do
          expect(@vector.not_eq(@comparator)).to eq(
            [true, true, false, true, false, true])
        end
      end

      context "#lt" do
        it "accepts scalar value" do
          expect(@vector.lt(51)).to eq([true, false, false, false, true, true])
        end

        it "accepts vector and compares corrensponding elements" do
          expect(@vector.lt(@comparator)).to eq(
            [true,false,false,false,false,false])
        end
      end

      context "#lteq" do
        it "accepts scalar value" do
          expect(@vector.lteq(51)).to eq([true, true, false, false, true, true])
        end

        it "accepts vector and compares corrensponding elements" do
          expect(@vector.lteq(@comparator)).to eq(
            [true,false,true,false,true,false])
        end
      end

      context "#mt" do
        it "accepts scalar value" do
          expect(@vector.mt(51)).to eq([false, false, true, true, false, false])
        end

        it "accepts vector and compares corrensponding elements" do
          expect(@vector.mt(@comparator)).to eq([false,true,false,true,false,true])
        end
      end

      context "#mteq" do
        it "accepts scalar value" do
          expect(@vector.mteq(51)).to eq([false, true, true, true, false, false])
        end

        it "accepts vector and compares corrensponding elements" do
          expect(@vector.mteq(@comparator)).to eq([false,true,true,true,true,true])
        end
      end

      context "#in" do
        it "checks if any of elements in the arg are present in the vector" do
          expect(@vector.in([23,55,1,33,32])).to eq(
            [true, false, false, false, true, false])
        end
      end
    end
  end

  describe "where clause" do
    context Daru::DataFrame do
      before do
        @df = Daru::DataFrame.new({
          number: [1,2,3,4,5,6],
          sym: [:one, :two, :three, :four, :five, :six],
          names: ['sameer', 'john', 'james', 'omisha', 'priyanka', 'shravan']
        })
      end

      it "accepts simple single eq statement" do
        answer = Daru::DataFrame.new({
          number: [4],
          sym: [:four],
          names: ['omisha']
          }, index: Daru::Index.new([3])
        )
        expect(@df.where(@df[:number].eq(4))).to eq(answer)
      end

      it "accepts somewhat complex comparison operator chaining" do
        answer = Daru::DataFrame.new({
          number: [3,4],
          sym: [:three, :four],
          names: ['james', 'omisha']
        }, index: Daru::Index.new([2,3]))
        expect(
          @df.where (@df[:names].eq('james') or @df[:sym].eq(:four))
          ).to eq(answer)
      end

      it "allows chaining of where clauses" do
        answer = Daru::DataFrame.new({
          number: [1,3],
          sym: [:four],
          names: ['sameer', 'john']
          }, index: Daru::Index.new([0,2])
        )
        expect(
          @df.where(@df[:number].lteq(3))
             .where(@df[:names] .in(['sameer', 'james']))
        ).to eq(answer)
      end
    end

    context Daru::Vector do
      before do
        @vector = Daru::Vector.new([2,5,1,22,51,4])
      end

      it "accepts a simple single statement" do
        expect(@vector.where(@vector.lt(10))).to eq(
          Daru::Vector.new([2,5,1,4], index: Daru::Index.new([0,1,2,5])))
      end

      it "accepts somewhat complex operator chaining" do
        expect(@vector.where (@vector.lt(6) or @vector.eq(51))).to eq(
          Daru::Vector.new([2,1,51,4], index: Daru::Index.new([0,2,4,5])))
      end

      it "allows chaining of where clauses" do
        expect(
          @vector.where(@vector.lt(20))
                 .where(@vector.gt(3))).to 
        eq(Daru::Vector.new([5,4], index: Daru::Index.new([1,5])))
      end
    end
  end
end
