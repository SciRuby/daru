require 'spec_helper'

describe Daru::DataFrame do
  context "#join" do
    before do
      @left = Daru::DataFrame.new({
        :id   => [1,2,3,4],
        :name => ['Pirate', 'Monkey', 'Ninja', 'Spaghetti']
      })
      @right = Daru::DataFrame.new({
        :id => [1,2,3,4],
        :name => ['Rutabaga', 'Pirate', 'Darth Vader', 'Ninja']
      })
    end

    it "performs an inner join of two dataframes" do
      answer = Daru::DataFrame.new({
        :id_1   => [1,3],
        :name => ['Pirate', 'Ninja'],
        :id_2   => [2,4]
      }, order: [:id_1, :name, :id_2])
      expect(@left.join(@right, how: :inner, on: [:name])).to eq(answer)
    end

    it "performs a full outer join" do
      answer = Daru::DataFrame.new({
        :id_1 => [1,2,3,4,nil,nil],
        :name => ['Pirate', 'Monkey', 'Ninja', 'Spaghetti','Rutabaga', 'Darth Vader'],
        :id_2 => [2,nil,4,nil,1,3]
      }, order: [:id_1, :name, :id_2])
      expect(@left.join(@right, how: :outer, on: [:name])).to eq(answer)
    end

    it "performs a left outer join", focus: true do
      answer = Daru::DataFrame.new({
        :id_1 => [1,2,3,4],
        :name => ['Pirate', 'Monkey', 'Ninja', 'Spaghetti'],
        :id_2 => [2,nil,4,nil]
      }, order: [:id_1, :name, :id_2])
      expect(@left.join(@right, how: :left, on: [:name])).to eq(answer)
    end

    it "performs a right outer join" do
      answer = Daru::DataFrame.new({
        :id_1 => [nil,1,nil,3],
        :name => ['Rutabaga','Pirate', 'Darth Vader', 'Ninja'],
        :id_2 => [1,2,3,4]
      }, order: [:id_1, :name, :id_2])
      expect(@left.join(@right, how: :right, on: [:name])).to eq(answer)
    end
  end
end