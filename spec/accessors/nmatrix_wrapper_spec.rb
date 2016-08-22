require 'spec_helper.rb'

describe Daru::Accessors::NMatrixWrapper do
  before :each do
    stub_context = Object.new
    @nm_wrapper = Daru::Accessors::NMatrixWrapper.new([1,2,3,4,5], stub_context, :float32)
  end

  it "checks for actual NMatrix creation" do
    expect(@nm_wrapper.data.class).to eq(NMatrix)
  end

  it "checks the actual size of the NMatrix object" do
    expect(@nm_wrapper.data.size).to eq(10)
  end

  it "checks that @size is the number of elements in the vector" do
    expect(@nm_wrapper.size).to eq(5)
  end

  it "checks for underlying NMatrix data type" do
    expect(@nm_wrapper.data.dtype).to eq(:float32)
  end

  it "resizes" do
    @nm_wrapper.resize(100)

    expect(@nm_wrapper.size).to eq(5)
    expect(@nm_wrapper.data.size).to eq(100)
    expect(@nm_wrapper.data).to eq(NMatrix.new [100], [1,2,3,4,5])
  end
end
