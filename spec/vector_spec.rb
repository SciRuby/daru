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
end if RUBY_ENGINE == 'ruby'