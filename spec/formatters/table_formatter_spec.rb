describe Daru::Formatters::Table do
  let(:options) { {} }
  subject {
    Daru::Formatters::Table
      .format(data, options.merge(headers: headers, row_headers: row_headers))
  }

  let(:data) { [[1,2,3], [4,5,6], [7,8,9]] }
  let(:headers) { [:col1, :col2, :col3] }
  let(:row_headers) { [:row1, :row2, :row3] }

  context 'simple table' do
    it { is_expected.to eq %Q{
      |      col1 col2 col3
      | row1    1    2    3
      | row2    4    5    6
      | row3    7    8    9
    }.unindent}
  end

  context 'with nils' do
    let(:data) { [[1,nil,3], [4,5,nil], [7,8,9]] }
    let(:headers) { [:col1, :col2, nil] }
    let(:row_headers) { [:row1, nil, :row3] }

    it { is_expected.to eq %Q{
      |      col1 col2     |
      | row1    1  nil    3|
      |         4    5  nil|
      | row3    7    8    9|
    }.unindent}
  end

  context 'with multivalue row headers' do
    let(:row_headers) { [[:row,1], [:row,2], [:row,3]] }
    it { is_expected.to eq %Q{
      |           col1 col2 col3
      |  row    1    1    2    3
      |  row    2    4    5    6
      |  row    3    7    8    9
    }.unindent}
  end

  context 'with multivalue column headers' do
    let(:headers) { [[:col,1], [:col,2], [:col,3]] }
  end

  context 'rows only' do
    let(:data) { [] }
    let(:headers) { nil }
    it { is_expected.to eq %Q{
      | row1
      | row2
      | row3
    }.unindent}
  end

  context 'columns only' do
    let(:data) { [] }
    let(:row_headers) { nil }
    it { is_expected.to eq %Q{
      | col1 col2 col3
    }.unindent}
  end

  context 'wide values' do
    let(:options) { {spacing: 2} }

    it { is_expected.to eq %Q{
      |    co co co
      | ro  1  2  3
      | ro  4  5  6
      | ro  7  8  9
    }.unindent}
  end

  context 'with empty data' do
    let(:data) { [] }
    let(:headers) { [] }
    let(:row_headers) { [] }

    it { is_expected.to eq '' }
  end


  context '<more> threshold' do
    let(:options) { {threshold: threshold} }
    context 'lower than data size' do
      let(:threshold) { 2 }
      it { is_expected.to eq %Q{
        |      col1 col2 col3
        | row1    1    2    3
        | row2    4    5    6
        |  ...  ...  ...  ...
      }.unindent}
    end

    context 'greater than data size' do
      let(:threshold) { 5 }
      it { is_expected.to eq %Q{
        |      col1 col2 col3
        | row1    1    2    3
        | row2    4    5    6
        | row3    7    8    9
      }.unindent}
    end
  end

  context 'no row and column headers' do
    let(:headers) { nil }
    let(:row_headers) { nil }
    it { is_expected.to eq %Q{
        |       1   2   3
        |       4   5   6
        |       7   8   9
      }.unindent }
  end

  context 'row headers only' do
    let(:headers) { nil }
    it { is_expected.to eq %Q{
        | row1    1    2    3
        | row2    4    5    6
        | row3    7    8    9
      }.unindent }
  end

  context 'column headers only' do
    let(:row_headers) { nil }
    it { is_expected.to eq %Q{
        |      col1 col2 col3
        |         1    2    3
        |         4    5    6
        |         7    8    9
      }.unindent }
  end
end
