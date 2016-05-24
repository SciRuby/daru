describe "Monkeys" do
  context Array do
    it "#recode_repeated" do
      expect([1,'a',1,'a','b',:c,2].recode_repeated).to eq(
        ['1_1','a_1', '1_2','a_2','b',:c,2])
    end
  end

  context Matrix do
    it "performs elementwise division" do
      left  = Matrix[[3,6,9],[4,8,12],[2,4,6]]
      right = Matrix[[3,6,9],[4,8,12],[2,4,6]]

      expect(left.elementwise_division(right)).to eq(Matrix[[1,1,1],[1,1,1],[1,1,1]])
    end
  end
end
