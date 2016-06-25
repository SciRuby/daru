require 'spec_helper.rb'

class Nyaplot::DataFrame
  # Because it does not allow to any equality testing
  def == other
    other.is_a?(Nyaplot::DataFrame) && rows == other.rows
  end
end

# FIXME: just guessed specs logic from code. As far as I can understand,
# it can be broken in number of ways with incorrect arguments.
#
describe Daru::DataFrame, 'plotting' do
  let(:data_frame) {
    described_class.new({
        x:  [1, 2, 3, 4],
        y1: [5, 7, 9, 11],
        y2: [-3, -7, -11, -15],
        cat: [:a, :b, :c, :d]
      },
      index: [:one, :two, :three, :four]
    )
  }
  let(:plot) { instance_double('Nyaplot::Plot') }
  let(:diagram) { instance_double('Nyaplot::Diagram') }

  before do
    allow(Nyaplot::Plot).to receive(:new).and_return(plot)
  end

  context 'box' do
    let(:numerics) { data_frame.only_numerics }
    it 'plots numeric vectors' do
      expect(plot).to receive(:add_with_df)
        .with(numerics.to_nyaplotdf, :box, :x, :y1, :y2)
        .ordered

      expect(plot).to receive(:show).ordered
      data_frame.plot(type: :box)
    end
  end

  context 'other types' do
    context 'single chart' do
      it 'works with :y provided' do
        expect(plot).to receive(:add_with_df)
          .with(data_frame.to_nyaplotdf, :scatter, :x, :y1)
          .ordered

        expect(plot).to receive(:show).ordered
        data_frame.plot(type: :scatter, x: :x, y: :y1)
      end

      it 'works without :y provided' do
        expect(plot).to receive(:add_with_df)
          .with(data_frame.to_nyaplotdf, :scatter, :x)
          .ordered

        expect(plot).to receive(:show).ordered
        data_frame.plot(type: :scatter, x: :x)
      end
    end

    context 'multiple charts' do
      it 'works with single type provided' do
        expect(plot).to receive(:add_with_df)
          .with(data_frame.to_nyaplotdf, :scatter, :x, :y1)
          .ordered
        expect(plot).to receive(:add_with_df)
          .with(data_frame.to_nyaplotdf, :scatter, :x, :y2)
          .ordered
        expect(plot).to receive(:show).ordered

        data_frame.plot(type: :scatter, x: [:x, :x], y: [:y1, :y2])
      end

      it 'works with multiple types provided' do
        expect(plot).to receive(:add_with_df)
          .with(data_frame.to_nyaplotdf, :scatter, :x, :y1)
          .ordered
        expect(plot).to receive(:add_with_df)
          .with(data_frame.to_nyaplotdf, :line, :x, :y2)
          .ordered
        expect(plot).to receive(:show).ordered

        data_frame.plot(type: [:scatter, :line], x: [:x, :x], y: [:y1, :y2])
      end

      it 'works with numeric var names' do
        expect(plot).to receive(:add_with_df)
          .with(data_frame.to_nyaplotdf, :scatter, :x, :y1)
          .ordered
        expect(plot).to receive(:add_with_df)
          .with(data_frame.to_nyaplotdf, :line, :x, :y2)
          .ordered
        expect(plot).to receive(:show).ordered

        data_frame.plot(
          type: [:scatter, :line],
          # FIXME: this didn't work due to default type: :scatter opts
          #type1: :scatter,
          #type2: :line,
          x1: :x,
          x2: :x,
          y1: :y1,
          y2: :y2
        )
      end
    end
  end
end

