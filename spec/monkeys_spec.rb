describe "Monkeys" do
  context Matrix do
    it "performs elementwise division" do
      left  = Matrix[[3,6,9],[4,8,12],[2,4,6]]
      right = Matrix[[3,6,9],[4,8,12],[2,4,6]]

      expect(left.elementwise_division(right)).to eq(Matrix[[1,1,1],[1,1,1],[1,1,1]])
    end
  end

  describe '#daru_vector' do
    it 'converts Array' do
      expect([1,2,3].daru_vector).to eq Daru::Vector.new [1,2,3]
      expect([1,2,3].daru_vector('test', [:a, :b, :c])).to eq \
        Daru::Vector.new [1,2,3], name: 'test', index: [:a, :b, :c]
    end

    it 'converts Range' do
      expect((1..3).daru_vector).to eq Daru::Vector.new [1,2,3]
      expect((1..3).daru_vector('test', [:a, :b, :c])).to eq \
        Daru::Vector.new [1,2,3], name: 'test', index: [:a, :b, :c]
    end

    it 'converts Hash' do
      # FIXME: is it most useful way of converting hashes?..
      # I'd prefer something like
      #   expect({a: 1, b: 2, c: 3}.daru_vector('test')).to eq Daru::Vector.new [1,2,3], name: 'test', index: [:a, :b, :c]
      #
      expect({test: [1, 2, 3]}.daru_vector).to eq Daru::Vector.new [1,2,3], name: :test
    end
  end

  describe '#to_index' do
    it 'converts Array' do
      expect([1,2,3].to_index).to eq Daru::Index.new [1,2,3]
    end

    it 'converts Range' do
      expect((1..3).to_index).to eq Daru::Index.new [1,2,3]
    end
  end
end
