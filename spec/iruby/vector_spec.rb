describe Daru::Vector, '#to_html' do
  [nil, :category].each do |type|
    let(:doc) { Nokogiri::HTML(vector.to_html) }
    subject(:table) { doc.at('table') }
    let(:header) { doc.at('b') }

    context 'simple' do
      let(:vector) { Daru::Vector.new [1,nil,3],
        index: [:a, :b, :c], name: 'test', type: type }
      it { is_expected.not_to be_nil }

      describe 'header' do
        subject { header }
        it { is_expected.not_to be_nil }
        its(:text) { is_expected.to eq " Daru::Vector(3)"\
          "#{":category" if type == :category} " }
      end

      describe 'name' do
        subject(:name) { table.at('tr:nth-child(1) > th:nth-child(2)') }
        it { is_expected.not_to be_nil }
        its(:text) { is_expected.to eq 'test' }

        context 'withought name' do
          let(:vector) { Daru::Vector.new [1,nil,3], index: [:a, :b, :c], type: type }

          it { is_expected.to be_nil }
        end
      end

      describe 'index' do
        subject(:indexes) { table.search('tr > td:first-child').map(&:text) }
        its(:count) { is_expected.to eq vector.size }
        it { is_expected.to eq vector.index.to_a.map(&:to_s) }
      end

      describe 'values' do
        subject(:indexes) { table.search('tr > td:last-child').map(&:text) }
        its(:count) { is_expected.to eq vector.size }
        it { is_expected.to eq vector.to_a.map(&:to_s) }
      end
    end

    context 'large vector' do
      subject(:vector) { Daru::Vector.new [1,2,3] * 100, name: 'test', type: type }
      it 'has only 30 rows (+ 1 header rows, + 2 finishing rows)' do
        expect(table.search('tr').size).to eq 33
      end

      describe '"skipped" row' do
        subject(:row) { table.search('tr:nth-child(31) td').map(&:text) }
        its(:count) { is_expected.to eq 2 }
        it { is_expected.to eq ['...', '...'] }
      end

      describe 'last row' do
        subject(:row) { table.search('tr:nth-child(32) td').map(&:text) }
        its(:count) { is_expected.to eq 2 }
        it { is_expected.to eq ['299', '3'] }
      end
    end

    context 'multi-index' do
      subject(:vector) {
        Daru::Vector.new(
          [1,2,3,4,5,6,7],
          name: 'test',
          type: type,
          index: Daru::MultiIndex.from_tuples([
              %w[foo one],
              %w[foo two],
              %w[foo three],
              %w[bar one],
              %w[bar two],
              %w[bar three],
              %w[baz one],
           ]),
        )
      }

      describe 'header' do
        subject { header }
        it { is_expected.not_to be_nil }
        its(:text) { is_expected.to eq " Daru::Vector(7)"\
          "#{":category" if type == :category} " }
      end

      describe 'name row' do
        subject(:row) { table.at('tr:nth-child(1)').search('th') }
        its(:count) { should == 2 }
        it { expect(row.first['colspan']).to eq '2' }
      end

      describe 'first data row' do
        let(:row) { table.at('tbody > tr:first-child') }
        subject { row.inner_html.scan(/<t[dh].+?<\/t[dh]>/) }
        it { is_expected.to eq [
          '<th rowspan="3">foo</th>',
          '<th rowspan="1">one</th>',
          '<td>1</td>'
        ]}
      end
    end
  end
end
