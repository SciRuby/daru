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
    Daru.plotting_library = :nyaplot
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

describe Daru::Vector, 'plotting vector with gruff' do
  let(:dv) { Daru::Vector.new [1, 2, 3] }
  before { Daru.plotting_library = :gruff }

  context 'line' do
    let(:plot) { instance_double 'Gruff::Line' }
    before { allow(Gruff::Line).to receive(:new).and_return(plot) }
    
    it 'plots line graph without block' do
      expect(plot).to receive(:labels=)
      expect(plot).to receive(:data)
      dv.plot type: :line
    end
    
    it 'plots line graph with block' do
      expect(plot).to receive :labels=
      expect(plot).to receive :data
      expect(plot).to receive :title=
      dv.plot(type: :line) { |p| p.title = 'hello' }
    end
  end
  
  context 'bar' do
    let(:plot) { instance_double 'Gruff::Bar' }
    before { allow(Gruff::Bar).to receive(:new).and_return(plot) }
    
    it 'plots bar graph' do
      expect(plot).to receive :labels=
      expect(plot).to receive :data
      dv.plot type: :bar
    end
  end
  
  context 'pie' do
    let(:plot) { instance_double 'Gruff::Pie' }
    before { allow(Gruff::Pie).to receive(:new).and_return(plot) }
    
    it 'plots pie graph' do
      expect(plot).to receive(:data).exactly(3).times
      dv.plot type: :pie
    end
  end
  
  context 'scatter' do
    let(:plot) { instance_double 'Gruff::Scatter' }
    before { allow(Gruff::Scatter).to receive(:new).and_return(plot) }

    it 'plots scatter graph' do
      expect(plot).to receive :data
      dv.plot type: :scatter
    end
  end
  
  context 'sidebar' do
    let(:plot) { instance_double 'Gruff::SideBar' }
    before { allow(Gruff::SideBar).to receive(:new).and_return(plot) }

    it 'plots sidebar' do
      expect(plot).to receive :labels=
      expect(plot).to receive(:data).exactly(3).times
      dv.plot type: :sidebar
    end
  end
  
  context 'invalid type' do
    it { expect { dv.plot type: :lol }.to raise_error ArgumentError }
  end
end

describe Daru::Vector, 'plotting category vector with gruff' do
  before { Daru.plotting_library = :gruff }
  let(:dv) { Daru::Vector.new [1, 2, 3], type: :category }

  context 'bar' do
    let(:plot) { instance_double 'Gruff::Bar' }
    before { allow(Gruff::Bar).to receive(:new).and_return(plot) }
    it 'plots bar graph' do
      expect(plot).to receive :labels=
      expect(plot).to receive :data
      dv.plot type: :bar
    end
    
    it 'plots bar graph with block' do
      expect(plot).to receive :labels=
      expect(plot).to receive :data
      expect(plot).to receive :title=
      dv.plot(type: :bar) { |p| p.title = 'hello' }
    end
  end
  
  context 'pie' do
    let(:plot) { instance_double 'Gruff::Pie' }
    before { allow(Gruff::Pie).to receive(:new).and_return(plot) }
    it 'plots pie graph' do
      expect(plot).to receive(:data).exactly(3).times
      dv.plot type: :pie
    end
  end
  
  context 'sidebar' do
    let(:plot) { instance_double 'Gruff::SideBar' }
    before { allow(Gruff::SideBar).to receive(:new).and_return(plot) }
    it 'plots sidebar graph' do
      expect(plot).to receive :labels=
      expect(plot).to receive(:data).exactly(3).times
      dv.plot type: :sidebar
    end
  end

  context 'invalid type' do
    it { expect { dv.plot type: :lol }.to raise_error ArgumentError }
  end
end