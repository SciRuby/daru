include Daru

describe DateTimeIndex do
  context ".initialize" do
    it "creates DateTimeIndex from Time objects" do
      index = DateTimeIndex.new([
        DateTime.new(2014,7,1),DateTime.new(2014,7,2),
        DateTime.new(2014,7,3),DateTime.new(2014,7,4)])
      expect(index.class).to eq(DateTimeIndex)
      expect(index['2014-7-2']).to eq(1)
    end

    it "attempts conversion to Time from strings" do
      index = DateTimeIndex.new([
        '2014-7-1','2014-7-2','2014-7-3','2014-7-4'], freq: :infer)
      expect(index.class).to eq(DateTimeIndex)
      expect(index['2014-7-2']).to eq(1)
    end

    it "tries to automatically infer the frequency of the data" do
      index = DateTimeIndex.new([
        DateTime.new(2012,1,1), DateTime.new(2012,1,2), DateTime.new(2012,1,3),
        DateTime.new(2012,1,4), DateTime.new(2012,1,5)], freq: :infer)
      expect(index.frequency).to eq('D')
    end

    it "lets setting of string time format" do
      pending
      Daru::DateTimeIndex.format = 'some-date-time-format'
    end
  end

  context '.try_create' do
    it 'creates index from array of dates' do
      index = DateTimeIndex.try_create([
        DateTime.new(2014,7,1),DateTime.new(2014,7,2),
        DateTime.new(2014,7,3),DateTime.new(2014,7,4)])
      expect(index.class).to eq(DateTimeIndex)
    end

    it 'does not creates index from anything else' do
      index = DateTimeIndex.try_create([:a, :b, :c])
      expect(index).to be_nil
    end
  end

  context ".date_range" do
    it "creates DateTimeIndex with default options" do
      index = DateTimeIndex.date_range(:start => DateTime.new(2014,5,3),
        :end => DateTime.new(2014,5,10))

      expect(index).to eq(DateTimeIndex.new([
        DateTime.new(2014,5,3),DateTime.new(2014,5,4),DateTime.new(2014,5,5),
        DateTime.new(2014,5,6),DateTime.new(2014,5,7),DateTime.new(2014,5,8),
        DateTime.new(2014,5,9),DateTime.new(2014,5,10)]))
      expect(index.frequency).to eq('D')
    end

    it "accepts start and end as strings with default options" do
      index = DateTimeIndex.date_range(start: '2014-5-3', end: '2014-5-10')

      expect(index).to eq(DateTimeIndex.new([
        DateTime.new(2014,5,3),DateTime.new(2014,5,4),DateTime.new(2014,5,5),
        DateTime.new(2014,5,6),DateTime.new(2014,5,7),DateTime.new(2014,5,8),
        DateTime.new(2014,5,9),DateTime.new(2014,5,10)]))
      expect(index.frequency).to eq('D')
    end

    it 'fails on wrong string format' do
      expect{DateTimeIndex.date_range(start: '2014/5/3', end: '2014/5/10')}
        .to raise_error(ArgumentError, /Unacceptable date string/)
    end

    it "creates DateTimeIndex of per minute frequency between start and end" do
      index = DateTimeIndex.date_range(start: '2015-7-1',freq: 'M', periods: 10)

      expect(index).to eq(DateTimeIndex.new([
        DateTime.new(2015,7,1,0,0,0),DateTime.new(2015,7,1,0,1,0),DateTime.new(2015,7,1,0,2,0),
        DateTime.new(2015,7,1,0,3,0),DateTime.new(2015,7,1,0,4,0),DateTime.new(2015,7,1,0,5,0),
        DateTime.new(2015,7,1,0,6,0),DateTime.new(2015,7,1,0,7,0),DateTime.new(2015,7,1,0,8,0),
        DateTime.new(2015,7,1,0,9,0)]))
      expect(index.frequency).to eq('M')
    end

    it "creates a DateTimeIndex of hourly frequency between start and end" do
      index = DateTimeIndex.date_range(start: '2015-7-1',freq: 'H', periods: 10)

      expect(index).to eq(DateTimeIndex.new([
        DateTime.new(2015,7,1,0,0,0),DateTime.new(2015,7,1,1,0,0),DateTime.new(2015,7,1,2,0,0),
        DateTime.new(2015,7,1,3,0,0),DateTime.new(2015,7,1,4,0,0),DateTime.new(2015,7,1,5,0,0),
        DateTime.new(2015,7,1,6,0,0),DateTime.new(2015,7,1,7,0,0),DateTime.new(2015,7,1,8,0,0),
        DateTime.new(2015,7,1,9,0,0)]))
      expect(index.frequency).to eq('H')
    end

    it "creates a DateTimeIndex of daily frequency for specified periods" do
      index = DateTimeIndex.date_range(start: '2015-7-29',freq: 'D',periods: 10)

      expect(index).to eq(DateTimeIndex.new([
        DateTime.new(2015,7,29,0,0,0),DateTime.new(2015,7,30,0,0,0),DateTime.new(2015,7,31,0,0,0),
        DateTime.new(2015,8,1,0,0,0),DateTime.new(2015,8,2,0,0,0),DateTime.new(2015,8,3,0,0,0),
        DateTime.new(2015,8,4,0,0,0),DateTime.new(2015,8,5,0,0,0),DateTime.new(2015,8,6,0,0,0),
        DateTime.new(2015,8,7,0,0,0)]))
      expect(index.frequency).to eq('D')
    end

    it "creates a DateTimeIndex of (sunday) weekly frequency" do
      index = DateTimeIndex.date_range(start: '2014-8-2', end: '2014-9-8',
        freq: 'W')

      expect(index).to eq(DateTimeIndex.new([
        DateTime.new(2014,8,3) ,DateTime.new(2014,8,10),DateTime.new(2014,8,17),
        DateTime.new(2014,8,24),DateTime.new(2014,8,31),DateTime.new(2014,9,7)]))
      expect(index.frequency).to eq('W-SUN')
    end

    it "creates a DateTimeIndex of (monday) weekly frequency" do
      index = DateTimeIndex.date_range(:start => '2015-7-6', :periods => 5,
        :freq => 'W-MON')
      expect(index).to eq(DateTimeIndex.new([
        DateTime.new(2015,7,6), DateTime.new(2015,7,13), DateTime.new(2015,7,20),
        DateTime.new(2015,7,27), DateTime.new(2015,8,3)]))
      expect(index.frequency).to eq('W-MON')
    end

    it "creates a DateTimeIndex of month begin frequency" do
      index = DateTimeIndex.date_range(
        :start => '2017-4-14', :freq => 'MB', :periods => 5)
      expect(index).to eq(DateTimeIndex.new([
        DateTime.new(2017,5,1), DateTime.new(2017,6,1),
        DateTime.new(2017,7,1), DateTime.new(2017,8,1),DateTime.new(2017,9,1)]))
    end

    it "creates a DateTimeIndex of month end frequency" do
      index = DateTimeIndex.date_range(
        :start => '2014-2-22', freq: 'ME', periods: 6)
      expect(index).to eq(DateTimeIndex.new([
        DateTime.new(2014,2,28), DateTime.new(2014,3,31), DateTime.new(2014,4,30),
        DateTime.new(2014,5,31), DateTime.new(2014,6,30), DateTime.new(2014,7,31)]))
    end

    it "creates a DateTimeIndex of year begin frequency" do
      index = DateTimeIndex.date_range(:start => '2014-4-2', periods: 3, freq: 'YB')
      expect(index).to eq(DateTimeIndex.new([
        DateTime.new(2015,1,1), DateTime.new(2016,1,1), DateTime.new(2017,1,1)]))
    end

    it "creates a DateTimeIndex of year end frequency" do
      index = DateTimeIndex.date_range(start: '2014-9',end: '2018-1',freq: 'YE')

      expect(index).to eq(DateTimeIndex.new([
        DateTime.new(2014,12,31), DateTime.new(2015,12,31),DateTime.new(2016,12,31),
        DateTime.new(2017,12,31)]))
      expect(index.frequency).to eq('YE')
    end

    it "creates only specfied number of periods taking precendence over end" do
      index = DateTimeIndex.date_range(start: '2014-5-5', end: '2015-3',
        periods: 5, freq: 'YB')
      expect(index).to eq(DateTimeIndex.new([
        DateTime.new(2015,1,1),DateTime.new(2016,1,1),DateTime.new(2017,1,1),
        DateTime.new(2018,1,1),DateTime.new(2019,1,1)]))
    end

    it "does not increment start date if it satisifies the anchor" do
      index = DateTimeIndex.date_range(:start => '2012-1-1', freq: 'MB', periods: 4)
      expect(index).to eq(DateTimeIndex.new(
        [DateTime.new(2012,1,1), DateTime.new(2012,2,1),
         DateTime.new(2012,3,1), DateTime.new(2012,4,1)]))
    end

    it "raises error for different start and end timezones" do
      expect {
        DateTimeIndex.date_range(
          :start => DateTime.new(2012,3,4,12,5,4,"+5:30"),
          :end => DateTime.new(2013,3,4,12,5,4,"+7:30"), freq: 'M')
      }.to raise_error(ArgumentError)
    end
  end

  context '#inspect' do
    subject { index.inspect }

    context 'with known frequency' do
      let(:index){
        DateTimeIndex.new([
          DateTime.new(2014,7,1),DateTime.new(2014,7,2),DateTime.new(2014,7,3),
          DateTime.new(2014,7,4)], freq: :infer)
      }
      it { is_expected.to eq \
        "#<Daru::DateTimeIndex(4, frequency=D) 2014-07-01T00:00:00+00:00...2014-07-04T00:00:00+00:00>"
      }
    end

    context 'with unknown frequency' do
      let(:index){
        DateTimeIndex.new([
          DateTime.new(2014,7,1),DateTime.new(2014,7,2),DateTime.new(2014,7,3),
          DateTime.new(2014,7,4)])
      }
      it { is_expected.to eq \
        "#<Daru::DateTimeIndex(4) 2014-07-01T00:00:00+00:00...2014-07-04T00:00:00+00:00>"
      }
    end

    context 'empty index' do
      let(:index){ DateTimeIndex.new([]) }
      it { is_expected.to eq "#<Daru::DateTimeIndex(0)>" }
    end
  end

  context "#frequency" do
    it "reports the frequency of when a period index is specified" do
      index = DateTimeIndex.new([
        DateTime.new(2014,7,1),DateTime.new(2014,7,2),DateTime.new(2014,7,3),
        DateTime.new(2014,7,4)], freq: :infer)
      expect(index.frequency).to eq('D')
    end

    it "reports frequency as nil for non-periodic index" do
      index = DateTimeIndex.new([
        DateTime.new(2014,7,1),DateTime.new(2014,7,2),DateTime.new(2014,7,3),
        DateTime.new(2014,7,10)], freq: :infer)
      expect(index.frequency).to eq(nil)
    end
  end

  context "#[]" do
    it "accepts complete time as a string" do
      index = DateTimeIndex.new([
        DateTime.new(2014,3,3),DateTime.new(2014,3,4),DateTime.new(2014,3,5),DateTime.new(2014,3,6)],
        freq: :infer)
      expect(index.frequency).to eq('D')
      expect(index['2014-3-5']).to eq(2)
    end

    it "accepts complete time as a DateTime object" do
      index = DateTimeIndex.new([
        DateTime.new(2014,3,3),DateTime.new(2014,3,4),DateTime.new(2014,3,5),DateTime.new(2014,3,6)],
        freq: :infer)
      expect(index[DateTime.new(2014,3,6)]).to eq(3)
    end

    it "accepts only year specified as a string" do
      index = DateTimeIndex.new([
        DateTime.new(2014,5),DateTime.new(2018,6),DateTime.new(2014,7),DateTime.new(2016,7),
        DateTime.new(2015,7),DateTime.new(2013,7)])
      expect(index['2014']).to eq(DateTimeIndex.new([
        DateTime.new(2014,5),DateTime.new(2014,7)]))
    end

    it 'does not fail on absent data' do
      index = DateTimeIndex.new([
        DateTime.new(2014,5),DateTime.new(2018,6),DateTime.new(2014,7),DateTime.new(2016,7),
        DateTime.new(2013,7)])
      p DateTimeIndex.new([])
      expect(index['2015']).to eq(DateTimeIndex.new([]))
    end

    it "accepts only year for frequency data" do
      index = DateTimeIndex.date_range(:start => DateTime.new(2012,3,2),
        periods: 1000, freq: '5D')
      expect(index['2012']).to eq(DateTimeIndex.date_range(
        :start => DateTime.new(2012,3,2), :end => DateTime.new(2012,12,27), freq: '5D'))
    end

    it "accepts year and month specified as a string" do
      index = DateTimeIndex.new([
        DateTime.new(2014,5,3),DateTime.new(2014,5,4),DateTime.new(2014,5,5),
        DateTime.new(2014,6,3),DateTime.new(2014,7,4),DateTime.new(2014,6,5),
        DateTime.new(2014,7,3),DateTime.new(2014,7,4),DateTime.new(2014,7,5)])
      expect(index['2014-6']).to eq(DateTimeIndex.new([
        DateTime.new(2014,6,3),DateTime.new(2014,6,5)]))
    end

    it "accepts year and month for frequency data" do
      index = DateTimeIndex.date_range(start: '2014-1-1', periods: 100, freq: 'MB')
      expect(index['2015-3']).to eq(14)
    end

    it "accepts year, month and date specified as a string" do
      index = DateTimeIndex.new([
        DateTime.new(2012,2,28,0,0,1),DateTime.new(2012,2,25,0,0,1),
        DateTime.new(2012,2,29,0,1,1),DateTime.new(2012,2,29,0,1,3),
        DateTime.new(2012,2,29,0,1,5)])
      expect(index['2012-2-29']).to eq(DateTimeIndex.new([
        DateTime.new(2012,2,29,0,1,1),DateTime.new(2012,2,29,0,1,3),
        DateTime.new(2012,2,29,0,1,5)]))
    end

    it "accepts year, month, date for frequency data" do
      index = DateTimeIndex.date_range(:start => DateTime.new(2012,2,29),
        periods: 1000, freq: 'M')
      expect(index['2012-2-29']).to eq(DateTimeIndex.date_range(
        :start => DateTime.new(2012,2,29),
        :end   => DateTime.new(2012,2,29,16,39,00), freq: 'M'))
    end

    it "accepts year, month, date and specific time as a string" do
      index = DateTimeIndex.date_range(
        :start => DateTime.new(2015,5,3),:end => DateTime.new(2015,5,5), freq: 'M')
      expect(index['2015-5-3 00:04:00']).to eq(4)
    end

    it "accepts with seconds accuracy" do
      index = DateTimeIndex.date_range(
        :start => DateTime.new(2012,3,2,21,4,2), :end => DateTime.new(2012,3,2,21,5,2),
        :freq => 'S')
      expect(index['2012-3-2 21:04:04']).to eq(2)
    end

    it "supports completely specified time ranges" do
      index = DateTimeIndex.date_range(start: '2011-4-1', periods: 50, freq: 'D')
      expect(index['2011-4-5'..'2011-5-3']).to eq(
        DateTimeIndex.date_range(:start => '2011-4-5', :end => '2011-5-3', freq: 'D'))
    end

    it "supports time ranges with only year specified" do
      index = DateTimeIndex.date_range(start: '2011-5-5', periods: 50, freq: 'MONTH')
      expect(index['2011'..'2012']).to eq(
        DateTimeIndex.date_range(:start => '2011-5-5', :end => '2012-12-5',
          :freq => 'MONTH'))
    end

    it "supports time ranges with year and month specified" do
      index = DateTimeIndex.date_range(:start => '2016-4-3', periods: 100, freq: 'D')
      expect(index['2016-4'..'2016-5']).to eq(
        DateTimeIndex.date_range(:start => '2016-4-3', periods: 59, freq: 'D'))
    end

    it "supports time range with year, month and date specified" do
      index = DateTimeIndex.date_range(:start => '2015-7-4', :end => '2015-12-3')
      expect(index['2015-7-4'..'2015-9-3']).to eq(
        DateTimeIndex.date_range(:start => '2015-7-4', :end => '2015-9-3'))
    end

    it "supports time range with year, month, date and hours specified" do
      index = DateTimeIndex.date_range(:start => '2015-4-2', periods: 120, freq: 'H')
      expect(index['2015-4-3 00:00'..'2015-4-3 12:00']).to eq(
        DateTimeIndex.date_range(:start => '2015-4-3', freq: 'H', periods: 13))
    end

    it "returns slice upto last element if overshoot in partial date" do
      index = DateTimeIndex.date_range(:start => '2012-4-2', periods: 100, freq: 'M')
      expect(index['2012-4-2']).to eq(DateTimeIndex.date_range(
        :start => '2012-4-2', periods: 100, freq: 'M'))
    end

    it "returns slice upto last element if overshoot in range" do
      index = DateTimeIndex.date_range(:start => '2012-2-2', :periods => 50,
        freq: 'M')
      expect(index['2012'..'2013']).to eq(DateTimeIndex.date_range(
        :start => '2012-2-2',:periods => 50, freq: 'M'))
    end

    it "returns a slice when given a numeric range" do
      index = DateTimeIndex.date_range(
        :start => DateTime.new(2012,3,1), :periods => 50)
      expect(index[4..10]).to eq(
        DateTimeIndex.date_range(:start => DateTime.new(2012,3,5), :periods => 7))
    end

    it "raises error if key out of bounds" do
      index = DateTimeIndex.date_range(:start => '2012-1', :periods => 5)
      expect{
        index['2011']
      }.to raise_error(ArgumentError)
    end

    it "raises error if date not present (exact date)" do
      expect {
        index = DateTimeIndex.date_range(:start => '2011', :periods => 5, :freq => 'MONTH')
        index[DateTime.new(2013,1,4)]
        }.to raise_error(ArgumentError)
    end

    it "raises error if date not present (string)" do
      expect {
        index = DateTimeIndex.date_range(:start => '2012-2-3', :periods => 10)
        index['2012-2-4 12']
      }.to raise_error(ArgumentError)
    end

    it "raises error for out of bounds range" do
      expect {
        index = DateTimeIndex.date_range(:start => '2012', :periods => 100)
        index['2001'..'2005']
      }.to raise_error(ArgumentError)
    end
  end

  context "#pos" do
    let(:idx) do
      described_class.new([
        DateTime.new(2014,3,3),
        DateTime.new(2014,3,4),
        DateTime.new(2014,3,5),
        DateTime.new(2014,3,6)
        ], freq: :infer
      )
    end

    context "single index" do
      it { expect(idx.pos '2014-3-4').to eq 1 }
    end

    context "multiple indexes" do
      subject { idx.pos '2014' }

      it { is_expected.to be_a Array }
      its(:size) { is_expected.to eq 4 }
      it { is_expected.to eq [0, 1, 2, 3] }
    end

    context "single positional index" do
      it { expect(idx.pos 1).to eq 1 }
    end

    context "multiple positional indexes" do
      subject { idx.pos 0, 2 }

      it { is_expected.to be_a Array }
      its(:size) { is_expected.to eq 3 }
      it { is_expected.to eq [0, 1, 2] }
    end
  end

  context "#subset" do
    let(:idx) do
      described_class.new([
        DateTime.new(2014,3,3),
        DateTime.new(2014,3,4),
        DateTime.new(2014,3,5),
        DateTime.new(2014,3,6)
        ], freq: :infer
      )
    end

    context "multiple indexes" do
      subject { idx.subset '2014' }

      it { is_expected.to be_a described_class }
      its(:size) { is_expected.to eq 4 }
      it { is_expected.to eq idx }
    end

    context "multiple positional indexes" do
      subject { idx.subset 0, 2 }

      it { is_expected.to be_a described_class }
      its(:size) { is_expected.to eq 3 }
      its(:to_a) { is_expected.to eq [DateTime.new(2014, 3, 3),
        DateTime.new(2014, 3, 4), DateTime.new(2014, 3, 5)] }
    end
  end

  context "#slice" do
    it "supports both DateTime objects" do
      index = DateTimeIndex.date_range(:start => '2012', :periods => 50,
        :freq => 'M')
      expect(index.slice(DateTime.new(2012,1,1), DateTime.new(2012,1,1,0,6))).to eq(
        DateTimeIndex.date_range(:start => '2012', :periods => 7, :freq => 'M'))
    end

    it "supports single DateTime object on the left" do
      index = DateTimeIndex.date_range(:start => '2012', :periods => 40, :freq => 'M')
      expect(index.slice('2012', DateTime.new(2012,1,1,0,20))).to eq(
        DateTimeIndex.date_range(:start => '2012', :periods => 21, :freq => 'M'))
    end

    it "supports single DateTime object on the right" do
      index = DateTimeIndex.date_range(:start => '2012', :periods => 40, :freq => 'MONTH')
      expect(index.slice(DateTime.new(2012), '2013')).to eq(
        DateTimeIndex.date_range(:start => '2012', :periods => 24, :freq => 'MONTH'))
    end

    it "supports two strings" do
      index = DateTimeIndex.date_range(:start => '2012', :periods => 40, :freq => 'MONTH')
      expect(index.slice('2012', '2013')).to eq(
        DateTimeIndex.date_range(:start => '2012', :periods => 24, :freq => 'MONTH'))

      # FIXME: It works this way now, yet I'm faithfully not sure that is most
      # reasonable behavior. At least MY expectation is "slice(2012, 2013)" returns
      # "from start of 2012 to start of 2013"... Or am I missing something?.. - zverok
    end
  end

  context "#size" do
    it "returns the size of the DateTimeIndex" do
      index = DateTimeIndex.date_range start: DateTime.new(2014,5,3), periods: 100
      expect(index.size).to eq(100)
    end
  end

  context "#add" do
    before { skip }
    let(:idx) { Daru::Index.new [:a, :b, :c] }

    context "single index" do
      subject { idx }
      before { idx.add :d }

      its(:to_a) { is_expected.to eq [:a, :b, :c, :d] }
    end

    context "mulitple indexes" do
      subject { idx }
      before { idx.add :d, :e }

      its(:to_a) { is_expected.to eq [:a, :b, :c, :d, :e] }
    end
  end

  context "#to_a" do
    it "returns an Array of ruby Time objects" do
      index = DateTimeIndex.date_range(
        start: DateTime.new(2012,2,1), :end => DateTime.new(2012,2,4))
      expect(index.to_a).to eq([
        DateTime.new(2012,2,1),DateTime.new(2012,2,2),DateTime.new(2012,2,3),DateTime.new(2012,2,4)])
    end

    context 'empty index' do
      subject(:index) { DateTimeIndex.new([]) }
      its(:to_a) { is_expected.to eq [] }
    end
  end

  context "#shift" do
    it "shifts all dates to the future by specified value (with offset)" do
      index = DateTimeIndex.date_range(
        :start => '2012-1-1', :freq => 'MB', :periods => 10)
      expect(index.shift(3)).to eq(DateTimeIndex.date_range(
        :start => '2012-4-1', :freq => 'MB', :periods => 10))
    end

    it "shifts all dates by the given offset" do
      offset = Daru::Offsets::Minute.new
      index = DateTimeIndex.date_range(
        :start => '2012-3-1', :freq => 'D', :periods => 10)
      expect(index.shift(offset)).to eq(
        DateTimeIndex.date_range(
          :start => '2012-3-1 00:01', :freq => 'D', :periods => 10))
    end
  end

  context "#lag" do
    it "shifts all dates to the past by specified value (with offset)" do
      index = DateTimeIndex.date_range(
        :start => '2012-5-5', :freq => 'D', :periods => 5)
      expect(index.lag(2)).to eq(DateTimeIndex.date_range(
        :start => '2012-5-3', :freq => 'D', :periods => 5))
    end

    it "lags all dates by the given offset" do
      offset = Daru::Offsets::Month.new
      index = DateTimeIndex.date_range(
        :start => '2012-4-5', :freq => 'MONTH', :periods => 10)
      expect(index.lag(offset)).to eq(
        DateTimeIndex.date_range(:start => '2012-3-5', :periods => 10, freq: offset))
    end
  end

  [:year, :month, :day, :hour, :min, :sec].each do |meth|
    dates = [
      DateTime.new(2012,5,1,12,5,4), DateTime.new(2015,5,1,13,5),
      DateTime.new(2012,8,1,12,5,3), DateTime.new(2015,1,4,16,5,44)
    ]
    curated = dates.inject([]) do |arr, e|
      arr << e.send(meth)
      arr
    end

    context "##{meth}" do
      it "returns #{meth} of all dates as an Array" do
        index = DateTimeIndex.new(dates)
        expect(index.send(meth)).to eq(curated)
      end
    end
  end

  context "#include?" do
    it "returns true if an index is present" do
      index = DateTimeIndex.date_range(:start => '2012-1-4', :periods => 100, :freq => 'D')
      expect(index.include?(DateTime.new(2012,1,6))).to eq(true)
      expect(index.include?(DateTime.new(2011,4,2))).to eq(false)
    end
  end
end
