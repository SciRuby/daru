describe Daru::ArrayHelper do
  context '#recode_repeated' do
    let(:source) { [1,'a',1,'a','b',:c,2] }
    subject { described_class.recode_repeated(source) }

    it { is_expected.to eq ['1_1','a_1', '1_2','a_2','b',:c,2] }
  end
end
