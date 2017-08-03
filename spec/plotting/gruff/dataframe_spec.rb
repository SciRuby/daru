require 'spec_helper.rb'

describe Daru::DataFrame, 'plotting dataframe using gruff' do
  before { Daru.plotting_library = :gruff }
  let(:df) do
    Daru::DataFrame.new({
      a: [1, 3, 5, 2, 5, 0],
      b: [1, 5, 2, 5, 1, 0],
      c: [1, 6, 7, 2, 6, 0]
    }, index: 'a'..'f')
  end

  context 'bar' do
    let(:plot) { instance_double 'Gruff::Bar' }
    before { allow(Gruff::Bar).to receive(:new).and_return(plot) }
    it 'plots bar graph' do
      expect(plot).to receive :labels=
      expect(plot).to receive(:data).exactly(3).times
      df.plot type: :bar
    end

    it 'plots bar graph with block' do
      expect(plot).to receive :labels=
      expect(plot).to receive(:data).exactly(3).times
      expect(plot).to receive :title=
      df.plot(type: :bar) { |p| p.title = 'hello' }
    end

    it 'plots with specified columns' do
      expect(plot).to receive :labels=
      expect(plot).to receive(:data).exactly(2).times
      df.plot type: :bar, y: [:a, :b]
    end
  end

  context 'line' do
    let(:plot) { instance_double 'Gruff::Line' }
    before { allow(Gruff::Line).to receive(:new).and_return(plot) }
    it 'plots line graph' do
      expect(plot).to receive :labels=
      expect(plot).to receive(:data).exactly(3).times
      df.plot type: :line
    end
  end

  context 'scatter' do
    let(:plot) { instance_double 'Gruff::Scatter' }
    before { allow(Gruff::Scatter).to receive(:new).and_return(plot) }
    it 'plots scatter graph' do
      expect(plot).to receive(:data).exactly(3).times
      df.plot type: :scatter
    end

    it 'plots with specified columns' do
      expect(plot).to receive(:data).exactly(1).times
      df.plot type: :scatter, x: :c, y: :a
    end
  end

  context 'invalid type' do
    it { expect { df.plot type: :lol }.to raise_error ArgumentError }
  end
end

describe Daru::DataFrame, 'dataframe category plotting with gruff' do
  before { Daru.plotting_library = :gruff }
  let(:df) do
    Daru::DataFrame.new({
      a: [1, 3, 5, 2, 5, 0],
      b: [1, 5, 2, 5, 1, 0],
      c: [:a, :b, :a, :a, :b, :a]
    }, index: 'a'..'f')
  end
  before { df.to_category :c }

  context 'scatter' do
    let(:plot) { instance_double 'Gruff::Scatter' }
    before { allow(Gruff::Scatter).to receive(:new).and_return(plot) }
    it 'plots scatter plot categorized by category vector' do
      expect(plot).to receive(:data).exactly(2).times
      df.plot type: :scatter, x: :a, y: :b, categorized: { by: :c }
    end

    it 'plots with axes description' do
      expect(plot).to receive(:data).exactly(2).times
      expect(plot).to receive(:x_axis_label=).exactly(1).times
      expect(plot).to receive(:y_axis_label=).exactly(1).times
      df.plot type: :scatter, x: :a, y: :b, categorized: { by: :c } do |gruff_plot|
        gruff_plot.x_axis_label = 'A data'
        gruff_plot.y_axis_label = 'B data'
      end
    end
  end
end
