require_relative '_base'

n = 40_0000
idx = (1..n).to_a.map(&:to_s)


__profile__ do
  Daru::Vector.new(1..n, index: idx)
end
