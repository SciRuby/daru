require 'spec_helper.rb'

describe Daru::DataFrame, 'plotting' do
  let(:data_frame) {
    Daru::DataFrame.new({
        a: [11, 22, 33],
        b: [5, 7, 9],
        c: [-3, -7, -11]
      },
      index: [:one, :two, :three]
    )
  }
  let(:plot) { instance_double('Nyaplot::Plot') }
  let(:diagram) { instance_double('Nyaplot::Diagram') }

  context 'box' do
  end

  context 'other types' do
  end

  context 'unknown types' do
  end
end
