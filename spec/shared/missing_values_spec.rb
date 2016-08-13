[nil, :category].each do |type|
  describe Daru::Vector, type do
    context type do
      context '#reject_values'do
        # TODO: Also test it for :gsl
        let(:dv) { Daru::Vector.new [1, nil, 3, :a, Float::NAN, nil, Float::NAN, 1],
          index: 11..18, type: type }
        context 'reject only nils' do
          subject { dv.reject_values nil }
          
          it { is_expected.to be_a Daru::Vector }
          its(:to_a) { is_expected.to eq [1, 3, :a, Float::NAN, Float::NAN, 1] }
          its(:'index.to_a') { is_expected.to eq [11, 13, 14, 15, 17, 18] }
        end
    
        context 'reject only float::NAN' do
          subject { dv.reject_values Float::NAN }
          
          it { is_expected.to be_a Daru::Vector }
          its(:to_a) { is_expected.to eq [1, nil, 3, :a, nil, 1] }
          its(:'index.to_a') { is_expected.to eq [11, 12, 13, 14, 16, 18] }
        end
    
        context 'reject both nil and float::NAN' do
          subject { dv.reject_values nil, Float::NAN }
          
          it { is_expected.to be_a Daru::Vector }
          its(:to_a) { is_expected.to eq [1, 3, :a, 1] }
          its(:'index.to_a') { is_expected.to eq [11, 13, 14, 18] }
        end
        
        context 'reject any other value' do
          subject { dv.reject_values 1, 3 }
          
          it { is_expected.to be_a Daru::Vector }
          its(:to_a) { is_expected.to eq [nil, :a, Float::NAN, nil, Float::NAN] }
          its(:'index.to_a') { is_expected.to eq [12, 14, 15, 16, 17] }
        end
    
        context 'test caching' do
          let(:dv) { Daru::Vector.new [nil]*8, index: 11..18}
          before do
            dv.reject_values nil
            [1, nil, 3, :a, Float::NAN, nil, Float::NAN, 1].each_with_index do |v, pos|
              dv.set_at [pos], v
            end
          end
    
          context 'reject only nils' do
            subject { dv.reject_values nil }
            
            it { is_expected.to be_a Daru::Vector }
            its(:to_a) { is_expected.to eq [1, 3, :a, Float::NAN, Float::NAN, 1] }
            its(:'index.to_a') { is_expected.to eq [11, 13, 14, 15, 17, 18] }
          end
      
          context 'reject only float::NAN' do
            subject { dv.reject_values Float::NAN }
            
            it { is_expected.to be_a Daru::Vector }
            its(:to_a) { is_expected.to eq [1, nil, 3, :a, nil, 1] }
            its(:'index.to_a') { is_expected.to eq [11, 12, 13, 14, 16, 18] }
          end
      
          context 'reject both nil and float::NAN' do
            subject { dv.reject_values nil, Float::NAN }
            
            it { is_expected.to be_a Daru::Vector }
            its(:to_a) { is_expected.to eq [1, 3, :a, 1] }
            its(:'index.to_a') { is_expected.to eq [11, 13, 14, 18] }
          end
          
          context 'reject any other value' do
            subject { dv.reject_values 1, 3 }
            
            it { is_expected.to be_a Daru::Vector }
            its(:to_a) { is_expected.to eq [nil, :a, Float::NAN, nil, Float::NAN] }
            its(:'index.to_a') { is_expected.to eq [12, 14, 15, 16, 17] }
          end
        end
      end
  
      context '#include_values?' do
        context 'only nils' do
          context 'true' do
            let(:dv) { Daru::Vector.new [1, 2, 3, :a, 'Unknown', nil],
              type: type }
            it { expect(dv.include_values? nil).to eq true }
          end
    
          context 'false' do
            let(:dv) { Daru::Vector.new [1, 2, 3, :a, 'Unknown'],
              type: type }
            it { expect(dv.include_values? nil).to eq false }
          end
        end
    
        context 'only Float::NAN' do
          context 'true' do
            let(:dv) { Daru::Vector.new [1, nil, 2, 3, Float::NAN],
             type: type }
            it { expect(dv.include_values? Float::NAN).to eq true }
          end
    
          context 'false' do
            let(:dv) { Daru::Vector.new [1, nil, 2, 3],
              type: type }
            it { expect(dv.include_values? Float::NAN).to eq false }
          end
        end
    
        context 'both nil and Float::NAN' do
          context 'true with only nil' do
            let(:dv) { Daru::Vector.new [1, Float::NAN, 2, 3],
              type: type }
            it { expect(dv.include_values? nil, Float::NAN).to eq true }
          end
          
          context 'true with only Float::NAN' do
            let(:dv) { Daru::Vector.new [1, nil, 2, 3],
              type: type }
            it { expect(dv.include_values? nil, Float::NAN).to eq true }
          end
          
          context 'false' do
            let(:dv) { Daru::Vector.new [1, 2, 3],
              type: type }
            it { expect(dv.include_values? nil, Float::NAN).to eq false }
          end
        end
        
        context 'any other value' do
          context 'true' do
            let(:dv) { Daru::Vector.new [1, 2, 3, 4, nil],
              type: type }
            it { expect(dv.include_values? 1, 2, 3, 5).to eq true }
          end
          
          context 'false' do
            let(:dv) { Daru::Vector.new [1, 2, 3, 4, nil],
              type: type }
            it { expect(dv.include_values? 5, 6).to eq false }
          end
        end
      end
  
      context '#count_values' do
        let(:dv) { Daru::Vector.new [1, 2, 3, 1, 2, nil, nil],
          type: type }
        it { expect(dv.count_values 1, 2).to eq 4 }
        it { expect(dv.count_values nil).to eq 2 }
        it { expect(dv.count_values 3, Float::NAN).to eq 1 }
        it { expect(dv.count_values 4).to eq 0 }
      end
  
      context '#indexes' do
        context Daru::Index do
          let(:dv) { Daru::Vector.new [1, 2, 1, 2, 3, nil, nil, Float::NAN],
            index: 11..18, type: type }
          
          subject { dv.indexes 1, 2, nil, Float::NAN }
          it { is_expected.to be_a Array }
          it { is_expected.to eq [11, 12, 13, 14, 16, 17, 18] }
        end
        
        context Daru::MultiIndex do
          let(:mi) do
            Daru::MultiIndex.from_tuples([
              ['M', 2000],
              ['M', 2001],
              ['M', 2002],
              ['M', 2003],
              ['F', 2000],
              ['F', 2001],
              ['F', 2002],
              ['F', 2003]
            ])
          end
          let(:dv) { Daru::Vector.new [1, 2, 1, 2, 3, nil, nil, Float::NAN],
            index: mi, type: type }
          
          subject { dv.indexes 1, 2, Float::NAN }
          it { is_expected.to be_a Array }
          it { is_expected.to eq(
            [
              ['M', 2000],
              ['M', 2001],
              ['M', 2002],
              ['M', 2003],
              ['F', 2003]
            ]) }
        end
      end
      
      context '#replace' do
        subject do
          Daru::Vector.new(
            [1, 2, 1, 4, nil, Float::NAN, nil, Float::NAN],
            index: 11..18,
            type: type
          )
        end

        context 'replace nils and NaNs' do
          before { subject.replace [nil, Float::NAN], 10 }
          its(:to_a) { is_expected.to eq [1, 2, 1, 4, 10, 10, 10, 10] }
        end
        
        context 'replace arbitrary values' do
          before { subject.replace [1, 2], 10 }
          its(:to_a) { is_expected.to eq(
            [10, 10, 10, 4, nil, Float::NAN, nil, Float::NAN]) }
        end
        
        context 'works for single value' do
          before { subject.replace nil, 10 }
          its(:to_a) { is_expected.to eq(
            [1, 2, 1, 4, 10, Float::NAN, 10, Float::NAN]) }
        end
      end
    end
  end
end