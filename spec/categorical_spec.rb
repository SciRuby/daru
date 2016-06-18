describe Daru::Vector, "categorical" do
  context "initialize" do
    context "default parameters" do
      let(:dv) { Daru::Vector.new [:a, 1, :a, 1, :c], type: :category }
      subject { dv }
      
      it { is_expected.to be_a Daru::Vector }
      its(:size) { is_expected.to eq 5 }
      its(:type) { is_expected.to eq :category }
      its(:ordered?) { is_expected.to eq false }
      its(:to_a) { is_expected.to eq [:a, 1, :a, 1, :c] }
      its(:base_category) { is_expected.to eq :a }
      its(:coding_scheme) { is_expected.to eq :dummy }
      its(:index) { is_expected.to be_a Daru::Index }
      its(:'index.to_a') { is_expected.to eq [0, 1, 2, 3, 4] }
    end
    
    context "with index" do
      context "as array" do
        let(:dv) do
          Daru::Vector.new [:a, 1, :a, 1, :c],
            type: :category,
            index: ['a', 'b', 'c', 'd', 'e']
        end
        subject { dv }
        
        its(:index) { is_expected.to be_a Daru::Index }
        its(:'index.to_a') { is_expected.to eq ['a', 'b', 'c', 'd', 'e'] }
      end
      
      context "as range" do
        let(:dv) do
          Daru::Vector.new [:a, 1, :a, 1, :c],
            type: :category,
            index: 'a'..'e'
        end
        subject { dv }
          
        its(:index) { is_expected.to be_a Daru::Index }
        its(:'index.to_a') { is_expected.to eq ['a', 'b', 'c', 'd', 'e'] }
      end
      
      context "as index object" do
        let(:tuples) do
          [
            [:one, :tin, :bar],
            [:one, :pin, :bar],
            [:two, :pin, :bar],
            [:two, :tin, :bar],
            [:thr, :pin, :foo]
          ]
        end
        let(:idx) { Daru::MultiIndex.from_tuples tuples }
        let(:dv) do
          Daru::Vector.new [:a, 1, :a, 1, :c],
            type: :category,
            index: idx
        end
        subject { dv }
        
        its(:index) { is_expected.to be_a Daru::MultiIndex }
        its(:'index.to_a') { is_expected.to eq tuples }
      end
      
      context "invalid index" do
        it { expect { Daru::Vector.new [1, 1, 2],
          type: :category,
          index: [1, 2]
        }.to raise_error ArgumentError }
      end
    end
    
    context "with categories" do
      context "extra categories" do
        subject { Daru::Vector.new [:a, 1, :a, 1, :c],
          type: :category, categories: [:a, :b, :c, 1] }
        
        it { is_expected.to be_a Daru::Vector }
        its(:type) { is_expected.to eq :category }
        its(:size) { is_expected.to eq 5 }
        its(:order) { is_expected.to eq [:a, :b, :c, 1] }
        its(:categories) { is_expected.to eq [:a, :b, :c, 1] }
      end
      
      context "incomplete" do
        it do
          expect { Daru::Vector.new [:a, 1, :a, 1, :c],
            type: :category, categories: [:b, :c, 1] }.
            to raise_error ArgumentError
        end
      end
    end
  end
  
  context "#cut" do
    let(:dv) { Daru::Vector.new [1, 2, 5, 14] }
    subject { dv.cut (0..20).step(5) }
    
    it { is_expected.to be_a Daru::Vector }
    its(:type) { is_expected.to eq :category }
    its(:size) { is_expected.to eq 4 }
    its(:categories) { is_expected.to eq ['0-4', '5-9', '10-14', '15-19'] }
    its(:to_a) { is_expected.to eq ['0-4', '0-4', '5-9', '10-14'] }
  end

  context "#each" do
    let(:dv) { Daru::Vector.new [:a, 1, :a, 1, :c] }
    subject { dv.each }
    
    it { is_expected.to be_a Enumerator }
    its(:to_a) { is_expected.to eq [:a, 1, :a, 1, :c] }
  end
  
  context "#to_a" do
    let(:dv) { Daru::Vector.new [:a, 1, :a, 1, :c] }
    subject { dv.to_a }
    
    it { is_expected.to be_a Array }
    its(:size) { is_expected.to eq 5 }
    it { is_expected.to eq [:a, 1, :a, 1, :c] }
  end
  
  context "#dup" do
    let(:dv) { Daru::Vector.new [:a, 1, :a, 1, :c], type: :category }
    before do
      dv.categories = [:a, :b, :c, 1]
      dv.name = 'daru'
      dv.ordered = true
    end
    subject { dv.dup }
    
    its(:type) { is_expected.to eq :category }
    its(:ordered?) { is_expected.to eq true }
    its(:categories) { is_expected.to eq [:a, :b, :c, 1] }
    its(:name) { is_expected.to eq 'daru' }
  end

  context "#add_category" do
    context "single category" do
      let(:dv) { Daru::Vector.new [:a, 1, :a, 1, :c], type: :category }
      subject { dv }
      before { dv.add_category :b }
      
      its(:categories) { is_expected.to eq [:a, 1, :c, :b] }
      its(:order) { is_expected.to eq [:a, 1, :c, :b] }
    end
    
    context "multiple categories" do
      let(:dv) { Daru::Vector.new [:a, 1, :a, 1, :c], type: :category }
      subject { dv }
      before { dv.add_category :b, :d }
      
      its(:categories) { is_expected.to eq [:a, 1, :c, :b, :d] }
      its(:order) { is_expected.to eq [:a, 1, :c, :b, :d] }
    end
  end
  
  context "count" do
    context "existant category" do
      context "more than 0" do
        subject(:dv) { Daru::Vector.new [:a, 1, :a, 1, :c], type: :category }
  
        it { expect(dv.count :a).to eq 2 }
      end
      
      context "equal to 0" do
        subject(:dv) { Daru::Vector.new [:a, 1, :a, 1, :c], type: :category }
        before { dv.add_category :b }
  
        it { expect(dv.count :b).to eq 0 }
      end
    end
    
    context "non existant category" do
      subject(:dv) { Daru::Vector.new [:a, 1, :a, 1, :c], type: :category }
      
      it { expect { dv.count :k }.to raise_error ArgumentError }
    end
  end

  context "#frequencies" do
    let(:dv) { Daru::Vector.new [:a, 1, :a, 1, :c],
      type: :category,
      categories: [:a, :b, :c, :d, 1] }
    subject { dv.frequencies }

    its(:'index.to_a') { is_expected.to eq [:a, :b, :c, :d, 1] }
    its(:to_a) { is_expected.to eq [2, 0, 1, 0, 2] }
  end

  context "#to_category" do
    let(:dv) { Daru::Vector.new [:a, 1, :a, 1, :c] }
    subject { dv.to_category }

    it { is_expected.to be_a Daru::Vector }
    its(:size) { is_expected.to eq 5 }
    its(:type) { is_expected.to eq :category }
    its(:ordered?) { is_expected.to eq false }
    its(:to_a) { is_expected.to eq [:a, 1, :a, 1, :c] }
  end
  
  context "#categories" do
    let(:dv) { Daru::Vector.new [:a, 1, :a, 1, :c], type: :category }
    subject { dv.categories }
    
    it { is_expected.to be_a Array }
    its(:size) { is_expected.to eq 3 }
    its(:'to_a') { is_expected.to eq [:a, 1, :c] }
  end
  
  context "#categories=" do
    context "extra categories" do
      subject { Daru::Vector.new [:a, 1, :a, 1, :c],
        type: :category }
      before { subject.categories = [:a, :b, :c, 1] }
      
      it { is_expected.to be_a Daru::Vector }
      its(:type) { is_expected.to eq :category }
      its(:categories) { is_expected.to eq [:a, :b, :c, 1] }
      its(:to_a) { is_expected.to eq [:a, 1, :a, 1, :c] }
    end
    
    context "incomplete" do
      subject { Daru::Vector.new [:a, 1, :a, 1, :c], type: :category }

      it do
        expect { subject.categories = [:b, :c, 1] }.
          to raise_error ArgumentError
      end
    end
  end
  
  context "#base_category" do
    let(:dv) { Daru::Vector.new [:a, 1, :a, 1, :c], type: :category }
    subject { dv }
    before { dv.base_category = 1 }
    
    its(:base_category) { is_expected.to eq 1 }
  end
  
  context "#coding_scheme" do
    context "valid coding scheme" do
      let(:dv) { Daru::Vector.new [:a, 1, :a, 1, :c], type: :category }
      subject { dv }
      before { dv.coding_scheme = :deviation }
      
      its(:coding_scheme) { is_expected.to eq :deviation }
    end
    
    context "invalid coding scheme" do
      let(:dv) { Daru::Vector.new [:a, 1, :a, 1, :c], type: :category }
      
      it { expect { dv.coding_scheme = :foo }.to raise_error ArgumentError }
    end
  end
  
  context "#rename_categories" do
    let(:dv) { Daru::Vector.new [:a, 1, :a, 1, :c], type: :category }
    subject { dv }
    before { dv.rename_categories :a => 1, 1 => 2 }
    
    its(:to_a) { is_expected.to eq [1, 2, 1, 2, :c] }
  end
  
  context "#min" do
    context "ordered" do
      context "default ordering" do
        let(:dv) { Daru::Vector.new [:a, 1, :a, 1, :c], type: :category, ordered: true }

        it { expect(dv.min).to eq :a }
      end
      
      context "reorder" do
        let(:dv) { Daru::Vector.new [:a, 1, :a, 1, :c], type: :category, ordered: true }
        before { dv.categories = [1, :a, :c] }
        
        it { expect(dv.min).to eq 1 }
      end
    end
    
    context "unordered" do
      let(:dv) { Daru::Vector.new [:a, 1, :a, 1, :c], type: :category }

      it { expect { dv.min }.to raise_error ArgumentError }
    end
  end

  context "#max" do
    context "ordered" do
      context "default ordering" do
        let(:dv) { Daru::Vector.new [:a, 1, :a, 1, :c], type: :category, ordered: true }

        it { expect(dv.max).to eq :c }
      end
      
      context "reorder" do
        let(:dv) { Daru::Vector.new [:a, 1, :a, 1, :c], type: :category, ordered: true }
        before { dv.categories = [1, :c, :a] }
        
        it { expect(dv.max).to eq :a }
      end
    end
    
    context "unordered" do
      let(:dv) { Daru::Vector.new [:a, 1, :a, 1, :c, :a], type: :category }

      it { expect { dv.max }.to raise_error ArgumentError }
    end
  end
  
  context "summary" do
    let(:dv) { Daru::Vector.new [:a, 1, :a, 1, :c, :a], type: :category }
    subject { dv.summary }
    
    it { is_expected.to be_a Daru::Vector }
    its(:categories) { is_expected.to eq 3 }
    its(:max_freq) { is_expected.to eq 3 }
    its(:max_category) { is_expected.to eq :a }
    its(:min_freq) { is_expected.to eq 1 }
    its(:min_category) { is_expected.to eq :c }
  end
  
  context "#sort!" do
    let(:dv) { Daru::Vector.new [:a, 1, :a, 1, :c], type: :category, ordered: true }
    subject { dv }
    before { dv.categories = [:c, :a, 1]; dv.sort! }
    
    it { is_expected.to be_a Daru::Vector }
    its(:size) { is_expected.to eq 5 }
    its(:to_a) { is_expected.to eq [:c, :a, :a, 1, 1] }
    its(:'index.to_a') { is_expected.to eq [4, 0, 2, 1, 3] }
  end
  
  context "#[]" do
    context Daru::Index do
      before :each do
        @dv = Daru::Vector.new [1,2,3,4,5], name: :yoga, metadata: { cdc_type: 2 },
          index: [:yoda, :anakin, :obi, :padme, :r2d2], type: :category
      end

      it "returns an element after passing an index" do
        expect(@dv[:yoda]).to eq(1)
      end

      it "returns an element after passing a numeric index" do
        expect(@dv[0]).to eq(1)
      end

      it "returns a vector with given indices for multiple indices" do
        expect(@dv[:yoda, :anakin]).to eq(Daru::Vector.new([1,2], name: :yoda,
          index: [:yoda, :anakin], type: :category))
      end

      it "returns a vector with given indices for multiple numeric indices" do
        expect(@dv[0,1]).to eq(Daru::Vector.new([1,2], name: :yoda,
          index: [:yoda, :anakin], type: :category))
      end

      it "returns a vector when specified symbol Range" do
        expect(@dv[:yoda..:anakin]).to eq(Daru::Vector.new([1,2],
          index: [:yoda, :anakin], name: :yoga, type: :category))
      end

      it "returns a vector when specified numeric Range" do
        expect(@dv[3..4]).to eq(Daru::Vector.new([4,5], name: :yoga,
          index: [:padme, :r2d2], type: :category))
      end

      it "returns correct results for index of multiple index" do
        v = Daru::Vector.new([1,2,3,4], index: ['a','c',1,:a], type: :category)
        expect(v['a']).to eq(1)
        expect(v[:a]).to eq(4)
        expect(v[1]).to eq(3)
        expect(v[0]).to eq(1)
      end

      it "raises exception for invalid index" do
        expect { @dv[:foo] }.to raise_error(IndexError)
        expect { @dv[:obi, :foo] }.to raise_error(IndexError)
      end

      it "retains the original vector metadata" do
        expect(@dv[:yoda, :anakin].metadata).to eq({ cdc_type: 2 })
      end
    end

    context Daru::MultiIndex do
      before do
        @tuples = [
          [:a,:one,:bar],
          [:a,:one,:baz],
          [:a,:two,:bar],
          [:a,:two,:baz],
          [:b,:one,:bar],
          [:b,:two,:bar],
          [:b,:two,:baz],
          [:b,:one,:foo],
          [:c,:one,:bar],
          [:c,:one,:baz],
          [:c,:two,:foo],
          [:c,:two,:bar],
          [:d,:one,:foo]
        ]
        @multi_index = Daru::MultiIndex.from_tuples(@tuples)
        @vector = Daru::Vector.new(
          Array.new(13) { |i| i }, index: @multi_index,
          name: :mi_vector, type: :category)
      end

      it "returns a single element when passed a row number" do
        expect(@vector[1]).to eq(1)
      end

      it "returns a single element when passed the full tuple" do
        expect(@vector[:a, :one, :baz]).to eq(1)
      end

      it "returns sub vector when passed first layer of tuple" do
        mi = Daru::MultiIndex.from_tuples([
          [:one,:bar],
          [:one,:baz],
          [:two,:bar],
          [:two,:baz]])
        expect(@vector[:a]).to eq(Daru::Vector.new([0,1,2,3], index: mi,
          name: :sub_vector, type: :category))
      end

      it "returns sub vector when passed first and second layer of tuple" do
        mi = Daru::MultiIndex.from_tuples([
          [:foo],
          [:bar]])
        expect(@vector[:c,:two]).to eq(Daru::Vector.new([10,11], index: mi,
          name: :sub_sub_vector, type: :category))
      end

      it "returns sub vector not a single element when passed the partial tuple" do
        mi = Daru::MultiIndex.from_tuples([[:foo]])
        expect(@vector[:d, :one]).to eq(Daru::Vector.new([12], index: mi,
          name: :sub_sub_vector, type: :category))
      end

      it "returns a vector with corresponding MultiIndex when specified numeric Range" do
        mi = Daru::MultiIndex.from_tuples([
          [:a,:two,:baz],
          [:b,:one,:bar],
          [:b,:two,:bar],
          [:b,:two,:baz],
          [:b,:one,:foo],
          [:c,:one,:bar],
          [:c,:one,:baz]
        ])
        expect(@vector[3..9]).to eq(Daru::Vector.new([3,4,5,6,7,8,9], index: mi,
          name: :slice, type: :category))
      end

      it "raises exception for invalid index" do
        expect { @vector[:foo] }.to raise_error(IndexError)
        expect { @vector[:a, :two, :foo] }.to raise_error(IndexError)
        expect { @vector[:x, :one] }.to raise_error(IndexError)
      end
    end

    context Daru::CategoricalIndex do
      context "non-numerical index" do
        let (:idx) { Daru::CategoricalIndex.new [:a, :b, :a, :a, :c] }
        let (:dv)  { Daru::Vector.new 'a'..'e', index: idx, type: :category }

        context "single category" do
          context "multiple instances" do
            subject { dv[:a] }

            it { is_expected.to be_a Daru::Vector }
            its(:type) { is_expected.to eq :category }
            its(:size) { is_expected.to eq 3 }
            its(:to_a) { is_expected.to eq  ['a', 'c', 'd'] }
            its(:index) { is_expected.to eq(
              Daru::CategoricalIndex.new([:a, :a, :a])) }
          end

          context "single instance" do
            subject { dv[:c] }

            it { is_expected.to eq 'e' }
          end
        end

        context "multiple categories" do
          subject { dv[:a, :c] }

          it { is_expected.to be_a Daru::Vector }
          its(:type) { is_expected.to eq :category }
          its(:size) { is_expected.to eq 4 }
          its(:to_a) { is_expected.to eq  ['a', 'c', 'd', 'e'] }
          its(:index) { is_expected.to eq(
            Daru::CategoricalIndex.new([:a, :a, :a, :c])) }
        end

        context "multiple positional indexes" do
          subject { dv[0, 1, 2] }

          it { is_expected.to be_a Daru::Vector }
          its(:type) { is_expected.to eq :category }
          its(:size) { is_expected.to eq 3 }
          its(:to_a) { is_expected.to eq ['a', 'b', 'c'] }
          its(:index) { is_expected.to eq(
            Daru::CategoricalIndex.new([:a, :b, :a])) }
        end

        context "single positional index" do
          subject { dv[1] }

          it { is_expected.to eq 'b' }
        end

        context "invalid category" do
          it { expect { dv[:x] }.to raise_error IndexError }
        end

        context "invalid positional index" do
          it { expect { dv[30] }.to raise_error IndexError }
        end
      end

      context "numerical index" do
        let (:idx) { Daru::CategoricalIndex.new [1, 1, 2, 2, 3] }
        let (:dv)  { Daru::Vector.new 'a'..'e', index: idx, type: :category }

        context "single category" do
          context "multiple instances" do
            subject { dv[1] }

            it { is_expected.to be_a Daru::Vector }
            its(:type) { is_expected.to eq :category }
            its(:size) { is_expected.to eq 2 }
            its(:to_a) { is_expected.to eq  ['a', 'b'] }
            its(:index) { is_expected.to eq(
              Daru::CategoricalIndex.new([1, 1])) }
          end

          context "single instance" do
            subject { dv[3] }

            it { is_expected.to eq 'e' }
          end
        end
      end
    end
  end

  context "#[]=" do
    context Daru::Index do
      before :each do
        @dv = Daru::Vector.new [1,2,3,4,5], name: :yoga,
          index: [:yoda, :anakin, :obi, :padme, :r2d2], type: :category
        @dv.add_category 666
      end

      it "assigns at the specified index" do
        @dv[:yoda] = 666
        expect(@dv[:yoda]).to eq(666)
      end

      it "assigns at the specified Integer index" do
        @dv[0] = 666
        expect(@dv[:yoda]).to eq(666)
      end

      it "assigns correctly for a mixed index Vector" do
        v = Daru::Vector.new [1,2,3,4], index: ['a',:a,0,66], type: :category
        v.add_category 666
        v['a'] = 666
        expect(v['a']).to eq(666)

        v[0] = 666
        expect(v[0]).to eq(666)

        v[3] = 666
        expect(v[3]).to eq(666)

        expect(v).to eq(Daru::Vector.new([666,2,666,666],
          index: ['a',:a,0,66], type: :category))
      end
    end

    context Daru::MultiIndex do
      before :each do
        @tuples = [
          [:a,:one,:bar],
          [:a,:one,:baz],
          [:a,:two,:bar],
          [:a,:two,:baz],
          [:b,:one,:bar],
          [:b,:two,:bar],
          [:b,:two,:baz],
          [:b,:one,:foo],
          [:c,:one,:bar],
          [:c,:one,:baz],
          [:c,:two,:foo],
          [:c,:two,:bar]
        ]
        @multi_index = Daru::MultiIndex.from_tuples(@tuples)
        @vector = Daru::Vector.new Array.new(12) { |i| i }, index: @multi_index,
          type: :category, name: :mi_vector
        @vector.add_category 69
      end

      it "assigns all lower layer indices when specified a first layer index" do
        @vector[:b] = 69
        expect(@vector).to eq(Daru::Vector.new([0,1,2,3,69,69,69,69,8,9,10,11],
          index: @multi_index, name: :top_layer_assignment, type: :category
          ))
      end

      it "assigns all lower indices when specified first and second layer index" do
        @vector[:b, :one] = 69
        expect(@vector).to eq(Daru::Vector.new([0,1,2,3,69,5,6,69,8,9,10,11],
          index: @multi_index, name: :second_layer_assignment, type: :category))
      end

      it "assigns just the precise value when specified complete tuple" do
        @vector[:b, :one, :foo] = 69
        expect(@vector).to eq(Daru::Vector.new([0,1,2,3,4,5,6,69,8,9,10,11],
          index: @multi_index, name: :precise_assignment, type: :category))
      end

      it "assigns correctly when numeric index" do
        @vector[7] = 69
        expect(@vector).to eq(Daru::Vector.new([0,1,2,3,4,5,6,69,8,9,10,11],
          index: @multi_index, name: :precise_assignment, type: :category))
      end

      it "fails predictably on unknown index" do
        expect { @vector[:d] = 69 }.to raise_error(IndexError)
        expect { @vector[:b, :three] = 69 }.to raise_error(IndexError)
        expect { @vector[:b, :two, :test] = 69 }.to raise_error(IndexError)
      end
    end
    
    context Daru::CategoricalIndex do
      context "non-numerical index" do
        let (:idx) { Daru::CategoricalIndex.new [:a, :b, :a, :a, :c] }
        let (:dv)  { Daru::Vector.new 'a'..'e', index: idx, type: :category }
        before { dv.add_category 'x' }

        context "single category" do
          context "multiple instances" do
            subject { dv }
            before { dv[:a] = 'x' }

            its(:size) { is_expected.to eq 5 }
            its(:to_a) { is_expected.to eq  ['x', 'b', 'x', 'x', 'e'] }
            its(:index) { is_expected.to eq idx }
          end

          context "single instance" do
            subject { dv }
            before { dv[:b] = 'x' }

            its(:size) { is_expected.to eq 5 }
            its(:to_a) { is_expected.to eq  ['a', 'x', 'c', 'd', 'e'] }
            its(:index) { is_expected.to eq idx }
          end
        end

        context "multiple categories" do
          subject { dv }
          before { dv[:a, :c] = 'x' }

          its(:size) { is_expected.to eq 5 }
          its(:to_a) { is_expected.to eq  ['x', 'b', 'x', 'x', 'x'] }
          its(:index) { is_expected.to eq idx }
        end

        context "multiple positional indexes" do
          subject { dv }
          before { dv[0, 1, 2] = 'x' }

          its(:size) { is_expected.to eq 5 }
          its(:to_a) { is_expected.to eq ['x', 'x', 'x', 'd', 'e'] }
          its(:index) { is_expected.to eq idx }
        end

        context "single positional index" do
          subject { dv }
          before { dv[1] = 'x' }

          its(:size) { is_expected.to eq 5 }
          its(:to_a) { is_expected.to eq ['a', 'x', 'c', 'd', 'e'] }
          its(:index) { is_expected.to eq idx }
        end

        context "invalid category" do
          it { expect { dv[:x] = 'x' }.to raise_error IndexError }
        end

        context "invalid positional index" do
          it { expect { dv[30] = 'x'}.to raise_error IndexError }
        end
      end

      context "numerical index" do
        let (:idx) { Daru::CategoricalIndex.new [1, 1, 2, 2, 3] }
        let (:dv)  { Daru::Vector.new 'a'..'e', index: idx, type: :category }
        before { dv.add_category 'x' }

        context "single category" do
          subject { dv }
          before { dv[1] = 'x' }

          its(:size) { is_expected.to eq 5 }
          its(:to_a) { is_expected.to eq ['x', 'x', 'c', 'd', 'e'] }
          its(:index) { is_expected.to eq idx }
        end
        
        context "multiple categories" do
          subject { dv }
          before { dv[1, 2] = 'x' }

          its(:size) { is_expected.to eq 5 }
          its(:to_a) { is_expected.to eq ['x', 'x', 'x', 'x', 'e'] }
          its(:index) { is_expected.to eq idx }              
        end
      end
    end
  end
  
  context "#at" do
    context Daru::Index do
      let (:idx) { Daru::Index.new [1, 0, :c] }
      let (:dv) { Daru::Vector.new ['a', 'b', 'c'], index: idx, type: :category }
      
      context "single position" do
        it { expect(dv.at 1).to eq 'b' }
      end
      
      context "multiple positions" do
        subject { dv.at 0, 2 }
        
        it { is_expected.to be_a Daru::Vector }
        its(:type) { is_expected.to eq :category }
        its(:size) { is_expected.to eq 2 }
        its(:to_a) { is_expected.to eq ['a', 'c'] }
        its(:'index.to_a') { is_expected.to eq [1, :c] }
      end
      
      context "invalid position" do
        it { expect { dv.at 3 }.to raise_error IndexError }
      end
      
      context "invalid positions" do
        it { expect { dv.at 2, 3 }.to raise_error IndexError }
      end
      
      context "range" do
        subject { dv.at 0..1 }
        
        it { is_expected.to be_a Daru::Vector }
        its(:type) { is_expected.to eq :category }
        its(:size) { is_expected.to eq 2 }
        its(:to_a) { is_expected.to eq ['a', 'b'] }
        its(:'index.to_a') { is_expected.to eq [1, 0] }            
      end
      
      context "range with negative end" do
        subject { dv.at 0..-2 }
        
        it { is_expected.to be_a Daru::Vector }
        its(:type) { is_expected.to eq :category }
        its(:size) { is_expected.to eq 2 }
        its(:to_a) { is_expected.to eq ['a', 'b'] }
        its(:'index.to_a') { is_expected.to eq [1, 0] }              
      end
      
      context "range with single element" do
        subject { dv.at 0..0 }
        
        it { is_expected.to be_a Daru::Vector }
        its(:type) { is_expected.to eq :category }
        its(:size) { is_expected.to eq 1 }
        its(:to_a) { is_expected.to eq ['a'] }
        its(:'index.to_a') { is_expected.to eq [1] }
      end
    end
    
    context Daru::MultiIndex do
      let (:idx) do
        Daru::MultiIndex.from_tuples [
          [:a,:one,:bar],
          [:a,:one,:baz],
          [:b,:two,:bar],
          [:a,:two,:baz],
        ]
      end
      let (:dv) { Daru::Vector.new 1..4, index: idx, type: :category }
      
      context "single position" do
        it { expect(dv.at 1).to eq 2 }
      end
      
      context "multiple positions" do
        subject { dv.at 2, 3 }
        
        it { is_expected.to be_a Daru::Vector }
        its(:type) { is_expected.to eq :category }
        its(:size) { is_expected.to eq 2 }
        its(:to_a) { is_expected.to eq [3, 4] }
        its(:'index.to_a') { is_expected.to eq [[:b, :two, :bar], 
          [:a, :two, :baz]] }
      end
      
      context "invalid position" do
        it { expect { dv.at 4 }.to raise_error IndexError }
      end
      
      context "invalid positions" do
        it { expect { dv.at 2, 4 }.to raise_error IndexError }
      end
      
      context "range" do
        subject { dv.at 2..3 }
        
        it { is_expected.to be_a Daru::Vector }
        its(:type) { is_expected.to eq :category }
        its(:size) { is_expected.to eq 2 }
        its(:to_a) { is_expected.to eq [3, 4] }
        its(:'index.to_a') { is_expected.to eq [[:b, :two, :bar], 
          [:a, :two, :baz]] }            
      end
      
      context "range with negative end" do
        subject { dv.at 2..-1 }
        
        it { is_expected.to be_a Daru::Vector }
        its(:type) { is_expected.to eq :category }
        its(:size) { is_expected.to eq 2 }
        its(:to_a) { is_expected.to eq [3, 4] }
        its(:'index.to_a') { is_expected.to eq [[:b, :two, :bar], 
          [:a, :two, :baz]] }                 
      end
      
      context "range with single element" do
        subject { dv.at 2..2 }
        
        it { is_expected.to be_a Daru::Vector }
        its(:type) { is_expected.to eq :category }
        its(:size) { is_expected.to eq 1 }
        its(:to_a) { is_expected.to eq [3] }
        its(:'index.to_a') { is_expected.to eq [[:b, :two, :bar]] }   
      end
    end

    context Daru::CategoricalIndex do
      let (:idx) { Daru::CategoricalIndex.new [:a, 1, 1, :a, :c] }
      let (:dv)  { Daru::Vector.new 'a'..'e', index: idx, type: :category }

      context "multiple positional indexes" do
        subject { dv.at 0, 1, 2 }

        it { is_expected.to be_a Daru::Vector }
        its(:type) { is_expected.to eq :category }
        its(:size) { is_expected.to eq 3 }
        its(:to_a) { is_expected.to eq ['a', 'b', 'c'] }
        its(:index) { is_expected.to eq(
          Daru::CategoricalIndex.new([:a, 1, 1])) }
      end

      context "single positional index" do
        subject { dv.at 1 }

        it { is_expected.to eq 'b' }
      end
      
      context "invalid position" do
        it { expect { dv.at 5 }.to raise_error IndexError }
      end
      
      context "invalid positions" do
        it { expect { dv.at 2, 5 }.to raise_error IndexError }
      end
      
      context "range" do
        subject { dv.at 0..2 }

        it { is_expected.to be_a Daru::Vector }
        its(:type) { is_expected.to eq :category }
        its(:size) { is_expected.to eq 3 }
        its(:to_a) { is_expected.to eq ['a', 'b', 'c'] }
        its(:index) { is_expected.to eq(
          Daru::CategoricalIndex.new([:a, 1, 1])) }            
      end
      
      context "range with negative end" do
        subject { dv.at 0..-3 }

        it { is_expected.to be_a Daru::Vector }
        its(:type) { is_expected.to eq :category }
        its(:size) { is_expected.to eq 3 }
        its(:to_a) { is_expected.to eq ['a', 'b', 'c'] }
        its(:index) { is_expected.to eq(
          Daru::CategoricalIndex.new([:a, 1, 1])) }            
      end
      
      context "range with single element" do
        subject { dv.at 0..0 }

        it { is_expected.to be_a Daru::Vector }
        its(:type) { is_expected.to eq :category }
        its(:size) { is_expected.to eq 1 }
        its(:to_a) { is_expected.to eq ['a'] }
        its(:index) { is_expected.to eq(
          Daru::CategoricalIndex.new([:a])) }            
      end
    end
  end

  context "#set_at" do
    context Daru::Index do
      let (:idx) { Daru::Index.new [1, 0, :c] }
      let (:dv) { Daru::Vector.new ['a', 'b', 'c'], index: idx, type: :category }
      before { dv.add_category 'x' }
      
      context "single position" do
        subject { dv }
        before { dv.set_at [1], 'x' }

        its(:to_a) { is_expected.to eq ['a', 'x', 'c'] }
      end
      
      context "multiple positions" do
        subject { dv }
        before { dv.set_at [0, 2], 'x' }
        
        its(:to_a) { is_expected.to eq ['x', 'b', 'x'] }
      end
      
      context "invalid position" do
        it { expect { dv.set_at [3], 'x' }.to raise_error IndexError }
      end
      
      context "invalid positions" do
        it { expect { dv.set_at [2, 3], 'x' }.to raise_error IndexError }
      end
    end
    
    context Daru::MultiIndex do
      let(:idx) do
        Daru::MultiIndex.from_tuples [
          [:a,:one,:bar],
          [:a,:one,:baz],
          [:b,:two,:bar],
          [:a,:two,:baz],
        ]
      end
      let(:dv) { Daru::Vector.new 1..4, index: idx, type: :category }
      before { dv.add_category 'x' }
      
      context "single position" do
        subject { dv }
        before { dv.set_at [1], 'x' }

        its(:to_a) { is_expected.to eq [1, 'x', 3, 4] }
      end
      
      context "multiple positions" do
        subject { dv }
        before { dv.set_at [2, 3], 'x' }

        its(:to_a) { is_expected.to eq [1, 2, 'x', 'x'] }
      end
      
      context "invalid position" do
        it { expect { dv.set_at [4], 'x' }.to raise_error IndexError }
      end
      
      context "invalid positions" do
        it { expect { dv.set_at [2, 4], 'x' }.to raise_error IndexError }
      end          
    end

    context Daru::CategoricalIndex do
      let (:idx) { Daru::CategoricalIndex.new [:a, 1, 1, :a, :c] }
      let (:dv)  { Daru::Vector.new 'a'..'e', index: idx, type: :category }
      before { dv.add_category 'x' }

      context "multiple positional indexes" do
        subject { dv }
        before { dv.set_at [0, 1, 2], 'x' }

        its(:to_a) { is_expected.to eq ['x', 'x', 'x', 'd', 'e'] }
      end

      context "single positional index" do
        subject { dv }
        before { dv.set_at [1], 'x' }

        its(:to_a) { is_expected.to eq ['a', 'x', 'c', 'd', 'e'] }
      end
      
      context "invalid position" do
        it { expect { dv.set_at [5], 'x' }.to raise_error IndexError }
      end
      
      context "invalid positions" do
        it { expect { dv.set_at [2, 5], 'x' }.to raise_error IndexError }
      end
    end
  end  

  context "#contrast_code" do
    context "dummy coding" do
      context "default base category" do
        let(:dv) { Daru::Vector.new [:a, 1, :a, 1, :c], type: :category, name: 'abc' }
        subject { dv.contrast_code }
        
        it { is_expected.to be_a Daru::DataFrame }
        its(:shape) { is_expected.to eq [5, 2] }
        its(:'abc_1.to_a') { is_expected.to eq [0, 1, 0, 1, 0] }
        its(:'abc_c.to_a') { is_expected.to eq [0, 0, 0, 0, 1] }
      end
      
      context "manual base category" do
        let(:dv) { Daru::Vector.new [:a, 1, :a, 1, :c], type: :category, name: 'abc' }
        before { dv.base_category = :c }
        subject { dv.contrast_code }
        
        it { is_expected.to be_a Daru::DataFrame }
        its(:shape) { is_expected.to eq [5, 2] }
        its(:'abc_a.to_a') { is_expected.to eq [1, 0, 1, 0, 0] }
        its(:'abc_1.to_a') { is_expected.to eq [0, 1, 0, 1, 0] }        
      end
    end
    
    context "simple coding" do
      context "default base category" do
        let(:dv) { Daru::Vector.new [:a, 1, :a, 1, :c], type: :category, name: 'abc' }
        subject { dv.contrast_code }
        before { dv.coding_scheme = :simple }
        
        it { is_expected.to be_a Daru::DataFrame }
        its(:shape) { is_expected.to eq [5, 2] }
        its(:'abc_1.to_a') { is_expected.to eq [-1/3.0, 2/3.0, -1/3.0, 2/3.0, -1/3.0] }
        its(:'abc_c.to_a') { is_expected.to eq [-1/3.0, -1/3.0, -1/3.0, -1/3.0, 2/3.0] }
      end
      
      context "manual base category" do
        let(:dv) { Daru::Vector.new [:a, 1, :a, 1, :c], type: :category, name: 'abc' }
        subject { dv.contrast_code }
        before do
          dv.coding_scheme = :simple
          dv.base_category = :c
        end
        
        it { is_expected.to be_a Daru::DataFrame }
        its(:shape) { is_expected.to eq [5, 2] }
        its(:'abc_a.to_a') { is_expected.to eq [2/3.0, -1/3.0, 2/3.0, -1/3.0, -1/3.0] }
        its(:'abc_1.to_a') { is_expected.to eq [-1/3.0, 2/3.0, -1/3.0, 2/3.0, -1/3.0] }
      end
    end

    context "helmert coding" do
      let(:dv) { Daru::Vector.new [:a, 1, :a, 1, :c], type: :category, name: 'abc' }
      subject { dv.contrast_code }
      before { dv.coding_scheme = :helmert }

      it { is_expected.to be_a Daru::DataFrame }
      its(:shape) { is_expected.to eq [5, 2] }
      its(:'abc_a.to_a') { is_expected.to eq [2/3.0, -1/3.0, 2/3.0, -1/3.0, -1/3.0] }
      its(:'abc_1.to_a') { is_expected.to eq [0, 1/2.0, 0, 1/2.0, -1/2.0] }
    end

    context "deviation coding" do
      let(:dv) { Daru::Vector.new [:a, 1, :a, 1, :c], type: :category, name: 'abc' }
      subject { dv.contrast_code }
      before { dv.coding_scheme = :deviation }

      it { is_expected.to be_a Daru::DataFrame }
      its(:shape) { is_expected.to eq [5, 2] }
      its(:'abc_a.to_a') { is_expected.to eq [1, 0, 1, 0, -1] }
      its(:'abc_1.to_a') { is_expected.to eq [0, 1, 0, 1, -1] }
    end
  end

  context '#inspect' do
    context 'simple' do
      subject(:vector) { Daru::Vector.new [1,2,3],
        index: [:a, :b, :c], name: 'test', type: :category }
      its(:inspect) { is_expected.to eq %Q{
        |#<Daru::Vector(3)>
        |      test
        |    a    1
        |    b    2
        |    c    3
      }.unindent }
    end

    context 'no name' do
      subject(:vector) { Daru::Vector.new [1,2,3], index: [:a, :b, :c], type: :category }
      its(:inspect) { is_expected.to eq %Q{
        |#<Daru::Vector(3)>
        |   a   1
        |   b   2
        |   c   3
      }.unindent }
    end

    context 'with nils' do
      subject(:vector) { Daru::Vector.new [1,nil,3],
        index: [:a, :b, :c], name: 'test', type: :category }
      its(:inspect) { is_expected.to eq %Q{
        |#<Daru::Vector(3)>
        |      test
        |    a    1
        |    b  nil
        |    c    3
      }.unindent }
    end

    context 'with metadata' do
      subject(:vector) { Daru::Vector.new [1,2,3],
        index: [:a, :b, :c], name: 'test', metadata: {hey: 'JUDE!'}, type: :category }
      its(:inspect) { is_expected.to eq %Q{
        |#<Daru::Vector(3){:hey=>"JUDE!"}>
        |      test
        |    a    1
        |    b    2
        |    c    3
      }.unindent }
    end

    context 'very large amount of data' do
      subject(:vector) { Daru::Vector.new [1,2,3] * 100, name: 'test', type: :category }
      its(:inspect) { is_expected.to eq %Q{
        |#<Daru::Vector(300)>
        |      test
        |    0    1
        |    1    2
        |    2    3
        |    3    1
        |    4    2
        |    5    3
        |    6    1
        |    7    2
        |    8    3
        |    9    1
        |   10    2
        |   11    3
        |   12    1
        |   13    2
        |   14    3
        |  ...  ...
      }.unindent }
    end

    context 'really long name or data' do
      subject(:vector) { Daru::Vector.new [1,2,'this is ridiculously long'],
        index: [:a, :b, :c], name: 'and this is not much better faithfully',
        type: :category
      }
      its(:inspect) { is_expected.to eq %Q{
        |#<Daru::Vector(3)>
        |                      and this is not much
        |                    a                    1
        |                    b                    2
        |                    c this is ridiculously
      }.unindent }
    end

    context 'with multiindex' do
      subject(:vector) {
        Daru::Vector.new(
          [1,2,3,4,5,6,7],
          name: 'test',
          type: :category,
          index: Daru::MultiIndex.from_tuples([
              %w[foo one],
              %w[foo two],
              %w[foo three],
              %w[bar one],
              %w[bar two],
              %w[bar three],
              %w[baz one],
           ]),
        )
      }

      its(:inspect) { is_expected.to eq %Q{
        |#<Daru::Vector(7)>
        |              test
        |   foo   one     1
        |         two     2
        |       three     3
        |   bar   one     4
        |         two     5
        |       three     6
        |   baz   one     7
      }.unindent}
    end

    context 'threshold and spacing settings' do
    end
  end

  context '#to_html' do
    let(:doc) { Nokogiri::HTML(vector.to_html) }
    subject(:table) { doc.at('table') }
    let(:header) { table.at('tr:first-child > th:first-child') }

    context 'simple' do
      let(:vector) { Daru::Vector.new [1,nil,3],
        index: [:a, :b, :c], name: 'test', type: :category }
      it { is_expected.not_to be_nil }

      describe 'header' do
        subject { header }
        it { is_expected.not_to be_nil }
        its(['colspan']) { is_expected.to eq '2' }
        its(:text) { is_expected.to eq "Daru::Vector(3)" }
      end

      describe 'name' do
        subject(:name) { table.at('tr:nth-child(2) > th:nth-child(2)') }
        it { is_expected.not_to be_nil }
        its(:text) { is_expected.to eq 'test' }

        context 'withought name' do
          let(:vector) { Daru::Vector.new [1,nil,3], index: [:a, :b, :c], type: :category }

          it { is_expected.to be_nil }
        end
      end

      describe 'index' do
        subject(:indexes) { table.search('tr > td:first-child').map(&:text) }
        its(:count) { is_expected.to eq vector.size }
        it { is_expected.to eq vector.index.to_a.map(&:to_s) }
      end

      describe 'values' do
        subject(:indexes) { table.search('tr > td:last-child').map(&:text) }
        its(:count) { is_expected.to eq vector.size }
        it { is_expected.to eq vector.to_a.map(&:to_s) }
      end
    end

    context 'large vector' do
      subject(:vector) { Daru::Vector.new [1,2,3] * 100, name: 'test', type: :category }
      it 'has only 30 rows (+ 2 header rows, + 2 finishing rows)' do
        expect(table.search('tr').size).to eq 34
      end

      describe '"skipped" row' do
        subject(:row) { table.search('tr:nth-child(33) td').map(&:text) }
        its(:count) { is_expected.to eq 2 }
        it { is_expected.to eq ['...', '...'] }
      end

      describe 'last row' do
        subject(:row) { table.search('tr:nth-child(34) td').map(&:text) }
        its(:count) { is_expected.to eq 2 }
        it { is_expected.to eq ['299', '3'] }
      end
    end

    context 'multi-index' do
      subject(:vector) {
        Daru::Vector.new(
          [1,2,3,4,5,6,7],
          name: 'test',
          type: :category,
          index: Daru::MultiIndex.from_tuples([
              %w[foo one],
              %w[foo two],
              %w[foo three],
              %w[bar one],
              %w[bar two],
              %w[bar three],
              %w[baz one],
           ]),
        )
      }

      describe 'header' do
        subject { header }
        it { is_expected.not_to be_nil }
        its(['colspan']) { is_expected.to eq '3' }
        its(:text) { is_expected.to eq "Daru::Vector(7)" }
      end

      describe 'name row' do
        subject(:row) { table.at('tr:nth-child(2)').search('th') }
        its(:count) { should == 2 }
        it { expect(row.first['colspan']).to eq '2' }
      end

      describe 'first data row' do
        let(:row) { table.at('tr:nth-child(3)') }
        subject { row.inner_html.scan(/<t[dh].+?<\/t[dh]>/) }
        it { is_expected.to eq [
          '<th rowspan="3">foo</th>',
          '<th rowspan="1">one</th>',
          '<td>1</td>'
        ]}
      end
    end
  end
