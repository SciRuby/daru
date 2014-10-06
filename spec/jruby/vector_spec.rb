require 'spec_helper.rb'
# Tests if interpreter is JRuby

describe Daru::Vector do
  context ".initialize" do
    it "creates a vector object with an MDArray" do
      vector = Daru::Vector.new(MDArray.new([5], [1,2,3,4,5]), :uhura)

      expect(vector[1])  .to eq(2)
      expect(vector.name).to eq(:uhura)
    end

    it "creates a vector object with a Hash with different values" do
      vector = Daru::Vector.new({ sulu: MDArray.new([5], [1,2,3,4,5])})

      expect(vector[1])  .to eq(2)
      expect(vector.name).to eq(:sulu) 
    end
  end
end if RUBY_ENGINE == 'jruby'