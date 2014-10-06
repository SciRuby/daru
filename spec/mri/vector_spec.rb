require 'spec_helper.rb'

describe Daru::Vector do
  context "#initialize" do
    it "creates a vector object with an Array" do
      vector = Daru::Vector.new [1,2,3,4,5], :mowgli

      expect(vector[1])  .to eq(2)
      expect(vector.name).to eq(:mowgli)
    end

    it "creates a vector object with a Range" do
      vector = Daru::Vector.new 1..5, :bakasur

      expect(vector[1])  .to eq(2)
      expect(vector.name).to eq(:bakasur)
    end

    it "creates a vector object with an NMatrix" do
      vector = Daru::Vector.new(NMatrix.new([5], [1,2,3,4,5], 
        dtype: :int32), :scotty)

      expect(vector[1])  .to eq(2)
      expect(vector.name).to eq(:scotty)
    end

    it "creates a vector object with a Matrix" do
      vector = Daru::Vector.new Matrix[[1,2,3,4,5]], :ravan

      expect(vector[1])  .to eq(2)
      expect(vector.name).to eq(:ravan)
    end

    it "creates a vector object with a Hash with different values" do
      vector = Daru::Vector.new({orion: [1,2,3,4,5]})

      expect(vector[1])  .to eq(2)
      expect(vector.name).to eq(:orion)

      vector = Daru::Vector.new({ kirk: 1..5 })

      expect(vector[1])  .to eq(2)
      expect(vector.name).to eq(:kirk)

      vector = Daru::Vector.new({ spock: NMatrix.new([5], [1,2,3,4,5], 
        dtype: :int32) })

      expect(vector[1])  .to eq(2)
      expect(vector.name).to eq(:spock)     
    end

    it "auto assigns a name if not specified" do
      earth    = Daru::Vector.new 1..5
      organion = Daru::Vector.new 1..5

      expect(earth.name == organion.name).to eq(false)
    end
  end

  context "tests for methods" do # TODO: Name this better
    before do
      @anakin = Daru::Vector.new NMatrix.new([5], [1,2,3,4,5]), :anakin
      @luke   = Daru::Vector.new NMatrix.new([3], [3,4,5,6])  , :luke
    end

    it "checks for an each block" do
      sum = 0

      @anakin.each{ |e| sum += e}
      expect(sum).to eq(15)
    end

    it "checks for inequality of vectors" do
      expect(@anakin == @luke).to be(false)
    end

    it "calculates maximum value" do
      expect(@anakin.max).to eq(5)
    end

    it "calculates minimmum value" do
      expect(@anakin.min).to eq(1)
    end

    it "delegates to the internal array storage" do
      expect(@anakin.size).to eq(@anakin.to_a.size)
    end
  end
end if RUBY_ENGINE == 'ruby'