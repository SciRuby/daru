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
      describe "non-categorical type" do
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

      describe "categorical type" do
        let(:dv) { Daru::Vector.new ['e', 'd', 'd', 'x', 'x'],
          categories: ['a', 'x', 'c', 'd', 'e'], type: :category }
        let(:comp) { Daru::Vector.new ['a', 'd', 'x', 'e', 'x'],
          categories: ['a', 'x', 'c', 'd', 'e'], type: :category }
        let(:query_bool_class) { Daru::Core::Query::BoolArray }

        context "#eq" do
          context "scalar" do
            subject { dv.eq 'd' }

            it { is_expected.to be_a query_bool_class }
            its(:to_a) { is_expected.to eq [false, true, true, false, false] }
          end

          context "vector" do
            subject { dv.eq comp }

            it { is_expected.to be_a query_bool_class }
            its(:to_a) { is_expected.to eq [false, true, false, false, true] }
          end
        end

        context "#not_eq" do
          context "scalar" do
            subject { dv.not_eq 'd' }

            it { is_expected.to be_a query_bool_class }
            its(:to_a) { is_expected.to eq [true, false, false, true, true] }
          end

          context "vector" do
            subject { dv.not_eq comp }

            it { is_expected.to be_a query_bool_class }
            its(:to_a) { is_expected.to eq [true, false, true, true, false] }
          end
        end

        context "#lt" do
          context "scalar" do
            subject { dv.lt 'd' }

            it { is_expected.to be_a query_bool_class }
            its(:to_a) { is_expected.to eq [false, false, false, true, true] }
          end

          context "vector" do
            subject { dv.lt comp }

            it { is_expected.to be_a query_bool_class }
            its(:to_a) { is_expected.to eq [false, false, false, true, false] }
          end
        end

        context "#lteq" do
          context "scalar" do
            subject { dv.lteq 'd' }

            it { is_expected.to be_a query_bool_class }
            its(:to_a) { is_expected.to eq [false, true, true, true, true] }
          end

          context "vector" do
            subject { dv.lteq comp }

            it { is_expected.to be_a query_bool_class }
            its(:to_a) { is_expected.to eq [false, true, false, true, true] }
          end
        end

        context "#mt" do
          context "scalar" do
            subject { dv.mt 'd' }

            it { is_expected.to be_a query_bool_class }
            its(:to_a) { is_expected.to eq [true, false, false, false, false] }
          end

          context "vector" do
            subject { dv.mt comp }

            it { is_expected.to be_a query_bool_class }
            its(:to_a) { is_expected.to eq [true, false, true, false, false] }
          end
        end

        context "#mteq" do
          context "scalar" do
            subject { dv.mteq 'd' }

            it { is_expected.to be_a query_bool_class }
            its(:to_a) { is_expected.to eq [true, true, true, false, false] }
          end

          context "vector" do
            subject { dv.mteq comp }

            it { is_expected.to be_a query_bool_class }
            its(:to_a) { is_expected.to eq [true, true, true, false, true] }
          end
        end

        # context "#in" do
        #   subject { dv.in ['b', 'd'] }
        #   it { is_expected.to be_a query_bool_class }
        #   its(:to_a) { is_expected.to eq [false, true, true, true, true] }
        # end
      end
    end
  end

  describe "where clause" do
    context Daru::DataFrame do
      before do
        @df = Daru::DataFrame.new({
          number: [1,2,3,4,5,6,Float::NAN],
          sym: [:one, :two, :three, :four, :five, :six, :seven],
          names: ['sameer', 'john', 'james', 'omisha', 'priyanka', 'shravan',nil]
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

      let(:dv) { Daru::Vector.new([1,11,32,Float::NAN,nil]) }
      it "handles empty data" do
        expect(dv.where(dv.lt(14))).to eq(Daru::Vector.new([1,11]))
      end

      it "does not give SystemStackError" do
        v = Daru::Vector.new [1]*300_000
        expect { v.where v.eq(1) }.not_to raise_error
      end
    end

    context Daru::Vector do
      context "non-categorical type" do
        before do
          @vector = Daru::Vector.new([2,5,1,22,51,4,nil,Float::NAN])
        end

        it "accepts a simple single statement" do
          expect(@vector.where(@vector.lt(10))).to eq(
            Daru::Vector.new([2,5,1,4], index: Daru::Index.new([0,1,2,5])))
        end

        it "accepts somewhat complex operator chaining" do
          expect(@vector.where((@vector.lt(6) | @vector.eq(51)))).to eq(
            Daru::Vector.new([2,5,1,51,4], index: Daru::Index.new([0,1,2,4,5])))
        end
      end

      context "categorical type" do
        let(:dv) { Daru::Vector.new ['a', 'c', 'x', 'x', 'c'],
          categories: ['a', 'x', 'c'], type: :category }

        context "simple single statement" do
          subject { dv.where(dv.lt('x')) }

          it { is_expected.to be_a Daru::Vector }
          its(:type) { is_expected.to eq :category }
          its(:to_a) { is_expected.to eq ['a'] }
          its(:'index.to_a') { is_expected.to eq [0] }
        end

        context "complex operator chaining" do
          subject { dv.where((dv.lt('x') | dv.eq('c'))) }

          it { is_expected.to be_a Daru::Vector }
          its(:type) { is_expected.to eq :category }
          its(:to_a) { is_expected.to eq ['a', 'c', 'c'] }
          its(:'index.to_a') { is_expected.to eq [0, 1, 4] }
        end

        context "preserve categories" do
          subject { dv.where((dv.lt('x') | dv.eq('c'))) }

          it { is_expected.to be_a Daru::Vector }
          its(:type) { is_expected.to eq :category }
          its(:to_a) { is_expected.to eq ['a', 'c', 'c'] }
          its(:'index.to_a') { is_expected.to eq [0, 1, 4] }
          its(:categories) { is_expected.to eq ['a', 'x', 'c'] }
        end
      end

      it "preserves name" do
        named_vector = Daru::Vector.new([1,2,3], name: 'named')
        expect(named_vector.where(named_vector.lteq(2)).name).to eq('named')
      end
    end
  end

  describe "apply_where" do
    context "matches regexp with block input" do
      subject { dv.apply_where(dv.match /weeks/) { |x| "#{x.split.first.to_i * 7} days" } }

      let(:dv) { Daru::Vector.new ['3 days', '5 weeks', '2 weeks'] }

      it { is_expected.to eq(Daru::Vector.new ['3 days', '35 days', '14 days']) }
    end
  end
end
