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
      @right_many = Daru::DataFrame.new({
        :id => [1,1,1,1],
        :name => ['Rutabaga', 'Pirate', 'Darth Vader', 'Ninja']
      })
      @empty = Daru::DataFrame.new({
        :id => [],
        :name => []
      })
    end

    it "performs an inner join of two dataframes" do
      answer = Daru::DataFrame.new({
        :id_1   => [3,1],
        :name => ['Ninja', 'Pirate'],
        :id_2   => [4,2]
      }, order: [:id_1, :name, :id_2])
      expect(@left.join(@right, how: :inner, on: [:name])).to eq(answer)
    end

    it "performs an inner join of two dataframes that has one to many mapping" do
      answer = Daru::DataFrame.new({
        :name_1 => ['Pirate', 'Pirate', 'Pirate', 'Pirate'],
        :id => [1,1,1,1],
        :name_2 => ['Rutabaga', 'Pirate', 'Darth Vader', 'Ninja']
      }, order: [:name_1, :id, :name_2])
      expect(@left.join(@right_many, how: :inner, on: [:id])).to eq(answer)
    end

    it "performs a full outer join" do
      answer = Daru::DataFrame.new({
        :id_1 => [nil,2,3,1,nil,4],
        :name => ["Darth Vader", "Monkey", "Ninja", "Pirate", "Rutabaga", "Spaghetti"],
        :id_2 => [3,nil,4,2,1,nil]
      }, order: [:id_1, :name, :id_2])
      expect(@left.join(@right, how: :outer, on: [:name])).to eq(answer)
    end

    it "performs a left outer join", focus: true do
      answer = Daru::DataFrame.new({
        :id_1 => [2,3,1,4],
        :name => ["Monkey", "Ninja", "Pirate", "Spaghetti"],
        :id_2 => [nil,4,2,nil]
      }, order: [:id_1, :name, :id_2])
      expect(@left.join(@right, how: :left, on: [:name])).to eq(answer)
    end

    it "performs a left join with an empty dataframe" do

      answer = Daru::DataFrame.new({
        :id_1 => [2,3,1,4],
        :name => ["Monkey", "Ninja", "Pirate", "Spaghetti"],
        :id_2 => [nil,nil,nil,nil]
      }, order: [:id_1, :name, :id_2])

      expect(@left.join(@empty, how: :left, on: [:name])).to eq(answer)
    end

    it "performs a right outer join" do
      answer = Daru::DataFrame.new({
        :id_1 => [nil,3,1,nil],
        :name => ["Darth Vader", "Ninja", "Pirate", "Rutabaga"],
        :id_2 => [3,4,2,1]
      }, order: [:id_1, :name, :id_2])
      expect(@left.join(@right, how: :right, on: [:name])).to eq(answer)
    end

  end
end
