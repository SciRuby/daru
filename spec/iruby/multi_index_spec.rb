describe Daru::MultiIndex, '#to_html' do
  let(:index) {
    Daru::MultiIndex.from_tuples [
      [:a,:one,:bar],
      [:a,:one,:baz],
      [:a,:two,:bar],
      [:a,:two,:baz],
      [:b,:one,:bar],
      [:b,:two,:bar],
      [:b,:two,:baz],
      [:b,:one,:foo],
      [:c,:one,:bar],
      [:c,:one,:baz],
      [:c,:two,:foo],
      [:c,:two,:bar]
    ]
  }

  let(:table) { Nokogiri::HTML(index.to_html) }

  describe 'first row' do
    subject { table.at('tr:first-child > th') }
    its(['colspan']) { is_expected.to eq '3' }
    its(:text) { is_expected.to eq 'Daru::MultiIndex(12x3)' }
  end

  describe 'next row' do
    let(:row) { table.at('tr:nth-child(2)') }
    subject { row.inner_html.scan(/<th.+?<\/th>/) }

    it { is_expected.to eq [
        '<th rowspan="4">a</th>',
        '<th rowspan="2">one</th>',
        '<th rowspan="1">bar</th>'
    ]}
  end
end
