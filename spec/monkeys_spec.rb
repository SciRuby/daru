require 'spec_helper.rb'

describe "Monkeys" do
  context Array do
  end

  context Matrix do
    it "performs elementwise division" do
      left  = Matrix[[3,6,9],[4,8,12],[2,4,6]]
      right = Matrix[[3,6,9],[4,8,12],[2,4,6]]

      expect(left.elementwise_division(right)).to eq(Matrix[[1,1,1],[1,1,1],[1,1,1]])
    end
  end
end