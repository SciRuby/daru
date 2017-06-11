require 'spec_helper.rb'

describe Daru::Vector, 'plotting category' do
  let(:plot) { instance_double('Nyaplot::Plot') }
  let(:diagram) { instance_double('Nyaplot::Diagram') }
  let(:dv) do
    Daru::Vector.new ['III']*10 + ['II']*5 + ['I']*5,
      type: :category,
      categories: ['I', 'II', 'III']
  end
  before do
    Daru.plotting_library = :nyaplot
    allow(Nyaplot::Plot).to receive(:new).and_return(plot)
  end
  context 'bar' do
    it 'plots bar graph taking a block' do
      expect(plot).to receive(:add).with(:bar, ['I', 'II', 'III'], [5, 5, 10])
      expect(plot).to receive :x_label
      expect(plot).to receive :y_label
      dv.plot(type: :bar) do |p|
        p.x_label 'Categories'
        p.y_label 'Frequency'
      end
    end

    it 'plots bar graph without taking a block' do
      expect(plot).to receive(:add).with(:bar, ["I", "II", "III"], [5, 5, 10])
      expect(dv.plot(type: :bar)).to eq plot
    end

    it 'plots bar graph with percentage' do
      expect(plot).to receive(:add).with(:bar, ["I", "II", "III"], [25, 25, 50])
      expect(plot).to receive(:yrange).with [0, 100]
      expect(dv.plot(type: :bar, method: :percentage)).to eq plot
    end

    it 'plots bar graph with fraction' do
      expect(plot).to receive(:add).with(:bar, ["I", "II", "III"], [0.25, 0.25, 0.50])
      expect(plot).to receive(:yrange).with [0, 1]
      expect(dv.plot(type: :bar, method: :fraction)).to eq plot
    end
  end

  context 'other type' do
    it { expect { dv.plot(type: :scatter) }.to raise_error ArgumentError }
  end
end
