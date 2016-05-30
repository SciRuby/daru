require_relative '_base'

n = 40_000
keys = (1..(n)).to_a

df = Daru::DataFrame.new(idx: 1.upto(n).to_a, keys: 1.upto(n).map { |v| keys[Random.rand(n)]})

__profile__ do
  df.to_a
end
