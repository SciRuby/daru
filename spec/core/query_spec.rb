describe Daru::Core::Query::BoolArray do
  before do
    @klass = Daru::Core::Query::BoolArray
    @left = @klass.new([true, true, true, false, false, true])
    @right = @klass.new([false, false, false, false, true, false])
  end

  context "#&" do
    it "computes and logic of each element in the array" do
      expect(@left & @right).to eq(
        @klass.new([false, false, false, false, false, false]))
    end
  end

  context "#|" do
    it "computes or logic of each element in arrays" do
      expect(@left | @right).to eq(
        @klass.new([true, true, true, false, true, true]))
    end
  end

  context "#!" do
    it "computes not logic of each element" do
      expect(!@left).to eq(
        @klass.new([false, false, false, true, true, false])
        )
    end
  end

  context '#inspect' do
    it 'is reasonable' do
      expect(@left.inspect).to eq "#<Daru::Core::Query::BoolArray:#{@left.object_id} bool_arry=[true, true, true, false, false, true]>"
    end
  end
end

describe "Arel-like syntax" do
  describe "comparison operators" do
    describe Daru::Vector do
      before do
        @vector = Daru::Vector.new([23,51,1214,352,32,11])
        @comparator = Daru::Vector.new([45,22,1214,55,32,9])
        @klass = Daru::Core::Query::BoolArray
      end

      context "#eq" do
        it "accepts scalar value" do
          expect(@vector.eq(352)).to eq(
            @klass.new([false,false,false,true,false,false]))
        end

        it "accepts vector and compares corrensponding elements" do
          expect(@vector.eq(@comparator)).to eq(
            @klass.new([false,false,true,false,true,false]))
        end
      end

      context "#not_eq" do
        it "accepts scalar value" do
          expect(@vector.not_eq(51)).to eq(
            @klass.new([true, false, true, true, true, true]))
        end

        it "accepts vector and compares corrensponding elements" do
          expect(@vector.not_eq(@comparator)).to eq(
            @klass.new([true, true, false, true, false, true]))
        end
      end

      context "#lt" do
        it "accepts scalar value" do
          expect(@vector.lt(51)).to eq(
            @klass.new([true, false, false, false, true, true]))
        end

        it "accepts vector and compares corrensponding elements" do
          expect(@vector.lt(@comparator)).to eq(
            @klass.new([true,false,false,false,false,false]))
        end
      end

      context "#lteq" do
        it "accepts scalar value" do
          expect(@vector.lteq(51)).to eq(
            @klass.new([true, true, false, false, true, true]))
        end

        it "accepts vector and compares corrensponding elements" do
          expect(@vector.lteq(@comparator)).to eq(
            @klass.new([true,false,true,false,true,false]))
        end
      end

      context "#mt" do
        it "accepts scalar value" do
          expect(@vector.mt(51)).to eq(
            @klass.new([false, false, true, true, false, false]))
        end

        it "accepts vector and compares corrensponding elements" do
          expect(@vector.mt(@comparator)).to eq(
            @klass.new([false,true,false,true,false,true]))
        end
      end

      context "#mteq" do
        it "accepts scalar value" do
          expect(@vector.mteq(51)).to eq(
            @klass.new([false, true, true, true, false, false]))
        end

        it "accepts vector and compares corrensponding elements" do
          expect(@vector.mteq(@comparator)).to eq(
            @klass.new([false,true,true,true,true,true]))
        end
      end

      context "#in" do
        it "checks if any of elements in the arg are present in the vector" do
          expect(@vector.in([23,55,1,33,32])).to eq(
            @klass.new([true, false, false, false, true, false]))
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
          @df.where (@df[:names].eq('james') | @df[:sym].eq(:four))
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
        expect(@vector.where((@vector.lt(6) | @vector.eq(51)))).to eq(
          Daru::Vector.new([2,5,1,51,4], index: Daru::Index.new([0,1,2,4,5])))
      end

      it "preserves name" do
        named_vector = Daru::Vector.new([1,2,3], name: 'named')
        expect(named_vector.where(named_vector.lteq(2)).name).to eq('named')
      end
    end
  end
end
