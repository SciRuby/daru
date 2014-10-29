require 'spec_helper.rb'

describe Daru::Vector do
  context "#initialize" do
    it "initializes from an Array" do
      dv = Daru::Vector.new :ravan, [1,2,3,4,5], [:ek, :don, :teen, :char, :pach]

      expect(dv.name) .to eq(:ravan)
      expect(dv.index).to eq(Daru::Index.new [:ek, :don, :teen, :char, :pach])
    end

    it "accepts Index object" do
      idx = Daru::Index.new [:yoda, :anakin, :obi, :padme, :r2d2]

      dv = Daru::Vector.new :yoga, [1,2,3,4,5], idx

      expect(dv.name) .to eq(:yoga)
      expect(dv.index).to eq(idx)
    end

    it "raises error for improper Index" do
      expect {
        dv = Daru::Vector.new :yoga, [1,2,3,4,5], [:i, :j, :k]
      }.to raise_error

      expect {
        idx = Daru::Index.new [:i, :j, :k]
        dv  = Daru::Vector.new :yoga, [1,2,3,4,5], idx 
      }.to raise_error
    end

    it "initializes without specifying an index" do
      dv = Daru::Vector.new :vishnu, [1,2,3,4,5]

      expect(dv.index).to eq(Daru::Index.new [0,1,2,3,4])
    end

    it "inserts nils for extra indices" do
      dv = Daru::Vector.new :yoga, [1,2,3], [0,1,2,3,4]

      expect(dv).to eq([1,2,3,nil,nil].dv(:yoga))
    end
  end

  context "#[]" do
    before :each do
      @dv = Daru::Vector.new :yoga, [1,2,3,4,5], [:yoda, :anakin, :obi, :padme, :r2d2]
    end

    it "returns an element after passing an index" do
      expect(@dv[:yoda]).to eq(1)
    end

    it "returns an element after passing a numeric index" , :focus => true do
      expect(@dv[0]).to eq(1)
    end

    it "returns a vector with given indices for multiple indices" do
      expect(@dv[:yoda, :anakin]).to eq(Daru::Vector.new(:yoga, [1,2], 
        [:yoda, :anakin]))
    end
  end

  context "#[]=" do
    before :each do
      @dv = Daru::Vector.new :yoga, [1,2,3,4,5], [:yoda, :anakin, :obi, :padme, :r2d2]
    end

    it "assigns at the specified index" do
      @dv[:yoda] = 666

      expect(@dv[:yoda]).to eq(666)
    end

    it "assigns at the specified Integer index" do
      @dv[0] = 666

      expect(@dv[:yoda]).to eq(666)
    end
  end

  context "#concat" do
    before :each do
      @dv = Daru::Vector.new :yoga, [1,2,3,4,5], [:warwick, :thompson, :jackson, :fender, :esp]
    end

    it "concatenates a new element at the end of vector with index" do
      @dv.concat 6, :ibanez

      expect(@dv.index)   .to eq(
        [:warwick, :thompson, :jackson, :fender, :esp, :ibanez].to_index)
      expect(@dv[:ibanez]).to eq(6)
      expect(@dv[5])      .to eq(6)
    end

    it "concatenates without index if index is default numeric" do
      vector = Daru::Vector.new :nums, [1,2,3,4,5]

      vector.concat 6

      expect(vector.index).to eq([0,1,2,3,4,5].to_index)
      expect(vector[5])   .to eq(6)
    end

    it "raises error if index not specified and non-numeric index" do
      expect {
        @dv.concat 6
      }.to raise_error
    end
  end

  context "#delete" do
    it "deletes element of specified index" do
      
    end
  end
end if mri?