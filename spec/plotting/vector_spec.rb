require 'spec_helper.rb'

describe Daru::Vector, 'plotting' do
  let(:vector) { Daru::Vector.new([11, 22, 33], index: [:a, :b, :c]) }
  let(:plot) { instance_double('Nyaplot::Plot') }
  let(:diagram) { instance_double('Nyaplot::Diagram') }

  before do
    allow(Nyaplot::Plot).to receive(:new).and_return(plot)
  end

  it 'plots the vector' do
    expect(plot).to receive(:add).with(:box, [11, 22, 33]).ordered
    expect(plot).to receive(:show).ordered

    vector.plot(type: :box)
  end

  context 'scatter' do
    it 'is default type' do
      expect(plot).to receive(:add).with(:scatter, instance_of(Array), instance_of(Array)).ordered
      expect(plot).to receive(:show).ordered

      vector.plot
    end

    it 'sets x_axis to 0...size' do
      expect(plot).to receive(:add).with(:scatter, [0, 1, 2], [11, 22, 33]).ordered
      expect(plot).to receive(:show).ordered

      vector.plot(type: :scatter)
    end
  end

  [:box, :histogram].each do |type|
    context type.to_s do
      it 'does not set x axis' do
        expect(plot).to receive(:add).with(type, [11, 22, 33]).ordered
        expect(plot).to receive(:show).ordered

        vector.plot(type: type)
      end
    end
  end

  [:bar, :line].each do |type| # FIXME: what other types 2D plot could have?..
    context type.to_s do
      it 'sets x axis to index' do
        expect(plot).to receive(:add).with(type, [:a, :b, :c], [11, 22, 33]).ordered
        expect(plot).to receive(:show).ordered

        vector.plot(type: type)
      end
    end
  end

  context 'with block provided' do
    it 'yields plot and diagram' do
      expect(plot).to receive(:add).with(:box, [11, 22, 33]).ordered.and_return(diagram)
      expect(plot).to receive(:show).ordered

      expect { |b| vector.plot(type: :box, &b) }.to yield_with_args(plot, diagram)
    end
  end
end

describe Daru::Vector, 'plotting category' do
  let(:plot) { instance_double('Nyaplot::Plot') }
  let(:diagram) { instance_double('Nyaplot::Diagram') }
  let(:dv) do
    Daru::Vector.new ['III']*10 + ['II']*5 + ['I']*5,
      type: :category,
      categories: ['I', 'II', 'III']
  end  
  before do
    allow(Nyaplot::Plot).to receive(:new).and_return(plot)
  end
  context 'bar' do
    it 'plots bar graph taking a block' do
      expect(plot).to receive(:add).with(:bar, ['I', 'II', 'III'], [5, 5, 10])
      expect(plot).to receive :x_label
      expect(plot).to receive :y_label
      expect(plot).to receive(:show)
      dv.plot(type: :bar) do |p|
        p.x_label 'Categories'
        p.y_label 'Frequency'
      end
    end

    it 'plots bar graph without taking a block' do
      expect(plot).to receive(:add).with(:bar, ["I", "II", "III"], [5, 5, 10])
      expect(plot).to receive(:show)
      dv.plot(type: :bar)
    end

    it 'plots bar graph with percentage' do
      expect(plot).to receive(:add).with(:bar, ["I", "II", "III"], [25, 25, 50])
      expect(plot).to receive(:yrange).with [0, 100]
      expect(plot).to receive(:show)
      dv.plot(type: :bar, method: :percentage)
    end

    it 'plots bar graph with fraction' do
      expect(plot).to receive(:add).with(:bar, ["I", "II", "III"], [0.25, 0.25, 0.50])
      expect(plot).to receive(:yrange).with [0, 1]
      expect(plot).to receive(:show)
      dv.plot(type: :bar, method: :fraction)
    end    
  end

  context 'other type' do
    it { expect { dv.plot(type: :scatter) }.to raise_error ArgumentError }
  end
end