RSpec.describe Daru do
  describe '#error' do
    context 'by default' do
      it { expect { Daru.error('test') }.to output("test\n").to_stderr_from_any_process }
    end

    context 'when set to nil' do
      before { Daru.error_stream = nil }
      it { expect { Daru.error('test') }.not_to output('test').to_stderr_from_any_process }
    end

    context 'when set to instance of custom class' do
      let(:custom_stream) { double(puts: nil) }
      before { Daru.error_stream = custom_stream }

      it 'calls puts' do
        expect { Daru.error('test') }.not_to output('test').to_stderr_from_any_process
        expect(custom_stream).to have_received(:puts).with('test')
      end
    end
  end

  describe '#Index' do
    subject { described_class.Index(data) }

    context 'with one-level array' do
      let(:data) { [:one, 'one', 1, 2, :two] }

      it { is_expected.to be_a Daru::Index }
      its(:name) { is_expected.to be_nil }
      its(:to_a) { is_expected.to eq data }

      context 'named' do
        subject { described_class.Index(data, name: 'index_name') }

        its(:name) { is_expected.to eq 'index_name' }
      end
    end

    context 'with array of tuples' do
      let(:data) {
        [
          %i[b one bar],
          %i[b two bar],
          %i[b two baz],
          %i[b one foo]
        ]
      }

      it { is_expected.to be_a Daru::MultiIndex }
      its(:levels) { is_expected.to eq [[:b], %i[one two], %i[bar baz foo]] }
      its(:labels) { is_expected.to eq [[0,0,0,0],[0,1,1,0],[0,0,1,2]] }
    end

    context 'with array of dates' do
      let(:data) { [DateTime.new(2012,2,4), DateTime.new(2012,2,5), DateTime.new(2012,2,6)] }

      it { is_expected.to be_a Daru::DateTimeIndex }
      its(:to_a) { is_expected.to eq [DateTime.new(2012,2,4), DateTime.new(2012,2,5), DateTime.new(2012,2,6)] }
      its(:frequency) { is_expected.to eq 'D' }
    end
  end
end