end

describe Daru::DataFrame, "categorical" do
  context "#to_category" do
    let(:df) do
      Daru::DataFrame.new({
        a: [1, 2, 3, 4, 5],
        b: ['first', 'second', 'first', 'second', 'third'],
        c: ['a', 'b', 'a', 'b', 'c']
      })
    end
    before { df.to_category :b, :c }
    subject { df }
    
    it { is_expected.to be_a Daru::DataFrame }
    its(:'b.type') { is_expected.to eq :category }
    its(:'c.type') { is_expected.to eq :category }
  end
  
  context "#interact_code" do
    context "two vectors" do
      let(:df) do
        Daru::DataFrame.new({
          a: [1, 2, 3, 4, 5],
          b: ['first', 'second', 'first', 'second', 'third'],
          c: ['a', 'b', 'a', 'b', 'c']
        })
      end
      before do
        df.to_category :b, :c
        df[:b].categories = ['first', 'second', 'third']
        df[:c].categories = ['a', 'b', 'c']
      end
  
      context "both full" do
        subject { df.interact_code [:b, :c], [true, true] }
        
        it { is_expected.to be_a Daru::DataFrame }
        its(:shape) { is_expected.to eq [5, 9] }
        it { expect(subject['b_first:c_a'].to_a).to eq [1, 0, 1, 0, 0] }
        it { expect(subject['b_first:c_b'].to_a).to eq [0, 0, 0, 0, 0] }
        it { expect(subject['b_first:c_c'].to_a).to eq [0, 0, 0, 0, 0] }
        it { expect(subject['b_second:c_a'].to_a).to eq [0, 0, 0, 0, 0] }
        it { expect(subject['b_second:c_b'].to_a).to eq [0, 1, 0, 1, 0] }
        it { expect(subject['b_second:c_c'].to_a).to eq [0, 0, 0, 0, 0] }
        it { expect(subject['b_third:c_a'].to_a).to eq [0, 0, 0, 0, 0] }
        it { expect(subject['b_third:c_b'].to_a).to eq [0, 0, 0, 0, 0] }
        it { expect(subject['b_third:c_c'].to_a).to eq [0, 0, 0, 0, 1] }
      end
  
      context "one full" do
        subject { df.interact_code [:b, :c], [true, false] }
        
        it { is_expected.to be_a Daru::DataFrame }
        its(:shape) { is_expected.to eq [5, 6] }
        it { expect(subject['b_first:c_b'].to_a).to eq [0, 0, 0, 0, 0] }
        it { expect(subject['b_first:c_c'].to_a).to eq [0, 0, 0, 0, 0] }
        it { expect(subject['b_second:c_b'].to_a).to eq [0, 1, 0, 1, 0] }
        it { expect(subject['b_second:c_c'].to_a).to eq [0, 0, 0, 0, 0] }
        it { expect(subject['b_third:c_b'].to_a).to eq [0, 0, 0, 0, 0] }
        it { expect(subject['b_third:c_c'].to_a).to eq [0, 0, 0, 0, 1] }
      end
  
      context "none full" do
        subject { df.interact_code [:b, :c], [false, false] }
        
        it { is_expected.to be_a Daru::DataFrame }
        its(:shape) { is_expected.to eq [5, 4] }
        it { expect(subject['b_second:c_b'].to_a).to eq [0, 1, 0, 1, 0] }
        it { expect(subject['b_second:c_c'].to_a).to eq [0, 0, 0, 0, 0] }
        it { expect(subject['b_third:c_b'].to_a).to eq [0, 0, 0, 0, 0] }
        it { expect(subject['b_third:c_c'].to_a).to eq [0, 0, 0, 0, 1] } 
      end
    end

    context "more than two vectors" do
      let(:df) do
        Daru::DataFrame.new({
          a: [1, 1, 2],
          b: [2, 2, 3],
          c: [3, 3, 4]
        })
      end
      before { df.to_category :a, :b, :c }
      subject { df.interact_code [:a, :b, :c], [false, false, true] }
      
      it { is_expected.to be_a Daru::DataFrame }
      its(:shape) { is_expected.to eq [3, 2] }
      it { expect(subject['a_2:b_3:c_3'].to_a).to eq [0, 0, 0] }
      it { expect(subject['a_2:b_3:c_4'].to_a).to eq [0, 0, 1] }
    end
  end
end