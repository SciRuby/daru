require 'spec_helper.rb'

describe Daru::Vector, 'plotting' do
  let(:vector) { Daru::Vector.new([11, 22, 33], index: [:a, :b, :c]) }
  let(:plot) { instance_double('Nyaplot::Plot') }
  let(:diagram) { instance_double('Nyaplot::Diagram') }

  before do
    Daru.plotting_library = :nyaplot
    allow(Nyaplot::Plot).to receive(:new).and_return(plot)
  end

  it 'plots the vector' do
    expect(plot).to receive(:add).with(:box, [11, 22, 33]).ordered

    expect(vector.plot(type: :box)).to eq plot
  end

  context 'scatter' do
    it 'is default type' do
      expect(plot).to receive(:add).with(:scatter, instance_of(Array), instance_of(Array)).ordered

      expect(vector.plot).to eq plot
    end

    it 'sets x_axis to 0...size' do
      expect(plot).to receive(:add).with(:scatter, [0, 1, 2], [11, 22, 33]).ordered

      expect(vector.plot(type: :scatter)).to eq plot
    end
  end

  [:box, :histogram].each do |type|
    context type.to_s do
      it 'does not set x axis' do
        expect(plot).to receive(:add).with(type, [11, 22, 33]).ordered

        expect(vector.plot(type: type)).to eq plot
      end
    end
  end

  [:bar, :line].each do |type| # FIXME: what other types 2D plot could have?..
    context type.to_s do
      it 'sets x axis to index' do
        expect(plot).to receive(:add).with(type, [:a, :b, :c], [11, 22, 33]).ordered

        expect(vector.plot(type: type)).to eq plot
      end
    end
  end

  context 'with block provided' do
    it 'yields plot and diagram' do
      expect(plot).to receive(:add).with(:box, [11, 22, 33]).ordered.and_return(diagram)

      expect { |b| vector.plot(type: :box, &b) }.to yield_with_args(plot, diagram)
    end
  end
end
