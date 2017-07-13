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
