describe Daru::DataFrame, '#to_html' do
  let(:doc) { Nokogiri::HTML(df.to_html) }
  subject(:table) { doc.at('table') }
  let(:header) { doc.at('b')}
  let(:name) { 'test' }

  let(:splitted_row) { row.inner_html.scan(/<t[dh].+?<\/t[dh]>/) }

  context 'simple' do
    let(:df) { Daru::DataFrame.new({a: [1,2,3], b: [3,4,5], c: [6,7,8]}, name: name)}

    describe 'header' do
      subject { header }

      it { is_expected.not_to be_nil }
      its(:text) { is_expected.to eq " Daru::DataFrame: test (3x3) " }

      context 'without name' do
        let(:name) { nil }

        its(:text) { is_expected.to eq " Daru::DataFrame(3x3) " }
      end
    end

    describe 'column headers' do
      subject(:columns) { table.search('tr:nth-child(1) th').map(&:text) }
      its(:size) { is_expected.to eq df.ncols + 1 }
      it { is_expected.to eq ['', 'a', 'b', 'c'] }
    end

    context 'with multi-index columns' do
      before { df.vectors = Daru::MultiIndex.from_tuples [[:a, :foo], [:a, :baz], [:b, :foo]] }

      subject { splitted_row }
      describe 'first row' do
        let(:row) { table.search('thead > tr:nth-child(1)') }

        it { is_expected.to eq [
          '<th rowspan="2"></th>',
          '<th colspan="2">a</th>',
          '<th colspan="1">b</th>'
        ] }
      end

      describe 'next row' do
        let(:row) { table.search('thead > tr:nth-child(2)') }

        it { is_expected.to eq [
          '<th colspan="1">foo</th>',
          '<th colspan="1">baz</th>',
          '<th colspan="1">foo</th>'
        ] }
      end
    end

    describe 'index' do
      subject(:indexes) { table.search('tr > td:first-child').map(&:text) }
      its(:count) { is_expected.to eq df.nrows }
      it { is_expected.to eq df.index.to_a.map(&:to_s) }
    end

    describe 'values' do
      subject(:values) {
        table.search('tr')[1..-1]
             .map { |tr| tr.search('td')[1..-1].map(&:text) }
      }
      its(:count) { is_expected.to eq df.nrows }
      it { is_expected.to eq df.map_rows{|r| r.map(&:to_s)} }
    end
  end

  context 'large dataframe' do
    let(:df) { Daru::DataFrame.new({a: [1,2,3]*100, b: [3,4,5]*100, c: [6,7,8]*100}, name: 'test') }

    describe 'header' do
      subject { header }

      its(:text) { is_expected.to eq " Daru::DataFrame: test (300x3) " }
    end

    it 'has only 30 rows (+ 1 header rows, + 2 finishing rows)' do
      expect(table.search('tr').size).to eq 33
    end

    describe '"skipped" row' do
      subject(:row) { table.search('tr:nth-child(31) td').map(&:text) }
      its(:count) { is_expected.to eq df.ncols + 1 }
      it { is_expected.to all eq '...' }
    end

    describe 'last row' do
      subject(:row) { table.search('tr:nth-child(32) td').map(&:text) }
      its(:count) { is_expected.to eq df.ncols + 1 }
      it { is_expected.to eq ['299', *df.row[-1].map(&:to_s)] }
    end
  end

  context 'with multi-index' do
    let(:df) {
      Daru::DataFrame.new(
        {
          a:   [1,2,3,4,5,6,7],
          b: %w[a b c d e f g]
        }, index: Daru::MultiIndex.from_tuples([
              %w[foo one],
              %w[foo two],
              %w[foo three],
              %w[bar one],
              %w[bar two],
              %w[bar three],
              %w[baz one],
           ]),
           name: 'test'
      )
    }

    describe 'header' do
      subject { header }

      it { is_expected.not_to be_nil }
      its(:text) { is_expected.to eq " Daru::DataFrame: test (7x2) " }
    end

    describe 'column headers' do
      let(:row) { table.search('thead > tr:nth-child(1)') }
      subject { splitted_row }

      it { is_expected.to eq [
        '<th colspan="2"></th>',
        '<th>a</th>',
        '<th>b</th>'
      ]}
    end

    context 'with multi-index columns' do
      before { df.vectors = Daru::MultiIndex.from_tuples [[:a, :foo], [:a, :baz]] }

      subject { splitted_row }
      describe 'first row' do
        let(:row) { table.search('thead > tr:nth-child(1)') }

        it { is_expected.to eq [
          '<th colspan="2" rowspan="2"></th>',
          '<th colspan="2">a</th>',
        ] }
      end

      describe 'next row' do
        let(:row) { table.search('thead > tr:nth-child(2)') }

        it { is_expected.to eq [
          '<th colspan="1">foo</th>',
          '<th colspan="1">baz</th>',
        ] }
      end
    end

    describe 'first row' do
      let(:row) { table.search('tbody > tr:nth-child(1)') }
      subject { splitted_row }

      it { is_expected.to eq [
        '<th rowspan="3">foo</th>',
        '<th rowspan="1">one</th>',
        '<td>1</td>',
        '<td>a</td>'
      ]}
    end
  end
end
