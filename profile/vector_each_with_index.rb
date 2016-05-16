require_relative '_base'

vector = Daru::Vector.new(['a','b','c','d','e','f']*1000, index: (1..6000).to_a.shuffle)

__profile__ do
  100.times do
    vector.each_with_index{|val, i| }
  end
end
