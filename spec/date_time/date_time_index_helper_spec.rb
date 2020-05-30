include Daru

describe Daru::DateTimeIndexHelper do


  describe '.infer_offset' do
    subject(:offset) { Daru::DateTimeIndexHelper.infer_offset(data) }

    context 'when the dataset does not have a regular offset' do
      let(:data) do
        [
          DateTime.new(2020, 1, 1, 00, 00, 00),
          DateTime.new(2020, 1, 1, 00, 01, 00),
          DateTime.new(2020, 1, 1, 00, 05, 00),
        ]
      end

      it 'returns nil' do
        expect(offset).to be_nil
      end
    end

    context 'when the dataset matches a defined offset' do
      let(:data) do
        [
          DateTime.new(2020, 1, 1, 00, 00, 00),
          DateTime.new(2020, 1, 1, 00, 01, 00),
          DateTime.new(2020, 1, 1, 00, 02, 00),
        ]
      end

      it 'returns the matched offset' do
        expect(offset).to be_an_instance_of(Daru::Offsets::Minute)
      end
    end

    context 'when the offset is a multiple of seconds' do
      let(:data) do
        [
          DateTime.new(2020, 1, 1, 00, 00, 00),
          DateTime.new(2020, 1, 1, 00, 00, 03),
          DateTime.new(2020, 1, 1, 00, 00, 06),
        ]
      end

      let(:expected_offset) { Daru::Offsets::Second.new(3) }

      it 'returns a Second offset' do
        expect(offset).to be_an_instance_of(Daru::Offsets::Second)
      end

      it 'has the correct multiplier' do
        expect(offset.freq_string).to eql(expected_offset.freq_string)
      end
    end

    context 'when the offset is less than a second' do
      let(:data) do
        [
          DateTime.new(2020, 1, 1, 00, 00, 00) + 0.00001,
          DateTime.new(2020, 1, 1, 00, 00, 00) + 0.00002,
          DateTime.new(2020, 1, 1, 00, 00, 00) + 0.00003,
        ]
      end

      it 'returns nil' do
        expect(offset).to be_nil
      end
    end
  end

end