describe Daru::DataFrame, 'category plotting' do
  context 'scatter' do
    let(:df) do
      Daru::DataFrame.new({
        a: [1, 2, 4, -2, 5, 23, 0],
        b: [3, 1, 3, -6, 2, 1, 0],
        c: ['I', 'II', 'I', 'III', 'I', 'III', 'II']
      })
    end
    let(:plot) { instance_double('Nyaplot::Plot') }
    let(:diagram) { instance_double('Nyaplot::Diagram::Scatter') }
  
    before do
      df.to_category :c
      allow(Nyaplot::Plot).to receive(:new).and_return(plot)
      allow(plot).to receive(:add_with_df).and_return(diagram)
    end
    
    it 'plots scatter plot categoried by color with a block' do
      expect(plot).to receive :add_with_df
      expect(diagram).to receive(:title).exactly(3).times
      expect(diagram).to receive(:color).exactly(3).times
      expect(diagram).to receive(:tooltip_contents).exactly(3).times
      expect(plot).to receive :legend
      expect(plot).to receive :xrange
      expect(plot).to receive :yrange
      expect(plot).to receive :show
      df.plot(type: :scatter, x: :a, y: :b, categorized: {by: :c, method: :color}) do |p, d|
        p.xrange [-10, 10]
        p.yrange [-10, 10]
      end
    end

    it 'plots scatter plot categoried by color without a block' do
      expect(plot).to receive :add_with_df
      expect(diagram).to receive(:title).exactly(3).times
      expect(diagram).to receive(:color).exactly(3).times
      expect(diagram).to receive(:tooltip_contents).exactly(3).times
      expect(plot).to receive :legend
      expect(plot).to receive :show
      df.plot(type: :scatter, x: :a, y: :b, categorized: {by: :c, method: :color})
    end

    it 'plots scatter plot categoried by shape without a block' do
      expect(plot).to receive :add_with_df
      expect(diagram).to receive(:title).exactly(3).times
      expect(diagram).to receive(:shape).exactly(3).times
      expect(diagram).to receive(:tooltip_contents).exactly(3).times
      expect(plot).to receive :legend
      expect(plot).to receive :show
      df.plot(type: :scatter, x: :a, y: :b, categorized: {by: :c, method: :shape})
    end

    it 'plots scatter plot categoried by size without a block' do
      expect(plot).to receive :add_with_df
      expect(diagram).to receive(:title).exactly(3).times
      expect(diagram).to receive(:size).exactly(3).times
      expect(diagram).to receive(:tooltip_contents).exactly(3).times
      expect(plot).to receive :legend
      expect(plot).to receive :show
      df.plot(type: :scatter, x: :a, y: :b, categorized: {by: :c, method: :size})
    end
  end

  context 'line' do
    let(:df) do
      Daru::DataFrame.new({
        a: [1, 2, 4, -2, 5, 23, 0],
        b: [3, 1, 3, -6, 2, 1, 0],
        c: ['I', 'II', 'I', 'III', 'I', 'III', 'II']
      })
    end
    let(:plot) { instance_double('Nyaplot::Plot') }
    let(:diagram) { instance_double('Nyaplot::Diagram::Scatter') }
  
    before do
      df.to_category :c
      allow(Nyaplot::Plot).to receive(:new).and_return(plot)
      allow(plot).to receive(:add_with_df).and_return(diagram)
    end
    
    it 'plots line plot categoried by color with a block' do
      expect(plot).to receive :add_with_df
      expect(diagram).to receive(:title).exactly(3).times
      expect(diagram).to receive(:color).exactly(3).times
      expect(plot).to receive :legend
      expect(plot).to receive :xrange
      expect(plot).to receive :yrange
      expect(plot).to receive :show
      df.plot(type: :line, x: :a, y: :b, categorized: {by: :c, method: :color}) do |p, d|
        p.xrange [-10, 10]
        p.yrange [-10, 10]
      end
    end

    it 'plots line plot categoried by color without a block' do
      expect(plot).to receive :add_with_df
      expect(diagram).to receive(:title).exactly(3).times
      expect(diagram).to receive(:color).exactly(3).times
      expect(plot).to receive :legend
      expect(plot).to receive :show
      df.plot(type: :line, x: :a, y: :b, categorized: {by: :c, method: :color})
    end

    it 'plots line plot categoried by stroke width without a block' do
      expect(plot).to receive :add_with_df
      expect(diagram).to receive(:title).exactly(3).times
      expect(diagram).to receive(:stroke_width).exactly(3).times
      expect(plot).to receive :legend
      expect(plot).to receive :show
      df.plot(type: :line, x: :a, y: :b, categorized: {by: :c, method: :stroke_width})
    end
  end

  context "invalid type" do
    let(:df) do
      Daru::DataFrame.new({
        a: [1, 2, 4, -2, 5, 23, 0],
        b: [3, 1, 3, -6, 2, 1, 0],
        c: ['I', 'II', 'I', 'III', 'I', 'III', 'II']
      })
    end
    it { expect { df.plot(type: :box, categorized: {by: :c, method: :color}) }.to raise_error ArgumentError }
  end
end
