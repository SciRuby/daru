describe Daru::IRuby::Helpers do
  context 'MultiIndex' do
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

    context '#tuples_with_rowspans' do
      subject { described_class.tuples_with_rowspans(index) }

      it { is_expected.to eq [
          [[:a,4],[:one,2],[:bar,1]],
          [                [:baz,1]],
          [       [:two,2],[:bar,1]],
          [                [:baz,1]],
          [[:b,4],[:one,1],[:bar,1]],
          [       [:two,2],[:bar,1]],
          [                [:baz,1]],
          [       [:one,1],[:foo,1]],
          [[:c,4],[:one,2],[:bar,1]],
          [                [:baz,1]],
          [       [:two,2],[:foo,1]],
          [                [:bar,1]]
      ]}
    end

    context '#tuples_with_colspans' do
      subject { described_class.tuples_with_colspans(index) }

      it { is_expected.to eq [
          [[:a, 4], [:b, 4], [:c, 4]],
          [[:one, 2], [:two, 2], [:one, 1], [:two, 2], [:one, 1], [:one, 2], [:two, 2]],
          [[:bar, 1], [:baz, 1], [:bar, 1], [:baz, 1], [:bar, 1], [:bar, 1], [:baz, 1], [:foo, 1], [:bar, 1], [:baz, 1], [:foo, 1], [:bar, 1]]
      ]}
    end
  end
end
