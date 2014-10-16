require 'spec_helper.rb'

describe Daru::Vector do
  context "#initialize" do
    it "initializes from an Array" do
      dv = Daru::Vector.new :ravan, [1,2,3,4,5], [:ek, :don, :teen, :char, :pach]

      expect(dv.name) .to eq(:ravan)
      expect(dv.index).to eq(Daru::Index.new [:ek, :don, :teen, :char, :pach])
    end
  end
end if RUBY_ENGINE == 'ruby'