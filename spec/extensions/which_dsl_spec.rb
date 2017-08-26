require 'daru/extensions/which_dsl'

describe "which DSL" do
  before do
    @df = Daru::DataFrame.new({
      number: [1,2,3,4,5,6,Float::NAN],
      sym: [:one, :two, :three, :four, :five, :six, :seven],
      names: ['sameer', 'john', 'james', 'omisha', 'priyanka', 'shravan',nil]
    })
  end

  it "accepts simple single eq statement" do
    answer = Daru::DataFrame.new({
      number: [4],
      sym: [:four],
      names: ['omisha']
      }, index: Daru::Index.new([3])
    )
    expect( @df.which{ `number` == 4 } ).to eq(answer)
  end

  it "accepts somewhat complex comparison operator chaining" do
    answer = Daru::DataFrame.new({
      number: [3,4],
      sym: [:three, :four],
      names: ['james', 'omisha']
    }, index: Daru::Index.new([2,3]))
    expect(
      @df.which{ (`names` == 'james') | (`sym` == :four) }
      ).to eq(answer)
  end

  it "accepts vector methods" do
    # expect( @df.which{ `number` == `number`.only_valid.max } ).to eq(@df.row_at(5)) # row_at(5) return a Vector object!?
    expect( @df.which{ `number` <= `number`.only_valid.max } ).to eq(@df.row_at(0..5))
  end

end
