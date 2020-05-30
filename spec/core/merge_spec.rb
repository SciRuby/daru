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

    it "performs an inner join of two dataframes that has many to one mapping" do
      left_many = @right_many
      right = @left

      answer = Daru::DataFrame.new({
        :name_2 => ['Pirate', 'Pirate', 'Pirate', 'Pirate'],
        :id => [1,1,1,1],
        :name_1 => ['Rutabaga', 'Pirate', 'Darth Vader', 'Ninja']
      }, order: [:name_1, :id, :name_2])
      expect(left_many.join(right, how: :inner, on: [:id])).to eq(answer)
    end

    it "performs an inner join of two dataframes that has many to many mapping" do
      @left[:id].recode! { |v| v == 2 ? 1 : v }
      answer = Daru::DataFrame.new({
        :name_1 => ['Pirate', 'Pirate', 'Pirate', 'Pirate', 'Monkey', 'Monkey', 'Monkey', 'Monkey'],
        :id => [1,1,1,1,1,1,1,1],
        :name_2 => ['Rutabaga', 'Pirate', 'Darth Vader', 'Ninja', 'Rutabaga', 'Pirate', 'Darth Vader', 'Ninja']
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

    it "adds a left/right indicator" do
      answer = Daru::DataFrame.new({
        :id_1 => [nil,2,3,1,nil,4],
        :name => ["Darth Vader", "Monkey", "Ninja", "Pirate", "Rutabaga", "Spaghetti"],
        :id_2 => [3,nil,4,2,1,nil]
      }, order: [:id_1, :name, :id_2])

      outer = @left.join(@right, how: :outer, on: [:name], indicator: :my_indicator)
      expect(outer[:my_indicator].to_a).to eq [:right_only, :left_only, :both, :both, :right_only, :left_only]
    end


    it "performs a full outer join when the right join keys have nils" do
      @right[:name].recode! { |v| v == 'Rutabaga' ? nil : v }
      answer = Daru::DataFrame.new({
        :id_1 => [nil, nil,2,3,1,4],
        :name => [nil, "Darth Vader", "Monkey", "Ninja", "Pirate", "Spaghetti"],
        :id_2 => [1,3,nil,4,2,nil]
      }, order: [:id_1, :name, :id_2])
      expect(@left.join(@right, how: :outer, on: [:name])).to eq(answer)
    end

    it "performs a full outer join when the left join keys have nils" do
      @left[:name].recode! { |v| v == 'Monkey' ? nil : v }
      answer = Daru::DataFrame.new({
        :id_1 => [2,nil,3,1,nil,4],
        :name => [nil, "Darth Vader", "Ninja", "Pirate", "Rutabaga", "Spaghetti"],
        :id_2 => [nil,3,4,2,1,nil]
      }, order: [:id_1, :name, :id_2])
      expect(@left.join(@right, how: :outer, on: [:name])).to eq(answer)
    end

    it "performs a full outer join when both left and right join keys have nils" do
      @left[:name].recode! { |v| v == 'Monkey' ? nil : v }
      @right[:name].recode! { |v| v == 'Rutabaga' ? nil : v }

      answer = Daru::DataFrame.new({
        :id_1 => [nil,2,nil,3,1,4],
        :name => [nil, nil, "Darth Vader", "Ninja", "Pirate", "Spaghetti"],
        :id_2 => [1,nil,3,4,2,nil]
      }, order: [:id_1, :name, :id_2])
      expect(@left.join(@right, how: :outer, on: [:name])).to eq(answer)
    end

    it "performs a left outer join" do
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

    it "doesn't convert false into nil when joining boolean values" do
      left = Daru::DataFrame.new({ key: [1,2,3], left_value: [true, false, true] })
      right = Daru::DataFrame.new({ key: [1,2,3], right_value: [true, false, true] })

      answer = Daru::DataFrame.new({
        left_value: [true, false, true],
        key: [1,2,3],
        right_value: [true, false, true]
      }, order: [:left_value, :key, :right_value] )

      expect(left.join(right, on: [:key], how: :inner)).to eq answer
    end

    it "raises if :on field are absent in one of dataframes" do
      @right.vectors = Daru::Index.new [:id, :other_name]
      expect { @left.join(@right, how: :right, on: [:name]) }.to \
        raise_error(ArgumentError, /Both dataframes expected .* :name/)

      expect { @left.join(@right, how: :right, on: [:other_name]) }.to \
        raise_error(ArgumentError, /Both dataframes expected .* :other_name/)
    end

    it "is able to join by several :on fields" do
      @left.gender = ['m', 'f', 'm', nil]
      @right.gender = ['m', 'm', nil, 'f']

      answer = Daru::DataFrame.new({
        id_1: [1],
        name: ['Pirate'],
        gender: ['m'],
        id_2: [2]
      }, order: [:id_1, :name, :gender, :id_2])
      expect(@left.join(@right, how: :inner, on: [:name, :gender])).to eq(answer)
    end
  end
end
