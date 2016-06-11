describe Daru::Vector do
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
  
  context "#base_category" do
    let(:dv) { Daru::Vector.new [:a, 1, :a, 1, :c], type: :category }
    subject { dv }
    before { dv.base_category = 1 }
    
    its(:base_category) { is_expected.to eq 1 }
  end
  
  context "#coding_scheme" do
    let(:dv) { Daru::Vector.new [:a, 1, :a, 1, :c], type: :category }
    subject { dv }
    before { dv.coding_scheme = :deviation }
    
    its(:coding_scheme) { is_expected.to eq :deviation }
  end
  
  context "#categories=" do
    let(:dv) { Daru::Vector.new [:a, 1, :a, 1, :c], type: :category }
    subject { dv }
    before { dv.categories = [1, 2, 3] }
    
    its(:to_a) { is_expected.to eq [1, 2, 1, 2, 3] }
  end
  
  context "#order=" do
    context "valid reordering" do
      let(:dv) { Daru::Vector.new [:a, 1, :a, 1, :c], type: :category }
      subject { dv }
      before { dv.order = [:c, 1, :a] }
      
      its(:categories) { is_expected.to eq [:c, 1, :a] }
      its(:to_a) { is_expected.to eq [:a, 1, :a, 1, :c] }
    end
    
    context "invalid reordering" do
      let(:dv) { Daru::Vector.new [:a, 1, :a, 1, :c], type: :category }

      it { expect { dv.order = [:c, 1, :b] }.to raise_error ArgumentError }
    end
  end
  
  context "#min" do
    context "ordered" do
      context "default ordering" do
        let(:dv) { Daru::Vector.new [:a, 1, :a, 1, :c], type: :category, ordered: true }

        it { expect(dv.min).to eq :a }
      end
      
      context "reorder" do
        let(:dv) { Daru::Vector.new [:a, 1, :a, 1, :c], type: :category, ordered: true }
        before { dv.order = [1, :a, :c] }
        
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
        before { dv.order = [1, :c, :a] }
        
        it { expect(dv.max).to eq :a }
      end
    end
    
    context "unordered" do
      let(:dv) { Daru::Vector.new [:a, 1, :a, 1, :c], type: :category }

      it { expect { dv.max }.to raise_error ArgumentError }
    end
  end
  
  context "#sort!" do
    let(:dv) { Daru::Vector.new [:a, 1, :a, 1, :c], type: :category, ordered: true }
    subject { dv }
    before { dv.order = [:c, :a, 1]; dv.sort! }
    
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
end