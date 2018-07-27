describe Daru::Core::GroupBy do
  before do
    @df = Daru::DataFrame.new({
      a: %w{foo bar foo bar   foo bar foo foo},
      b: %w{one one two three two two one three},
      c:   [1  ,2   ,3  ,1     ,3   ,6  ,3  ,8],
      d:   [11 ,22 ,33 ,44   ,55 ,66 ,77 ,88]
    }, order: [:a, :b, :c, :d])

    @sl_group = @df.group_by(:a)
    @dl_group = @df.group_by([:a, :b])
    @tl_group = @df.group_by([:a,:b,:c])

    @sl_index = Daru::Index.new(['bar', 'foo'])
    @dl_multi_index = Daru::MultiIndex.from_tuples([
      ['bar', 'one'],
      ['bar', 'three'],
      ['bar', 'two'],
      ['foo', 'one'],
      ['foo', 'three'],
      ['foo', 'two']
    ])
    @tl_multi_index = Daru::MultiIndex.from_tuples([
      ['bar', 'one'  , 2],
      ['bar', 'three', 1],
      ['bar', 'two'  , 6],
      ['foo', 'one'  , 1],
      ['foo', 'one'  , 3],
      ['foo', 'three', 8],
      ['foo', 'two'  , 3]
    ])

  end

  context 'with nil values' do
    before do
      @df[:w_nils] = Daru::Vector.new([11 ,nil ,33 ,nil   ,nil ,66 ,77 ,88])
    end

    it 'groups by nil values' do
      expect(@df.group_by(:w_nils).groups[[nil]]).to eq([1,3,4])
    end

    it "uses a multi-index when nils are part of the grouping keys" do
      expect(@df.group_by(:a, :w_nils).send(:multi_indexed_grouping?)).to be true
    end
  end

  context "#initialize" do
    let(:df_emp) { Daru::DataFrame.new(
      employee: %w[John Jane Mark John Jane Mark],
      month: %w[June June June July July July],
      salary: [1000, 500, 700, 1200, 600, 600]
    ) }
    let(:employee_grp) { df_emp.group_by(:employee).df }
    let(:mi_single) { Daru::MultiIndex.from_tuples([
        ['Jane', 1], ['Jane', 4], ['John', 0],
        ['John', 3], ['Mark', 2], ['Mark', 5]
        ]
      )}

    let(:emp_month_grp) { df_emp.group_by([:employee, :month]).df }
    let(:mi_double) { Daru::MultiIndex.from_tuples([
        ['Jane', 'July', 4], ['Jane', 'June', 1], ['John', 'July', 3],
        ['John', 'June', 0], ['Mark', 'July', 5], ['Mark', 'June', 2]
        ]
      )}

    let(:emp_month_salary_grp) {
      df_emp.group_by([:employee, :month, :salary]).df }
    let(:mi_triple) { Daru::MultiIndex.from_tuples([
        ['Jane', 'July', 600, 4], ['Jane', 'June', 500, 1],
        ['John', 'July', 1200, 3], ['John', 'June', 1000, 0],
        ['Mark', 'July', 600, 5], ['Mark', 'June', 700, 2]
        ]
      )}

    it "groups by a single tuple" do
      expect(@sl_group.groups).to eq({
        ['bar'] => [1,3,5],
        ['foo'] => [0,2,4,6,7]
      })
    end

    it "returns dataframe with MultiIndex, groups by single layer hierarchy" do
      expect(employee_grp).to eq(Daru::DataFrame.new({
        month: ["June", "July", "June", "July", "June", "July"],
        salary: [500, 600, 1000, 1200, 700, 600]
        }, index: mi_single))
    end

    it "returns dataframe with MultiIndex, groups by double layer hierarchy" do
      expect(emp_month_grp).to eq(Daru::DataFrame.new({
        salary: [600, 500, 1200, 1000, 600, 700]
        }, index: mi_double))
    end

    it "returns dataframe with MultiIndex, groups by triple layer hierarchy" do
      expect(emp_month_salary_grp).to eq(Daru::DataFrame.new({
        }, index: mi_triple))
    end

    it "groups by a double layer hierarchy" do
      expect(@dl_group.groups).to eq({
        ['foo', 'one']   => [0,6],
        ['bar', 'one']   => [1],
        ['foo', 'two']   => [2,4],
        ['bar', 'three'] => [3],
        ['bar', 'two']   => [5],
        ['foo', 'three'] => [7]
      })
    end

    it "groups by a triple layer hierarchy" do
      expect(@tl_group.groups).to eq({
        ['bar', 'one'  , 2] => [1],
        ['bar', 'three', 1] => [3],
        ['bar', 'two'  , 6] => [5],
        ['foo', 'one'  , 1] => [0],
        ['foo', 'one'  , 3] => [6],
        ['foo', 'three', 8] => [7],
        ['foo', 'two'  , 3] => [2,4]
      })
    end

    it "raises error if a non-existent vector is passed as args" do
      expect {
        @df.group_by([:a, :ted])
      }.to raise_error
    end
  end

  context "#size" do
    it "returns a vector containing the size of each group" do
      expect(@dl_group.size).to eq(Daru::Vector.new([1,1,1,2,1,2], index: @dl_multi_index))
    end

    it "returns an empty vector if given an empty dataframe" do
      df = Daru::DataFrame.new({ a: [], b: [] })
      expect(df.group_by(:a).size).to eq(Daru::Vector.new([]))
    end
  end

  context "#get_group" do
    it "returns the whole sub-group for single layer grouping" do
      expect(@sl_group.get_group(['bar'])).to eq(Daru::DataFrame.new({
        a: ['bar', 'bar', 'bar'],
        b: ['one', 'three', 'two'],
        c: [2,1,6],
        d: [22,44,66]
        }, index: [1,3,5]
      ))
    end

    it "returns the whole sub-group for double layer grouping" do
      expect(@dl_group.get_group(['bar', 'one'])).to eq(Daru::DataFrame.new({
        a: ['bar'],
        b: ['one'],
        c: [2],
        d: [22]
        }, index: [1]
      ))
    end

    it "returns the whole sub-group for triple layer grouping" do
      expect(@tl_group.get_group(['foo','two',3])).to eq(Daru::DataFrame.new({
        a: ['foo', 'foo'],
        b: ['two', 'two'],
        c: [3,3],
        d: [33,55]
        }, index: [2,4]
      ))
    end

    it "raises error for incomplete specification" do
      expect {
        @tl_group.get_group(['foo'])
      }.to raise_error
    end

    it "raises error for over specification" do
      expect {
        @sl_group.get_group(['bar', 'one'])
      }.to raise_error
    end
  end

  context '#each_group' do
    it 'enumerates groups' do
      ret = []
      @dl_group.each_group { |g| ret << g }
      expect(ret.count).to eq 6
      expect(ret).to all be_a(Daru::DataFrame)
      expect(ret.first).to eq(Daru::DataFrame.new({
        a: ['bar'],
        b: ['one'],
        c: [2],
        d: [22]
        }, index: [1]
      ))
    end
  end

  context '#each_group without block' do
    it 'enumerates groups' do
      enum = @dl_group.each_group

      expect(enum.count).to eq 6
      expect(enum).to all be_a(Daru::DataFrame)
      expect(enum.to_a.last).to eq(Daru::DataFrame.new({
        a: ['foo', 'foo'],
        b: ['two', 'two'],
        c: [3, 3],
        d: [33, 55]
        }, index: [2, 4]
      ))
    end
  end

  context '#first' do
    it 'gets the first row from each group' do
      expect(@dl_group.first).to eq(Daru::DataFrame.new({
        a: %w{bar bar   bar foo foo   foo },
        b: %w{one three two one three two },
        c:   [2  ,1    ,6  ,1  ,8    ,3   ],
        d:   [22 ,44   ,66 ,11 ,88   ,33  ]
      }, index: [1,3,5,0,7,2]))
    end
  end

  context '#last' do
    it 'gets the last row from each group' do
      expect(@dl_group.last).to eq(Daru::DataFrame.new({
        a: %w{bar bar   bar foo foo   foo },
        b: %w{one three two one three two },
        c:   [2  ,1    ,6  ,3  ,8    ,3   ],
        d:   [22 ,44   ,66 ,77 ,88   ,55  ]
      }, index: [1,3,5,6,7,4]))
    end
  end

  context "#mean" do
    it "computes mean of the numeric columns of a single layer group" do
      expect(@sl_group.mean).to eq(Daru::DataFrame.new({
        :c => [3.0, 3.6],
        :d => [44.0, 52.8]
        }, index: @sl_index
      ))
    end

    it "computes mean of the numeric columns of a double layer group" do
      expect(@dl_group.mean).to eq(Daru::DataFrame.new({
        c: [2,1,6,2,8,3],
        d: [22,44,66,44,88,44]
        }, index: @dl_multi_index))
    end

    it "computes mean of the numeric columns of a triple layer group" do
      expect(@tl_group.mean).to eq(Daru::DataFrame.new({
        d: [22,44,66,11,77,88,44]
        }, index: @tl_multi_index
      ))
    end
  end

  context "#sum" do
    it "calculates the sum of the numeric columns of a single layer group" do
      expect(@sl_group.sum).to eq(Daru::DataFrame.new({
        c: [9, 18],
        d: [132, 264]
        }, index: @sl_index
      ))
    end

    it "calculates the sum of the numeric columns of a double layer group" do
      expect(@dl_group.sum).to eq(Daru::DataFrame.new({
        c: [2,1,6,4,8,6],
        d: [22,44,66,88,88,88]
        }, index: @dl_multi_index))
    end

    it "calculates the sum of the numeric columns of a triple layer group" do
      expect(@tl_group.sum).to eq(Daru::DataFrame.new({
        d: [22,44,66,11,77,88,88]
        }, index: @tl_multi_index))
    end
  end

  [:median, :std, :max, :min].each do |numeric_method|
    it "works somehow" do
      expect(@sl_group.send(numeric_method).index).to eq @sl_index
      expect(@dl_group.send(numeric_method).index).to eq @dl_multi_index
      expect(@tl_group.send(numeric_method).index).to eq @tl_multi_index
    end
  end

  context "#product" do
    it "calculates product for single layer groups" do
      # TODO
    end

    it "calculates product for double layer groups" do
      # TODO
    end

    it "calculates product for triple layer groups" do
      # TODO
    end
  end

  context "#count" do
    it "counts the number of elements in a single layer group" do
      expect(@sl_group.count).to eq(Daru::DataFrame.new({
        b: [3,5],
        c: [3,5],
        d: [3,5]
        }, index: @sl_index))
    end

    it "counts the number of elements in a double layer group" do
      expect(@dl_group.count).to eq(Daru::DataFrame.new({
        c: [1,1,1,2,1,2],
        d: [1,1,1,2,1,2]
        }, index: @dl_multi_index))
    end

    it "counts the number of elements in a triple layer group" do
      expect(@tl_group.count).to eq(Daru::DataFrame.new({
        d: [1,1,1,1,1,1,2]
        }, index: @tl_multi_index))
    end
  end

  context "#std" do
    it "calculates sample standard deviation for single layer groups" do
      # TODO
    end

    it "calculates sample standard deviation for double layer groups" do
      # TODO
    end

    it "calculates sample standard deviation for triple layer groups" do
      # TODO
    end
  end

  context "#max" do
    it "calculates max value for single layer groups" do
      # TODO
    end

    it "calculates max value for double layer groups" do
      # TODO
    end

    it "calculates max value for triple layer groups" do
      # TODO
    end
  end

  context "#min" do
    it "calculates min value for single layer groups" do
      # TODO
    end

    it "calculates min value for double layer groups" do
      # TODO
    end

    it "calculates min value for triple layer groups" do
      # TODO
    end
  end

  context "#median" do
    it "calculates median for single layer groups" do
      # TODO
    end

    it "calculates median for double layer groups" do
      # TODO
    end

    it "calculates median for triple layer groups" do
      # TODO
    end
  end

  context "#head" do
    it "returns first n rows of each single layer group" do
      expect(@sl_group.head(2)).to eq(Daru::DataFrame.new({
        a: ['bar', 'bar','foo','foo'],
        b: ['one', 'three','one', 'two'],
        c: [2, 1, 1, 3],
        d: [22, 44, 11, 33]
      }, index: [1,3,0,2]))
    end

    it "returns first n rows of each double layer group" do
      expect(@dl_group.head(2)).to eq(Daru::DataFrame.new({
        a: ['bar','bar','bar','foo','foo','foo','foo','foo'],
        b: ['one','three','two','one','one','three','two','two'],
        c: [2,1,6,1,3,8,3,3],
        d: [22,44,66,11,77,88,33,55]
      }, index: [1,3,5,0,6,7,2,4]))
    end

    it "returns first n rows of each triple layer group" do
      expect(@tl_group.head(1)).to eq(Daru::DataFrame.new({
        a: ['bar','bar','bar','foo','foo','foo','foo'],
        b: ['one','three','two','one','one','three','two'],
        c: [2,1,6,1,3,8,3],
        d: [22,44,66,11,77,88,33]
        }, index: [1,3,5,0,6,7,2]))
    end
  end

  context "#tail" do
    it "returns last n rows of each single layer group" do
      expect(@sl_group.tail(1)).to eq(Daru::DataFrame.new({
        a: ['bar','foo'],
        b: ['two', 'three'],
        c: [6,8],
        d: [66,88]
      }, index: [5,7]))
    end

    it "returns last n rows of each double layer group" do
      expect(@dl_group.tail(2)).to eq(Daru::DataFrame.new({
        a: ['bar','bar','bar','foo','foo','foo','foo','foo'],
        b: ['one','three','two','one','one','three','two','two'],
        c: [2,1,6,1,3,8,3,3],
        d: [22,44,66,11,77,88,33,55]
        }, index: [1,3,5,0,6,7,2,4]))
    end

    it "returns last n rows of each triple layer group" do
      expect(@tl_group.tail(1)).to eq(Daru::DataFrame.new({
        a: ['bar','bar','bar','foo','foo','foo','foo'],
        b: ['one','three','two','one','one','three','two'],
        c: [2,1,6,1,3,8,3],
        d: [22,44,66,11,77,88,55]
        }, index: [1,3,5,0,6,7,4]))
    end
  end

  context "#[]" do
    pending
  end

  context "#reduce" do
    it "returns a vector that concatenates strings in a group" do
      string_concat = lambda { |result, row| result += row[:b] }
      expect(@sl_group.reduce('', &string_concat)).to eq(Daru::Vector.new(['onethreetwo', 'onetwotwoonethree'], index: @sl_index))
    end

    it "works with multi-indexes" do
      string_concat = lambda { |result, row| result += row[:b] }
      expect(@dl_group.reduce('', &string_concat)).to eq \
        Daru::Vector.new(['one', 'three', 'two', 'oneone', 'three', 'twotwo'], index: @dl_multi_index)
    end
  end

  context 'groups by first vector if no vector mentioned' do
    subject { @df.group_by }

    it { is_expected.to be_a Daru::Core::GroupBy }
    its(:groups) { is_expected.to eq @sl_group.groups }
    its(:size) { is_expected.to eq @sl_group.size }
  end

  context 'group and sum with numeric indices' do
    let(:df) { Daru::DataFrame.new({ g: ['a','a','a'], num: [1,2,3]}, index: [2,12,23]) }

    subject { df.group_by([:g]).sum }

    it { is_expected.to eq Daru::DataFrame.new({num: [6]}, index: ['a']) }
  end

  context 'when dataframe tuples contain nils in mismatching positions' do

    let(:df){
      Daru::DataFrame.new(
        {
          'string1' => ["Color", "Color", "Color", "Color", nil, "Color", "Color", " Black and White"],
          'string2' => ["Test", "test2", nil, "test3", nil, "test", "test3", "test5"],
          'num' => [1, nil, 3, 4, 5, 6, 7, nil]
        }
      )
    }

    it 'groups by without errors' do
      expect { df.group_by(df.vectors.map(&:to_s)) }.to_not raise_error(ArgumentError)
    end
  end
  
  context '#aggregate' do
    let(:dataframe) { Daru::DataFrame.new({
      employee: %w[John Jane Mark John Jane Mark],
      month: %w[June June June July July July],
      salary: [1000, 500, 700, 1200, 600, 600]})
    }
    context 'group and aggregate sum for particular single vector' do
      subject { dataframe.group_by([:employee]).aggregate(salary: :sum) }

      it { is_expected.to eq Daru::DataFrame.new({
              salary: [1100, 2200, 1300]},
              index: ['Jane', 'John', 'Mark'])
      }
    end

    context 'group and aggregate sum and lambda function for vectors' do
      subject { dataframe.group_by([:employee]).aggregate(
        salary: :sum,
        month: ->(vec) { vec.to_a.join('/') }) }

      it { is_expected.to eq Daru::DataFrame.new({
        salary: [1100, 2200, 1300],
        month: ['June/July', 'June/July', 'June/July']},
        index: ['Jane', 'John', 'Mark'],
        order: [:salary, :month])
      }
    end

    context 'group and aggregate sum and lambda functions on dataframe' do
      subject { dataframe.group_by([:employee]).aggregate(
        salary: :sum,
        month: ->(vec) { vec.to_a.join('/') },
        mean_salary: ->(df) { df.salary.mean },
        periods: ->(df) { df.size }
      )}

      it { is_expected.to eq Daru::DataFrame.new({
        salary: [1100, 2200, 1300],
        month: ['June/July', 'June/July', 'June/July'],
        mean_salary: [550.0, 1100.0, 650.0],
        periods: [2, 2, 2]},
        index: ['Jane', 'John', 'Mark'], order: [:salary, :month,
                                                :mean_salary, :periods]) }
    end

    context 'group_by and aggregate on mixed MultiIndex' do
      let(:df) { Daru::DataFrame.new(
                    name: ['Ram','Krishna','Ram','Krishna','Krishna'],
                    visited: [
                      'Hyderabad', 'Delhi', 'Mumbai', 'Raipur', 'Banglore']
                 )
                }
      let(:df_mixed) { Daru::DataFrame.new(
                    name: ['Krishna','Ram','Krishna','Krishna'],
                    visited: [
                      'Delhi', 'Mumbai', 'Raipur', 'Banglore']
                 )
                }
      it 'group_by' do
        expect(df.group_by(:name).df).to eq(
          Daru::DataFrame.new({
            visited: ['Delhi', 'Raipur', 'Banglore', 'Hyderabad', 'Mumbai']},
            index: Daru::MultiIndex.from_tuples(
                [['Krishna', 1], ['Krishna', 3], ['Krishna', 4],
                ['Ram', 0], ['Ram', 2]]
            )
          )
        )
      end

      it 'group_by and aggregate' do
        expect(
          df.group_by(:name).aggregate(
            visited: -> (vec){vec.to_a.join(',')})).to eq(
              Daru::DataFrame.new({
                visited: ['Delhi,Raipur,Banglore', 'Hyderabad,Mumbai']},
                index: ['Krishna', 'Ram']
              )
          )
      end

      it 'group_by and aggregate when anyone index is not multiple times' do
        expect(
          df_mixed.group_by(:name).aggregate(
            visited: -> (vec){vec.to_a.join(',')})).to eq(
              Daru::DataFrame.new({
                visited: ['Delhi,Raipur,Banglore', 'Mumbai']},
                index: ['Krishna', 'Ram']
              )
          )
      end
    end

    let(:spending_df) {
      Daru::DataFrame.rows([
        [2010,    'dev',  50, 1],
        [2010,    'dev', 150, 1],
        [2010,    'dev', 200, 1],
        [2011,    'dev',  50, 1],
        [2012,    'dev', 150, 1],

        [2011, 'office', 300, 1],

        [2010, 'market',  50, 1],
        [2011, 'market', 500, 1],
        [2012, 'market', 500, 1],
        [2012, 'market', 300, 1],

        [2012,    'R&D',  10, 1],],
        order: [:year, :category, :spending, :nb_spending])
    }
    let(:multi_index_year_category) {
      Daru::MultiIndex.from_tuples([
                       [2010, "dev"], [2010, "market"],
                       [2011, "dev"], [2011, "market"], [2011, "office"],
        [2012, "R&D"], [2012, "dev"], [2012, "market"]])
    }

    context 'group_by and aggregate on multiple elements' do
      it 'does aggregate' do
        expect(spending_df.group_by([:year, :category]).aggregate(spending: :sum)).to eq(
          Daru::DataFrame.new({spending: [400, 50, 50, 500, 300, 10, 150, 800]}, index: multi_index_year_category))
      end

      it 'works as older methods' do
        older_way = spending_df.group_by([:year, :category]).sum

        newer_way = spending_df.group_by([:year, :category]).aggregate(spending: :sum, nb_spending: :sum)
        expect(newer_way).to eq(older_way)

        contrived_way = spending_df.group_by([:year, :category]).aggregate(spending: :sum, nb_spending_lambda: ->(df) { df[:nb_spending].sum })
        contrived_way.rename_vectors(nb_spending_lambda: :nb_spending)
        expect(contrived_way).to eq(older_way)
      end

      context 'can aggregate on MultiIndex' do
        let(:multi_indexed_aggregated_df) { spending_df.group_by([:year, :category]).aggregate(spending: :sum) }
        let(:index_year) { Daru::Index.new([2010, 2011, 2012]) }
        let(:index_category) { Daru::Index.new(["dev", "market", "office", "R&D"]) }

        it 'aggregates by default on the last layer of MultiIndex' do
          expect(multi_indexed_aggregated_df.aggregate(spending: :sum)).to eq(
            Daru::DataFrame.new({spending: [450, 850, 960]}, index: index_year))
        end

        it 'can aggregate on the first layer of MultiIndex' do
          expect(multi_indexed_aggregated_df.aggregate({spending: :sum},0)).to eq(
            Daru::DataFrame.new({spending: [600, 1350, 300, 10]}, index: index_category))
        end

        it 'does coercion: when one layer is remaining, MultiIndex is coerced in Index that does not aggregate anymore' do
          df_with_simple_index = multi_indexed_aggregated_df.aggregate(spending: :sum)
          expect(df_with_simple_index.aggregate(spending: :sum)).to eq(df_with_simple_index)
        end
      end
    end
  end
end
