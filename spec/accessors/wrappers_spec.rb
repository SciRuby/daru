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

describe Daru::Accessors::ArrayWrapper do

end

describe Daru::Accessors::GSLWrapper do
  before :each do
    @stub_context = Object.new
    @gsl_wrapper = Daru::Accessors::GSLWrapper.new([1,2,3,4,5,6], @stub_context)
  end

  context ".new" do
    it "actually creates a GSL Vector" do
      expect(@gsl_wrapper.data.class).to eq(GSL::Vector)
    end
  end

  context "#mean" do
    it "computes mean" do
      expect(@gsl_wrapper.mean).to eq(3.5)
    end
  end

  context "#map!" do
    it "destructively maps" do
      expect(@gsl_wrapper.map! { |a| a += 1 }).to eq(
        Daru::Accessors::GSLWrapper.new([2,3,4,5,6,7], @stub_context)
      )
    end
  end

  context "#delete_at" do
    it "deletes at key" do
      expect(@gsl_wrapper.delete_at(2)).to eq(3)

      expect(@gsl_wrapper).to eq(
        Daru::Accessors::GSLWrapper.new([1,2,4,5,6], @stub_context)
      )
    end
  end

  context "#index" do
    it "returns index of value" do
      expect(@gsl_wrapper.index(3)).to eq(2)
    end
  end

  context "#push" do
    it "appends element" do
      expect(@gsl_wrapper.push(15)).to eq(
        Daru::Accessors::GSLWrapper.new([1,2,3,4,5,6,15], @stub_context)
      )
    end
  end
end
