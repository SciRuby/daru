require_relative '_base'

vector = Daru::Vector.new(10_000.times.map.to_a.shuffle)
df = Daru::DataFrame.new({
  a: vector,
  b: vector,
  c: vector
})

__profile__ do
  df.sort([:a])
end
